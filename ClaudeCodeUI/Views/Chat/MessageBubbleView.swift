import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let onFileSelected: (URL) -> Void

    private var isUser: Bool { message.role == .user }
    private var isSystem: Bool { message.role == .system }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !isUser {
                Image(systemName: isSystem ? "info.circle.fill" : "sparkles")
                    .font(.title2)
                    .foregroundStyle(isSystem ? .blue : .purple)
                    .frame(width: 28)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 8) {
                ForEach(Array(message.contents.enumerated()), id: \.offset) { _, content in
                    MessageContentView(content: content, onFileSelected: onFileSelected)
                }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if isUser {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 28)
            }
        }
        .padding(.horizontal)
    }
}

struct MessageContentView: View {
    let content: MessageContent
    let onFileSelected: (URL) -> Void

    var body: some View {
        switch content {
        case .text(let text):
            MarkdownTextView(text: text)
                .textSelection(.enabled)

        case .code(let language, let code):
            CodeBlockView(language: language, code: code)

        case .toolUse(let toolCall):
            ToolCallBadge(toolCall: toolCall)

        case .toolResult(let toolId, let output, let isError):
            ToolResultView(toolId: toolId, output: output, isError: isError)

        case .thinking(let thought):
            ThinkingView(thought: thought)
        }
    }
}

struct ToolResultView: View {
    let toolId: String
    let output: String
    let isError: Bool

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(isError ? .red : .green)

                    Text(isError ? "Error" : "Result")
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView {
                    Text(output)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 200)
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(10)
        .background(isError ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ThinkingView: View {
    let thought: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)

                    Text("Thinking...")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(thought)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(Color.purple.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: Message(role: .user, contents: [.text("Can you help me?")]),
            onFileSelected: { _ in }
        )

        MessageBubbleView(
            message: Message(role: .assistant, contents: [.text("Of course! I'd be happy to help.")]),
            onFileSelected: { _ in }
        )

        MessageBubbleView(
            message: Message(role: .assistant, contents: [
                .toolUse(ToolCall(name: "Read", input: ["file_path": .string("/test.swift")], status: .completed))
            ]),
            onFileSelected: { _ in }
        )
    }
    .padding()
}
