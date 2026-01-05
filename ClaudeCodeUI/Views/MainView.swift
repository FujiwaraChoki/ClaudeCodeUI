import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appState: AppState?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        Group {
            if let appState = appState {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    SessionListView(appState: appState)
                        .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
                } content: {
                    if let session = appState.selectedSession {
                        ChatView(session: session, appState: appState)
                    } else {
                        WelcomeView(appState: appState)
                    }
                } detail: {
                    DetailPanelView(appState: appState)
                        .navigationSplitViewColumnWidth(min: 250, ideal: 350, max: 500)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showNewSessionSheet(appState: appState) }) {
                            Label("New Session", systemImage: "plus.bubble")
                        }
                    }

                    ToolbarItem(placement: .automatic) {
                        if appState.cliService.isRunning {
                            Button(action: { Task { await appState.cliService.stopSession() } }) {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .tint(.red)
                        }
                    }
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            if appState == nil {
                appState = AppState(modelContext: modelContext)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newSession)) { _ in
            if let appState = appState {
                showNewSessionSheet(appState: appState)
            }
        }
    }

    @State private var showingNewSession = false
    @State private var newSessionTitle = ""
    @State private var newSessionDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    private func showNewSessionSheet(appState: AppState) {
        newSessionTitle = "New Session"
        newSessionDirectory = FileManager.default.currentDirectoryPath

        let alert = NSAlert()
        alert.messageText = "New Session"
        alert.informativeText = "Enter a name and select a working directory for your new session."
        alert.alertStyle = .informational

        let titleField = NSTextField(frame: NSRect(x: 0, y: 40, width: 300, height: 24))
        titleField.stringValue = newSessionTitle
        titleField.placeholderString = "Session name"

        let directoryLabel = NSTextField(labelWithString: "Directory:")
        directoryLabel.frame = NSRect(x: 0, y: 10, width: 60, height: 20)

        let directoryField = NSTextField(frame: NSRect(x: 65, y: 8, width: 235, height: 24))
        directoryField.stringValue = newSessionDirectory
        directoryField.isEditable = false

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 70))
        containerView.addSubview(titleField)
        containerView.addSubview(directoryLabel)
        containerView.addSubview(directoryField)

        alert.accessoryView = containerView
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Browse...")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()

        if response == .alertFirstButtonReturn {
            let title = titleField.stringValue.isEmpty ? "New Session" : titleField.stringValue
            let session = appState.sessionManager.createSession(
                title: title,
                workingDirectory: directoryField.stringValue
            )
            appState.selectSession(session)
        } else if response == .alertSecondButtonReturn {
            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.directoryURL = URL(fileURLWithPath: directoryField.stringValue)

            if panel.runModal() == .OK, let url = panel.url {
                directoryField.stringValue = url.path
                let response2 = alert.runModal()
                if response2 == .alertFirstButtonReturn {
                    let title = titleField.stringValue.isEmpty ? "New Session" : titleField.stringValue
                    let session = appState.sessionManager.createSession(
                        title: title,
                        workingDirectory: directoryField.stringValue
                    )
                    appState.selectSession(session)
                }
            }
        }
    }
}

struct WelcomeView: View {
    let appState: AppState

    var body: some View {
        ContentUnavailableView {
            Label("Claude Code", systemImage: "sparkles")
        } description: {
            Text("Select a session from the sidebar or create a new one to get started.")
        } actions: {
            Button("New Session") {
                NotificationCenter.default.post(name: .newSession, object: nil)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [Session.self, Message.self], inMemory: true)
}
