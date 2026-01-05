import Foundation
import SwiftData

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var timestamp: Date
    var contentData: Data

    var session: Session?

    var contents: [MessageContent] {
        get {
            (try? JSONDecoder().decode([MessageContent].self, from: contentData)) ?? []
        }
        set {
            contentData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }

    init(role: MessageRole, contents: [MessageContent]) {
        self.id = UUID()
        self.role = role
        self.timestamp = Date()
        self.contentData = (try? JSONEncoder().encode(contents)) ?? Data()
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

enum MessageContent: Codable, Hashable {
    case text(String)
    case code(language: String, content: String)
    case toolUse(ToolCall)
    case toolResult(toolId: String, output: String, isError: Bool)
    case thinking(String)

    private enum CodingKeys: String, CodingKey {
        case type, text, language, content, toolCall, toolId, output, isError, thought
    }

    private enum ContentType: String, Codable {
        case text, code, toolUse, toolResult, thinking
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContentType.self, forKey: .type)

        switch type {
        case .text:
            let text = try container.decode(String.self, forKey: .text)
            self = .text(text)
        case .code:
            let language = try container.decode(String.self, forKey: .language)
            let content = try container.decode(String.self, forKey: .content)
            self = .code(language: language, content: content)
        case .toolUse:
            let toolCall = try container.decode(ToolCall.self, forKey: .toolCall)
            self = .toolUse(toolCall)
        case .toolResult:
            let toolId = try container.decode(String.self, forKey: .toolId)
            let output = try container.decode(String.self, forKey: .output)
            let isError = try container.decode(Bool.self, forKey: .isError)
            self = .toolResult(toolId: toolId, output: output, isError: isError)
        case .thinking:
            let thought = try container.decode(String.self, forKey: .thought)
            self = .thinking(thought)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode(ContentType.text, forKey: .type)
            try container.encode(text, forKey: .text)
        case .code(let language, let content):
            try container.encode(ContentType.code, forKey: .type)
            try container.encode(language, forKey: .language)
            try container.encode(content, forKey: .content)
        case .toolUse(let toolCall):
            try container.encode(ContentType.toolUse, forKey: .type)
            try container.encode(toolCall, forKey: .toolCall)
        case .toolResult(let toolId, let output, let isError):
            try container.encode(ContentType.toolResult, forKey: .type)
            try container.encode(toolId, forKey: .toolId)
            try container.encode(output, forKey: .output)
            try container.encode(isError, forKey: .isError)
        case .thinking(let thought):
            try container.encode(ContentType.thinking, forKey: .type)
            try container.encode(thought, forKey: .thought)
        }
    }
}
