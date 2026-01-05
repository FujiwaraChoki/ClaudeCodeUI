import Foundation

enum StreamEvent {
    case systemInit(SystemInitEvent)
    case assistantMessage(AssistantMessageEvent)
    case userMessage(UserMessageEvent)
    case contentBlockStart(ContentBlockStartEvent)
    case contentBlockDelta(ContentBlockDeltaEvent)
    case contentBlockStop(ContentBlockStopEvent)
    case result(ResultEvent)
    case unknown(String)

    struct SystemInitEvent {
        let sessionId: String
        let tools: [String]
        let model: String?
    }

    struct AssistantMessageEvent {
        let id: String
        let stopReason: String?
    }

    struct UserMessageEvent {
        let id: String
    }

    struct ContentBlockStartEvent {
        let index: Int
        let blockType: ContentBlockType
    }

    struct ContentBlockDeltaEvent {
        let index: Int
        let delta: ContentDelta
    }

    struct ContentBlockStopEvent {
        let index: Int
    }

    struct ResultEvent {
        let subtype: String?
        let duration: Int?
        let numTurns: Int?
        let sessionId: String?
        let result: String?
    }

    enum ContentBlockType {
        case text
        case toolUse(id: String, name: String)
        case thinking
    }

    enum ContentDelta {
        case textDelta(String)
        case inputJsonDelta(String)
        case thinkingDelta(String)
    }
}

extension StreamEvent {
    static func parse(from jsonString: String) -> StreamEvent? {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let type = json["type"] as? String else {
            return .unknown(jsonString)
        }

        switch type {
        case "system":
            guard let subtype = json["subtype"] as? String, subtype == "init",
                  let sessionId = json["session_id"] as? String else {
                return .unknown(jsonString)
            }
            let tools = json["tools"] as? [String] ?? []
            let model = json["model"] as? String
            return .systemInit(SystemInitEvent(sessionId: sessionId, tools: tools, model: model))

        case "assistant":
            guard let subtype = json["subtype"] as? String else {
                return .unknown(jsonString)
            }

            switch subtype {
            case "message":
                guard let message = json["message"] as? [String: Any],
                      let id = message["id"] as? String else {
                    return .unknown(jsonString)
                }
                let stopReason = message["stop_reason"] as? String
                return .assistantMessage(AssistantMessageEvent(id: id, stopReason: stopReason))

            case "content_block_start":
                guard let index = json["index"] as? Int,
                      let contentBlock = json["content_block"] as? [String: Any],
                      let blockType = contentBlock["type"] as? String else {
                    return .unknown(jsonString)
                }

                let block: ContentBlockType
                switch blockType {
                case "text":
                    block = .text
                case "tool_use":
                    let id = contentBlock["id"] as? String ?? ""
                    let name = contentBlock["name"] as? String ?? ""
                    block = .toolUse(id: id, name: name)
                case "thinking":
                    block = .thinking
                default:
                    return .unknown(jsonString)
                }
                return .contentBlockStart(ContentBlockStartEvent(index: index, blockType: block))

            case "content_block_delta":
                guard let index = json["index"] as? Int,
                      let delta = json["delta"] as? [String: Any],
                      let deltaType = delta["type"] as? String else {
                    return .unknown(jsonString)
                }

                let contentDelta: ContentDelta
                switch deltaType {
                case "text_delta":
                    let text = delta["text"] as? String ?? ""
                    contentDelta = .textDelta(text)
                case "input_json_delta":
                    let jsonStr = delta["partial_json"] as? String ?? ""
                    contentDelta = .inputJsonDelta(jsonStr)
                case "thinking_delta":
                    let thinking = delta["thinking"] as? String ?? ""
                    contentDelta = .thinkingDelta(thinking)
                default:
                    return .unknown(jsonString)
                }
                return .contentBlockDelta(ContentBlockDeltaEvent(index: index, delta: contentDelta))

            case "content_block_stop":
                guard let index = json["index"] as? Int else {
                    return .unknown(jsonString)
                }
                return .contentBlockStop(ContentBlockStopEvent(index: index))

            default:
                return .unknown(jsonString)
            }

        case "user":
            guard let subtype = json["subtype"] as? String, subtype == "message",
                  let message = json["message"] as? [String: Any],
                  let id = message["id"] as? String else {
                return .unknown(jsonString)
            }
            return .userMessage(UserMessageEvent(id: id))

        case "result":
            let subtype = json["subtype"] as? String
            let duration = json["duration_ms"] as? Int
            let numTurns = json["num_turns"] as? Int
            let sessionId = json["session_id"] as? String
            let result = json["result"] as? String
            return .result(ResultEvent(subtype: subtype, duration: duration, numTurns: numTurns, sessionId: sessionId, result: result))

        default:
            return .unknown(jsonString)
        }
    }
}
