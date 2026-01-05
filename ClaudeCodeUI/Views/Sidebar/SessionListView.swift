import SwiftUI
import SwiftData

struct SessionListView: View {
    let appState: AppState

    @Query(sort: \Session.lastActiveAt, order: .reverse)
    private var sessions: [Session]

    @State private var discoveredSessions: [DiscoveredSession] = []
    @State private var isLoadingDiscovered = false
    @State private var searchText = ""

    private var filteredSessions: [Session] {
        if searchText.isEmpty {
            return sessions
        }
        return sessions.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredDiscovered: [DiscoveredSession] {
        if searchText.isEmpty {
            return discoveredSessions
        }
        return discoveredSessions.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.projectPath.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(selection: Binding(
            get: { appState.selectedSession },
            set: { appState.selectSession($0) }
        )) {
            Section("Sessions") {
                ForEach(filteredSessions) { session in
                    SessionRowView(session: session, isSelected: appState.selectedSession?.id == session.id)
                        .tag(session)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                if appState.selectedSession?.id == session.id {
                                    appState.selectSession(nil)
                                }
                                appState.sessionManager.deleteSession(session)
                            }
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let session = filteredSessions[index]
                        if appState.selectedSession?.id == session.id {
                            appState.selectSession(nil)
                        }
                        appState.sessionManager.deleteSession(session)
                    }
                }
            }

            if !filteredDiscovered.isEmpty {
                Section("Discovered") {
                    if isLoadingDiscovered {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(filteredDiscovered) { discovered in
                            DiscoveredSessionRowView(session: discovered) {
                                importDiscoveredSession(discovered)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search sessions")
        .navigationTitle("Sessions")
        .task {
            await loadDiscoveredSessions()
        }
        .refreshable {
            await loadDiscoveredSessions()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { Task { await loadDiscoveredSessions() } }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private func loadDiscoveredSessions() async {
        isLoadingDiscovered = true
        defer { isLoadingDiscovered = false }

        discoveredSessions = await appState.sessionManager.discoverSessions()

        let existingIds = Set(sessions.map { $0.sessionId })
        discoveredSessions = discoveredSessions.filter { !existingIds.contains($0.sessionId) }
    }

    private func importDiscoveredSession(_ discovered: DiscoveredSession) {
        let workingDirectory = discovered.projectPath.hasPrefix("/")
            ? discovered.projectPath
            : FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(discovered.projectPath).path

        let session = appState.sessionManager.createSession(
            title: discovered.displayName,
            workingDirectory: workingDirectory,
            sessionId: discovered.sessionId
        )
        appState.selectSession(session)
    }
}

struct SessionRowView: View {
    let session: Session
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                StatusBadge(status: session.status)
            }

            Text(session.workingDirectory)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(session.lastActiveAt, style: .relative)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct DiscoveredSessionRowView: View {
    let session: DiscoveredSession
    let onImport: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(session.projectPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button("Import") {
                onImport()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
