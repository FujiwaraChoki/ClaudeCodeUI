import SwiftUI

struct FileBrowserView: View {
    let rootDirectory: URL
    @Binding var selectedFile: URL?
    let fileSystemService: FileSystemService

    @State private var items: [FileItem] = []
    @State private var isLoading = true
    @State private var expandedFolders: Set<URL> = []

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)

                Text(rootDirectory.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                ContentUnavailableView(
                    "Empty Directory",
                    systemImage: "folder",
                    description: Text("This directory is empty")
                )
            } else {
                List(selection: $selectedFile) {
                    ForEach(items) { item in
                        FileItemRowView(
                            item: item,
                            expandedFolders: $expandedFolders,
                            selectedFile: $selectedFile,
                            level: 0
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await loadDirectory()
        }
    }

    private func loadDirectory() async {
        isLoading = true
        items = await fileSystemService.loadDirectory(rootDirectory)
        isLoading = false
    }

    private func refresh() {
        Task {
            await loadDirectory()
        }
    }
}

struct FileItemRowView: View {
    let item: FileItem
    @Binding var expandedFolders: Set<URL>
    @Binding var selectedFile: URL?
    let level: Int

    private var isExpanded: Bool {
        expandedFolders.contains(item.url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                if item.isDirectory {
                    Button(action: toggleExpanded) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 12)
                }

                Image(systemName: item.iconName)
                    .foregroundStyle(iconColor)

                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.leading, CGFloat(level * 16))
            .padding(.vertical, 4)
            .contentShape(Rectangle())
            .background(selectedFile == item.url ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onTapGesture {
                if item.isDirectory {
                    toggleExpanded()
                } else {
                    selectedFile = item.url
                }
            }

            if item.isDirectory && isExpanded, let children = item.children {
                ForEach(children) { child in
                    FileItemRowView(
                        item: child,
                        expandedFolders: $expandedFolders,
                        selectedFile: $selectedFile,
                        level: level + 1
                    )
                }
            }
        }
    }

    private var iconColor: Color {
        if item.isDirectory {
            return .blue
        }
        switch item.iconColor {
        case "orange": return .orange
        case "yellow": return .yellow
        case "blue": return .blue
        case "red": return .red
        case "cyan": return .cyan
        default: return .secondary
        }
    }

    private func toggleExpanded() {
        if isExpanded {
            expandedFolders.remove(item.url)
        } else {
            expandedFolders.insert(item.url)
        }
    }
}

#Preview {
    FileBrowserView(
        rootDirectory: FileManager.default.homeDirectoryForCurrentUser,
        selectedFile: .constant(nil),
        fileSystemService: FileSystemService()
    )
    .frame(width: 300, height: 500)
}
