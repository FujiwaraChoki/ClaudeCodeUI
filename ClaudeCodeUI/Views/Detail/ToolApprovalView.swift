import SwiftUI

struct ToolApprovalView: View {
    let pendingTools: [ToolCall]
    let onApprove: (ToolCall) -> Void
    let onDeny: (ToolCall) -> Void

    var body: some View {
        if pendingTools.isEmpty {
            ContentUnavailableView(
                "No Pending Approvals",
                systemImage: "checkmark.circle",
                description: Text("Tool calls requiring approval will appear here")
            )
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pendingTools) { tool in
                        ToolApprovalRow(
                            tool: tool,
                            onApprove: { onApprove(tool) },
                            onDeny: { onDeny(tool) }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct ToolApprovalRow: View {
    let tool: ToolCall
    let onApprove: () -> Void
    let onDeny: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: tool.iconName)
                    .font(.title2)
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.name)
                        .font(.headline)

                    Text(toolDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                ToolStatusBadge(status: tool.status)
            }

            GroupBox {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    Text(tool.formattedInput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 150)
            }

            HStack {
                Button("Deny", role: .destructive) {
                    onDeny()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("Approve") {
                    onApprove()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var toolDescription: String {
        switch tool.name.lowercased() {
        case "bash":
            if case .string(let cmd) = tool.input["command"] {
                return cmd
            }
            return "Execute shell command"
        case "read":
            if case .string(let path) = tool.input["file_path"] {
                return URL(fileURLWithPath: path).lastPathComponent
            }
            return "Read file contents"
        case "edit":
            if case .string(let path) = tool.input["file_path"] {
                return URL(fileURLWithPath: path).lastPathComponent
            }
            return "Edit file"
        case "write":
            if case .string(let path) = tool.input["file_path"] {
                return URL(fileURLWithPath: path).lastPathComponent
            }
            return "Write file"
        case "glob":
            if case .string(let pattern) = tool.input["pattern"] {
                return pattern
            }
            return "Find files"
        case "grep":
            if case .string(let pattern) = tool.input["pattern"] {
                return pattern
            }
            return "Search contents"
        default:
            return "Tool operation"
        }
    }
}

#Preview {
    ToolApprovalView(
        pendingTools: [
            ToolCall(
                name: "Bash",
                input: ["command": .string("ls -la"), "description": .string("List files")],
                status: .pending
            ),
            ToolCall(
                name: "Edit",
                input: [
                    "file_path": .string("/Users/test/project/main.swift"),
                    "old_string": .string("Hello"),
                    "new_string": .string("World")
                ],
                status: .pending
            ),
            ToolCall(
                name: "Read",
                input: ["file_path": .string("/Users/test/project/readme.md")],
                status: .pending
            )
        ],
        onApprove: { _ in },
        onDeny: { _ in }
    )
    .frame(width: 350, height: 600)
}
