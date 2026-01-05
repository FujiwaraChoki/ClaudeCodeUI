import Foundation

@Observable
@MainActor
final class CLIService {
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var readTask: Task<Void, Never>?

    private(set) var isRunning = false
    private(set) var currentSessionId: String?

    var onEvent: ((StreamEvent) -> Void)?
    var onError: ((String) -> Void)?
    var onComplete: (() -> Void)?

    private static func findClaudePath() -> String? {
        let possiblePaths = [
            "\(NSHomeDirectory())/.local/bin/claude",
            "/usr/local/bin/claude",
            "/opt/homebrew/bin/claude",
            "\(NSHomeDirectory())/.claude/local/claude"
        ]
        for path in possiblePaths {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
                return path
            }
            // Check if it's a symlink
            if let _ = try? FileManager.default.destinationOfSymbolicLink(atPath: path) {
                return path
            }
        }
        return nil
    }

    func startSession(
        prompt: String? = nil,
        workingDirectory: String,
        sessionId: String? = nil,
        continueSession: Bool = false
    ) async throws {
        await stopSession()

        let process = Process()

        // Build the claude command with arguments
        var claudeArgs = ["--output-format", "stream-json"]

        if let sessionId = sessionId {
            claudeArgs.append(contentsOf: ["--resume", sessionId])
        } else if continueSession {
            claudeArgs.append("--continue")
        }

        if let prompt = prompt {
            claudeArgs.append("-p")
            claudeArgs.append(prompt.replacingOccurrences(of: "'", with: "'\\''"))
        }

        // Use shell to run claude (respects PATH)
        if let claudePath = Self.findClaudePath() {
            process.executableURL = URL(fileURLWithPath: claudePath)
            process.arguments = claudeArgs
        } else {
            // Fallback: use shell to find claude in PATH
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            let claudeCommand = "claude " + claudeArgs.map { arg in
                if arg.contains(" ") || arg.contains("'") {
                    return "'\(arg.replacingOccurrences(of: "'", with: "'\\''"))'"
                }
                return arg
            }.joined(separator: " ")
            process.arguments = ["-l", "-c", claudeCommand]
        }

        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let stdinPipe = Pipe()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.standardInput = stdinPipe
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        self.process = process
        self.stdinPipe = stdinPipe
        self.stdoutPipe = stdoutPipe
        self.stderrPipe = stderrPipe

        process.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isRunning = false
                self?.onComplete?()
            }
        }

        try process.run()
        isRunning = true

        readTask = Task { [weak self] in
            await self?.readOutputStream()
        }
    }

    func sendMessage(_ message: String) throws {
        guard let stdinPipe = stdinPipe, isRunning else {
            throw CLIError.notRunning
        }

        let jsonMessage: [String: Any] = [
            "type": "user_message",
            "content": message
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: jsonMessage),
              var jsonString = String(data: data, encoding: .utf8) else {
            throw CLIError.encodingError
        }

        jsonString += "\n"

        guard let messageData = jsonString.data(using: .utf8) else {
            throw CLIError.encodingError
        }

        stdinPipe.fileHandleForWriting.write(messageData)
    }

    func respondToToolCall(toolId: String, approved: Bool) throws {
        guard let stdinPipe = stdinPipe, isRunning else {
            throw CLIError.notRunning
        }

        let response: [String: Any] = [
            "type": "tool_result",
            "tool_use_id": toolId,
            "approved": approved
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: response),
              var jsonString = String(data: data, encoding: .utf8) else {
            throw CLIError.encodingError
        }

        jsonString += "\n"

        guard let responseData = jsonString.data(using: .utf8) else {
            throw CLIError.encodingError
        }

        stdinPipe.fileHandleForWriting.write(responseData)
    }

    func stopSession() async {
        readTask?.cancel()
        readTask = nil

        if let process = process, process.isRunning {
            process.terminate()
        }

        process = nil
        stdinPipe = nil
        stdoutPipe = nil
        stderrPipe = nil
        isRunning = false
        currentSessionId = nil
    }

    private func readOutputStream() async {
        guard let stdoutPipe = stdoutPipe else { return }

        let handle = stdoutPipe.fileHandleForReading
        var buffer = Data()

        while !Task.isCancelled {
            let availableData = handle.availableData

            if availableData.isEmpty {
                try? await Task.sleep(for: .milliseconds(50))
                continue
            }

            buffer.append(availableData)

            while let newlineIndex = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = buffer[..<newlineIndex]
                buffer = Data(buffer[buffer.index(after: newlineIndex)...])

                if let lineString = String(data: lineData, encoding: .utf8), !lineString.isEmpty {
                    await MainActor.run {
                        if let event = StreamEvent.parse(from: lineString) {
                            if case .systemInit(let initEvent) = event {
                                currentSessionId = initEvent.sessionId
                            }
                            onEvent?(event)
                        }
                    }
                }
            }
        }
    }
}

enum CLIError: LocalizedError {
    case notRunning
    case encodingError
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notRunning: return "Claude CLI is not running"
        case .encodingError: return "Failed to encode message"
        case .invalidResponse: return "Invalid response from CLI"
        }
    }
}
