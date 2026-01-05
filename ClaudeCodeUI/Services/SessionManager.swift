import Foundation
import SwiftData

@Observable
@MainActor
final class SessionManager {
    private let modelContext: ModelContext

    private let sessionsDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/projects")
    }()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createSession(title: String, workingDirectory: String, sessionId: String? = nil) -> Session {
        let session = Session(
            sessionId: sessionId ?? UUID().uuidString,
            title: title,
            workingDirectory: workingDirectory
        )
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }

    func deleteSession(_ session: Session) {
        modelContext.delete(session)
        try? modelContext.save()
    }

    func updateSessionActivity(_ session: Session) {
        session.lastActiveAt = Date()
        try? modelContext.save()
    }

    func setSessionStatus(_ session: Session, status: SessionStatus) {
        session.status = status
        try? modelContext.save()
    }

    func addMessage(to session: Session, role: MessageRole, contents: [MessageContent]) {
        let message = Message(role: role, contents: contents)
        message.session = session
        session.messages.append(message)
        session.lastActiveAt = Date()
        try? modelContext.save()
    }

    func discoverSessions() async -> [DiscoveredSession] {
        var sessions: [DiscoveredSession] = []

        guard FileManager.default.fileExists(atPath: sessionsDirectory.path) else {
            return sessions
        }

        do {
            let projectDirs = try FileManager.default.contentsOfDirectory(
                at: sessionsDirectory,
                includingPropertiesForKeys: [.isDirectoryKey]
            )

            for projectDir in projectDirs {
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: projectDir.path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    continue
                }

                let files = try FileManager.default.contentsOfDirectory(
                    at: projectDir,
                    includingPropertiesForKeys: [.contentModificationDateKey]
                ).filter { $0.pathExtension == "jsonl" }

                for file in files {
                    let sessionId = file.deletingPathExtension().lastPathComponent
                    let attrs = try FileManager.default.attributesOfItem(atPath: file.path)
                    let modDate = attrs[.modificationDate] as? Date ?? Date.distantPast

                    let projectPath = projectDir.lastPathComponent.replacingOccurrences(of: "-", with: "/")

                    sessions.append(DiscoveredSession(
                        sessionId: sessionId,
                        projectPath: projectPath,
                        lastModified: modDate,
                        filePath: file.path
                    ))
                }
            }
        } catch {
            print("Failed to discover sessions: \(error)")
        }

        return sessions.sorted { $0.lastModified > $1.lastModified }
    }
}

struct DiscoveredSession: Identifiable, Hashable {
    var id: String { sessionId }
    let sessionId: String
    let projectPath: String
    let lastModified: Date
    let filePath: String

    var displayName: String {
        let components = projectPath.split(separator: "/")
        return components.last.map(String.init) ?? sessionId
    }
}
