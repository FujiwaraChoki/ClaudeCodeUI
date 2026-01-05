import Foundation

struct ToolCall: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let input: [String: JSONValue]
    var status: ToolCallStatus
    var output: String?

    init(id: String = UUID().uuidString, name: String, input: [String: JSONValue], status: ToolCallStatus = .pending, output: String? = nil) {
        self.id = id
        self.name = name
        self.input = input
        self.status = status
        self.output = output
    }

    var iconName: String {
        switch name.lowercased() {
        case "bash": return "terminal"
        case "edit", "write": return "doc.badge.plus"
        case "read": return "doc.text"
        case "glob": return "folder.badge.gearshape"
        case "grep": return "magnifyingglass"
        case "task": return "person.2"
        default: return "wrench.and.screwdriver"
        }
    }

    var formattedInput: String {
        guard let data = try? JSONEncoder().encode(input),
              let json = try? JSONSerialization.jsonObject(with: data),
              let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: formatted, encoding: .utf8) else {
            return String(describing: input)
        }
        return string
    }
}

enum ToolCallStatus: String, Codable {
    case pending
    case approved
    case denied
    case executing
    case completed
    case failed
}

enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let number = try? container.decode(Double.self) {
            self = .number(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.typeMismatch(JSONValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown JSON type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}
