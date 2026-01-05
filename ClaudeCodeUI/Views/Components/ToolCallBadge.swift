import SwiftUI

struct ToolCallBadge: View {
    let toolCall: ToolCall

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    Image(systemName: toolCall.iconName)
                        .foregroundStyle(.orange)

                    Text(toolCall.name)
                        .font(.subheadline.weight(.medium))

                    Spacer()

                    ToolStatusBadge(status: toolCall.status)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                GroupBox("Input") {
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        Text(toolCall.formattedInput)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                }

                if let output = toolCall.output {
                    GroupBox("Output") {
                        ScrollView {
                            Text(output)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                    }
                }
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack(spacing: 16) {
        ToolCallBadge(toolCall: ToolCall(
            name: "Read",
            input: ["file_path": .string("/Users/test/project/main.swift")],
            status: .pending
        ))

        ToolCallBadge(toolCall: ToolCall(
            name: "Bash",
            input: ["command": .string("ls -la"), "description": .string("List files")],
            status: .completed,
            output: "total 16\ndrwxr-xr-x  5 user  staff   160 Jan  5 10:00 .\ndrwxr-xr-x  3 user  staff    96 Jan  5 10:00 .."
        ))

        ToolCallBadge(toolCall: ToolCall(
            name: "Edit",
            input: [
                "file_path": .string("/test.swift"),
                "old_string": .string("Hello"),
                "new_string": .string("World")
            ],
            status: .executing
        ))
    }
    .padding()
    .frame(width: 400)
}
