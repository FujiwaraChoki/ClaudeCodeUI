import SwiftUI

struct MessageListView: View {
    let messages: [Message]
    let isStreaming: Bool
    let streamingText: String
    let onFileSelected: (URL) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubbleView(message: message, onFileSelected: onFileSelected)
                            .id(message.id)
                    }

                    if isStreaming {
                        StreamingMessageView(text: streamingText)
                            .id("streaming")
                    }
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: streamingText) { _, _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            if isStreaming {
                proxy.scrollTo("streaming", anchor: .bottom)
            } else if let lastMessage = messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct StreamingMessageView: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 8) {
                if text.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(.secondary)
                                .frame(width: 6, height: 6)
                                .opacity(0.6)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text(text)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 40)
        }
        .padding(.horizontal)
    }
}

#Preview {
    MessageListView(
        messages: [
            Message(role: .user, contents: [.text("Hello, Claude!")]),
            Message(role: .assistant, contents: [.text("Hello! How can I help you today?")])
        ],
        isStreaming: true,
        streamingText: "I'm thinking about this...",
        onFileSelected: { _ in }
    )
}
