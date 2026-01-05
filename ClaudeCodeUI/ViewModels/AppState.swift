import Foundation
import SwiftData

@Observable
@MainActor
final class AppState {
    let cliService: CLIService
    let sessionManager: SessionManager
    let fileSystemService: FileSystemService

    var selectedSession: Session?
    var selectedFile: URL?
    var pendingToolCalls: [ToolCall] = []
    var isStreaming: Bool = false
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.cliService = CLIService()
        self.sessionManager = SessionManager(modelContext: modelContext)
        self.fileSystemService = FileSystemService()
    }

    func selectSession(_ session: Session?) {
        selectedSession = session
        pendingToolCalls = []
        errorMessage = nil
    }

    func addPendingToolCall(_ toolCall: ToolCall) {
        pendingToolCalls.append(toolCall)
    }

    func removePendingToolCall(id: String) {
        pendingToolCalls.removeAll { $0.id == id }
    }

    func clearError() {
        errorMessage = nil
    }
}
