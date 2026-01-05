import SwiftUI

struct InputView: View {
    @Binding var text: String
    let isEnabled: Bool
    let isStreaming: Bool
    let onSend: () -> Void
    let onStop: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Message Claude...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $text)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
                    .frame(minHeight: 40, maxHeight: 200)
                    .disabled(!isEnabled)
                    .onSubmit {
                        if !text.isEmpty && isEnabled {
                            onSend()
                        }
                    }
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )

            VStack(spacing: 8) {
                if isStreaming {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generation")
                } else {
                    Button(action: onSend) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundStyle(text.isEmpty ? Color.secondary : Color.blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.isEmpty || !isEnabled)
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("Send message (⌘↩)")
                }
            }
        }
        .padding()
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    VStack {
        InputView(
            text: .constant(""),
            isEnabled: true,
            isStreaming: false,
            onSend: {},
            onStop: {}
        )

        InputView(
            text: .constant("Hello, Claude!"),
            isEnabled: true,
            isStreaming: false,
            onSend: {},
            onStop: {}
        )

        InputView(
            text: .constant(""),
            isEnabled: false,
            isStreaming: true,
            onSend: {},
            onStop: {}
        )
    }
    .padding()
}
