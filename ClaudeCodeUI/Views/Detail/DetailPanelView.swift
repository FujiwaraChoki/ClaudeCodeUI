import SwiftUI
import SwiftData

struct DetailPanelView: View {
    let appState: AppState

    @State private var selectedTab: DetailTab = .tools

    enum DetailTab: String, CaseIterable {
        case tools = "Tools"
        case files = "Files"
        case preview = "Preview"
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Detail View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            switch selectedTab {
            case .tools:
                ToolApprovalView(
                    pendingTools: appState.pendingToolCalls,
                    onApprove: { tool in approveToolCall(tool) },
                    onDeny: { tool in denyToolCall(tool) }
                )

            case .files:
                if let session = appState.selectedSession {
                    FileBrowserView(
                        rootDirectory: URL(fileURLWithPath: session.workingDirectory),
                        selectedFile: Binding(
                            get: { appState.selectedFile },
                            set: { appState.selectedFile = $0 }
                        ),
                        fileSystemService: appState.fileSystemService
                    )
                } else {
                    ContentUnavailableView(
                        "No Session",
                        systemImage: "folder",
                        description: Text("Select a session to browse files")
                    )
                }

            case .preview:
                if let file = appState.selectedFile {
                    FilePreviewView(fileURL: file, fileSystemService: appState.fileSystemService)
                } else {
                    ContentUnavailableView(
                        "No File Selected",
                        systemImage: "doc",
                        description: Text("Select a file from the browser to preview")
                    )
                }
            }
        }
        .onChange(of: appState.selectedFile) { _, newFile in
            if newFile != nil {
                selectedTab = .preview
            }
        }
        .onChange(of: appState.pendingToolCalls) { _, newTools in
            if !newTools.isEmpty {
                selectedTab = .tools
            }
        }
    }

    private func approveToolCall(_ tool: ToolCall) {
        do {
            try appState.cliService.respondToToolCall(toolId: tool.id, approved: true)
            appState.removePendingToolCall(id: tool.id)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }

    private func denyToolCall(_ tool: ToolCall) {
        do {
            try appState.cliService.respondToToolCall(toolId: tool.id, approved: false)
            appState.removePendingToolCall(id: tool.id)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    @Previewable @State var previewAppState: AppState? = nil

    DetailPanelView(appState: AppState(modelContext: try! ModelContainer(for: Session.self, Message.self).mainContext))
        .frame(width: 350, height: 600)
}
