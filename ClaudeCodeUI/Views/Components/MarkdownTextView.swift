import SwiftUI

struct MarkdownTextView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(parseBlocks().enumerated()), id: \.offset) { _, block in
                switch block {
                case .text(let content):
                    Text(parseInlineMarkdown(content))
                        .textSelection(.enabled)

                case .code(let language, let content):
                    CodeBlockView(language: language, code: content)
                }
            }
        }
    }

    private enum Block {
        case text(String)
        case code(language: String, content: String)
    }

    private func parseBlocks() -> [Block] {
        var blocks: [Block] = []
        var currentText = ""
        var inCodeBlock = false
        var codeLanguage = ""
        var codeContent = ""

        let lines = text.components(separatedBy: "\n")

        for line in lines {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    blocks.append(.code(language: codeLanguage, content: codeContent.trimmingCharacters(in: .newlines)))
                    codeLanguage = ""
                    codeContent = ""
                    inCodeBlock = false
                } else {
                    if !currentText.isEmpty {
                        blocks.append(.text(currentText.trimmingCharacters(in: .newlines)))
                        currentText = ""
                    }
                    codeLanguage = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                    inCodeBlock = true
                }
            } else if inCodeBlock {
                if !codeContent.isEmpty {
                    codeContent += "\n"
                }
                codeContent += line
            } else {
                if !currentText.isEmpty {
                    currentText += "\n"
                }
                currentText += line
            }
        }

        if !currentText.isEmpty {
            blocks.append(.text(currentText.trimmingCharacters(in: .newlines)))
        }

        if inCodeBlock && !codeContent.isEmpty {
            blocks.append(.code(language: codeLanguage, content: codeContent.trimmingCharacters(in: .newlines)))
        }

        return blocks
    }

    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var result = AttributedString()

        let boldPattern = #"\*\*(.+?)\*\*"#
        let italicPattern = #"\*(.+?)\*"#
        let codePattern = #"`([^`]+)`"#
        let linkPattern = #"\[([^\]]+)\]\(([^\)]+)\)"#

        var processedText = text

        if let attributedString = try? AttributedString(markdown: processedText, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return attributedString
        }

        result = AttributedString(processedText)
        return result
    }
}

#Preview {
    ScrollView {
        MarkdownTextView(text: """
        # Hello World

        This is **bold** and this is *italic*.

        Here's some `inline code` in a sentence.

        ```swift
        struct ContentView: View {
            var body: some View {
                Text("Hello!")
            }
        }
        ```

        And here's a [link](https://example.com).

        - Item 1
        - Item 2
        - Item 3
        """)
        .padding()
    }
    .frame(width: 500, height: 600)
}
