import Foundation
import SwiftData

@Model
final class Session {
    @Attribute(.unique) var id: UUID
    var sessionId: String
    var title: String
    var workingDirectory: String
    var createdAt: Date
    var lastActiveAt: Date
    var status: SessionStatus

    @Relationship(deleteRule: .cascade, inverse: \Message.session)
    var messages: [Message] = []

    init(sessionId: String = UUID().uuidString, title: String, workingDirectory: String) {
        self.id = UUID()
        self.sessionId = sessionId
        self.title = title
        self.workingDirectory = workingDirectory
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.status = .idle
    }
}

enum SessionStatus: String, Codable {
    case active
    case idle
    case terminated
}
