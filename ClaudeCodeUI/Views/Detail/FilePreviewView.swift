import SwiftUI

struct FilePreviewView: View {
    let fileURL: URL
    let fileSystemService: FileSystemService

    @State private var content: String?
    @State private var isLoading = true
    @State private var error: String?
    @State private var isCopied = false

    private var language: String {
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js": return "javascript"
        case "ts": return "typescript"
        case "jsx": return "jsx"
        case "tsx": return "tsx"
        case "py": return "python"
        case "rb": return "ruby"
        case "go": return "go"
        case "rs": return "rust"
        case "java": return "java"
        case "kt": return "kotlin"
        case "c", "h": return "c"
        case "cpp", "hpp", "cc": return "cpp"
        case "cs": return "csharp"
        case "json": return "json"
        case "yaml", "yml": return "yaml"
        case "xml": return "xml"
        case "html", "htm": return "html"
        case "css": return "css"
        case "scss", "sass": return "scss"
        case "md", "markdown": return "markdown"
        case "sh", "bash", "zsh": return "bash"
        case "sql": return "sql"
        default: return "plaintext"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: iconForFile)
                    .foregroundStyle(iconColor)

                Text(fileURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button {
                    copyToClipboard()
                } label: {
                    Label(isCopied ? "Copied!" : "Copy", systemImage: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(isCopied ? .green : .secondary)
                .disabled(content == nil)

                Button(action: openInFinder) {
                    Image(systemName: "arrow.up.forward.square")
                }
                .buttonStyle(.plain)
                .help("Reveal in Finder")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            HStack {
                Text(fileURL.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)

                Spacer()

                Text(language)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                ContentUnavailableView(
                    "Cannot Preview",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let content = content {
                ScrollView([.horizontal, .vertical]) {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .task(id: fileURL) {
            await loadFile()
        }
    }

    private func loadFile() async {
        isLoading = true
        error = nil
        content = nil

        do {
            let fileContent = try await fileSystemService.readFile(fileURL)

            if fileContent.count > 500_000 {
                error = "File is too large to preview (\(fileContent.count) bytes)"
            } else {
                content = fileContent
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func copyToClipboard() {
        guard let content = content else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        isCopied = true

        Task {
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }

    private func openInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private var iconForFile: String {
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "jsx", "ts", "tsx": return "curlybraces"
        case "json": return "doc.text"
        case "md", "markdown": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "html", "htm": return "globe"
        case "css", "scss", "sass": return "paintbrush"
        case "py": return "chevron.left.forwardslash.chevron.right"
        default: return "doc"
        }
    }

    private var iconColor: Color {
        let ext = fileURL.pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "js", "jsx", "ts", "tsx": return .yellow
        case "py": return .blue
        case "rb": return .red
        case "go": return .cyan
        case "rs": return .orange
        default: return .secondary
        }
    }
}

#Preview {
    FilePreviewView(
        fileURL: URL(fileURLWithPath: "/Users/test/example.swift"),
        fileSystemService: FileSystemService()
    )
    .frame(width: 400, height: 500)
}
