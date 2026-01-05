import SwiftUI
import SwiftData

struct ChatView: View {
    let session: Session
    let appState: AppState

    @State private var viewModel: ChatViewModel

    init(session: Session, appState: AppState) {
        self.session = session
        self.appState = appState
        let vm = ChatViewModel(
            cliService: appState.cliService,
            sessionManager: appState.sessionManager,
            appState: appState
        )
        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        VStack(spacing: 0) {
            MessageListView(
                messages: viewModel.messages,
                isStreaming: viewModel.isStreaming,
                streamingText: viewModel.currentStreamingText,
                onFileSelected: { url in
                    appState.selectedFile = url
                }
            )

            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.errorMessage = nil
                }
            }

            Divider()

            InputView(
                text: $viewModel.inputText,
                isEnabled: !viewModel.isStreaming,
                isStreaming: viewModel.isStreaming,
                onSend: {
                    Task {
                        await viewModel.sendMessage(to: session)
                    }
                },
                onStop: {
                    Task {
                        await viewModel.stopSession()
                    }
                }
            )
        }
        .navigationTitle(session.title)
        .navigationSubtitle(session.workingDirectory)
        .onAppear {
            viewModel.loadMessages(from: session)
        }
        .onChange(of: session.id) { _, _ in
            viewModel.loadMessages(from: session)
        }
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            Text(message)
                .font(.callout)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var container = try! ModelContainer(for: Session.self, Message.self)

        var body: some View {
            let session = Session(title: "Test Session", workingDirectory: "/Users/test")
            ChatView(session: session, appState: AppState(modelContext: container.mainContext))
                .modelContainer(container)
        }
    }

    return PreviewWrapper()
}
