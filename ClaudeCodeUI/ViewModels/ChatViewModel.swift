import Foundation

@Observable
@MainActor
final class ChatViewModel {
    private let cliService: CLIService
    private let sessionManager: SessionManager
    private weak var appState: AppState?

    var messages: [Message] = []
    var inputText: String = ""
    var isStreaming: Bool = false
    var currentStreamingText: String = ""
    var errorMessage: String?

    private var currentTextBlockIndex: Int?
    private var currentToolBlocks: [Int: (id: String, name: String, inputJson: String)] = [:]
    private var currentThinkingText: String = ""

    init(cliService: CLIService, sessionManager: SessionManager, appState: AppState? = nil) {
        self.cliService = cliService
        self.sessionManager = sessionManager
        self.appState = appState
        setupEventHandlers()
    }

    private func setupEventHandlers() {
        cliService.onEvent = { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleStreamEvent(event)
            }
        }

        cliService.onError = { [weak self] error in
            Task { @MainActor [weak self] in
                self?.errorMessage = error
            }
        }

        cliService.onComplete = { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishStreaming()
            }
        }
    }

    func loadMessages(from session: Session) {
        messages = session.messages.sorted { $0.timestamp < $1.timestamp }
    }

    func startNewSession(workingDirectory: String, initialPrompt: String? = nil) async {
        guard !inputText.isEmpty || initialPrompt != nil else { return }

        let prompt = initialPrompt ?? inputText
        inputText = ""
        isStreaming = true
        currentStreamingText = ""
        errorMessage = nil

        let userMessage = Message(role: .user, contents: [.text(prompt)])
        messages.append(userMessage)

        do {
            try await cliService.startSession(
                prompt: prompt,
                workingDirectory: workingDirectory
            )
        } catch {
            errorMessage = error.localizedDescription
            isStreaming = false
        }
    }

    func sendMessage(to session: Session) async {
        guard !inputText.isEmpty else { return }

        let prompt = inputText
        inputText = ""
        isStreaming = true
        currentStreamingText = ""
        errorMessage = nil

        let userMessage = Message(role: .user, contents: [.text(prompt)])
        messages.append(userMessage)
        sessionManager.addMessage(to: session, role: .user, contents: [.text(prompt)])

        do {
            if cliService.isRunning {
                try cliService.sendMessage(prompt)
            } else {
                try await cliService.startSession(
                    prompt: prompt,
                    workingDirectory: session.workingDirectory,
                    sessionId: session.sessionId
                )
            }
        } catch {
            errorMessage = error.localizedDescription
            isStreaming = false
        }
    }

    func resumeSession(_ session: Session) async {
        isStreaming = true
        errorMessage = nil

        do {
            try await cliService.startSession(
                workingDirectory: session.workingDirectory,
                sessionId: session.sessionId
            )
        } catch {
            errorMessage = error.localizedDescription
            isStreaming = false
        }
    }

    func stopSession() async {
        await cliService.stopSession()
        isStreaming = false
    }

    private func handleStreamEvent(_ event: StreamEvent) {
        switch event {
        case .systemInit(let initEvent):
            if let appState = appState, let session = appState.selectedSession {
                session.sessionId = initEvent.sessionId
            }

        case .assistantMessage:
            break

        case .userMessage:
            break

        case .contentBlockStart(let startEvent):
            switch startEvent.blockType {
            case .text:
                currentTextBlockIndex = startEvent.index
                currentStreamingText = ""

            case .toolUse(let id, let name):
                currentToolBlocks[startEvent.index] = (id: id, name: name, inputJson: "")
                let toolCall = ToolCall(id: id, name: name, input: [:], status: .pending)
                appState?.addPendingToolCall(toolCall)

            case .thinking:
                currentThinkingText = ""
            }

        case .contentBlockDelta(let deltaEvent):
            switch deltaEvent.delta {
            case .textDelta(let text):
                currentStreamingText += text

            case .inputJsonDelta(let json):
                if var toolBlock = currentToolBlocks[deltaEvent.index] {
                    toolBlock.inputJson += json
                    currentToolBlocks[deltaEvent.index] = toolBlock
                }

            case .thinkingDelta(let thinking):
                currentThinkingText += thinking
            }

        case .contentBlockStop(let stopEvent):
            if stopEvent.index == currentTextBlockIndex {
                if !currentStreamingText.isEmpty {
                    let assistantMessage = Message(role: .assistant, contents: [.text(currentStreamingText)])
                    messages.append(assistantMessage)

                    if let appState = appState, let session = appState.selectedSession {
                        sessionManager.addMessage(to: session, role: .assistant, contents: [.text(currentStreamingText)])
                    }
                }
                currentStreamingText = ""
                currentTextBlockIndex = nil
            }

            if let toolBlock = currentToolBlocks[stopEvent.index] {
                var input: [String: JSONValue] = [:]
                if let data = toolBlock.inputJson.data(using: .utf8),
                   let parsed = try? JSONDecoder().decode([String: JSONValue].self, from: data) {
                    input = parsed
                }

                let toolCall = ToolCall(id: toolBlock.id, name: toolBlock.name, input: input, status: .pending)
                let toolMessage = Message(role: .assistant, contents: [.toolUse(toolCall)])
                messages.append(toolMessage)

                currentToolBlocks.removeValue(forKey: stopEvent.index)
            }

        case .result:
            finishStreaming()

        case .unknown:
            break
        }
    }

    private func finishStreaming() {
        if !currentStreamingText.isEmpty {
            let assistantMessage = Message(role: .assistant, contents: [.text(currentStreamingText)])
            messages.append(assistantMessage)
            currentStreamingText = ""
        }
        isStreaming = false
    }

    func approveToolCall(_ toolCall: ToolCall) {
        do {
            try cliService.respondToToolCall(toolId: toolCall.id, approved: true)
            appState?.removePendingToolCall(id: toolCall.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func denyToolCall(_ toolCall: ToolCall) {
        do {
            try cliService.respondToToolCall(toolId: toolCall.id, approved: false)
            appState?.removePendingToolCall(id: toolCall.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
