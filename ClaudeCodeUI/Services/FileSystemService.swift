import Foundation

@Observable
final class FileSystemService {
    func loadDirectory(_ url: URL) async -> [FileItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let items = self.loadDirectorySync(url)
                continuation.resume(returning: items)
            }
        }
    }

    private func loadDirectorySync(_ url: URL) -> [FileItem] {
        var items: [FileItem] = []

        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return items
        }

        for fileURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)

            let children: [FileItem]? = isDirectory.boolValue ? loadDirectorySync(fileURL) : nil

            items.append(FileItem(
                url: fileURL,
                name: fileURL.lastPathComponent,
                isDirectory: isDirectory.boolValue,
                children: children
            ))
        }

        return items.sorted { item1, item2 in
            if item1.isDirectory != item2.isDirectory {
                return item1.isDirectory
            }
            return item1.name.localizedStandardCompare(item2.name) == .orderedAscending
        }
    }

    func readFile(_ url: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let content = try String(contentsOf: url, encoding: .utf8)
                    continuation.resume(returning: content)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
        return isDir.boolValue
    }
}

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let children: [FileItem]?

    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "js", "jsx": return "curlybraces"
        case "ts", "tsx": return "curlybraces"
        case "json": return "doc.text"
        case "md", "markdown": return "doc.richtext"
        case "png", "jpg", "jpeg", "gif", "svg": return "photo"
        case "html", "htm": return "globe"
        case "css", "scss", "sass": return "paintbrush"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "rb": return "diamond"
        case "go": return "g.circle"
        case "rs": return "gearshape"
        case "sh", "bash", "zsh": return "terminal"
        case "yml", "yaml": return "doc.text"
        case "xml": return "chevron.left.slash.chevron.right"
        case "txt": return "doc.text"
        case "pdf": return "doc.fill"
        default: return "doc"
        }
    }

    var iconColor: String {
        if isDirectory {
            return "blue"
        }

        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "orange"
        case "js", "jsx", "ts", "tsx": return "yellow"
        case "json": return "gray"
        case "md", "markdown": return "blue"
        case "py": return "blue"
        case "rb": return "red"
        case "go": return "cyan"
        case "rs": return "orange"
        default: return "gray"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool {
        lhs.url == rhs.url
    }
}
