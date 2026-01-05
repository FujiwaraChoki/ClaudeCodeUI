import SwiftUI

struct CodeBlockView: View {
    let language: String
    let code: String

    @State private var isCopied = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.isEmpty ? "code" : language)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isCopied ? .green : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 400)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            isHovering = hovering
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        isCopied = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CodeBlockView(
            language: "swift",
            code: """
            struct ContentView: View {
                var body: some View {
                    Text("Hello, World!")
                }
            }
            """
        )

        CodeBlockView(
            language: "bash",
            code: "npm install && npm run build"
        )
    }
    .padding()
    .frame(width: 500)
}
