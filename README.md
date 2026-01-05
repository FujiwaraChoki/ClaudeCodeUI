# Claude Code UI

A native SwiftUI macOS application that provides a graphical interface for [Claude Code](https://claude.ai/code), Anthropic's AI coding agent.

![macOS 26+](https://img.shields.io/badge/macOS-26%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Native-green)

## Features

- **Three-Column Layout** - Sessions sidebar, chat view, and detail panel
- **Session Management** - Create, resume, and delete conversation sessions
- **Tool Approval UI** - Visual interface to approve/deny tool calls (file edits, bash commands)
- **File Browser** - Browse and select working directories, view project files
- **File Preview** - Preview code files with syntax highlighting
- **Markdown Rendering** - Rich rendering of Claude's responses with code blocks
- **Real-time Streaming** - Live streaming of Claude's responses
- **Keyboard Shortcuts** - Cmd+N for new session, Cmd+Return to send

## Requirements

- macOS 26 (Tahoe) or later
- [Claude Code CLI](https://claude.ai/code) installed and authenticated
- Xcode 26+ (for building from source)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/ClaudeCodeUI.git
   cd ClaudeCodeUI
   ```

2. Open in Xcode:
   ```bash
   open ClaudeCodeUI.xcodeproj
   ```

3. Build and run (Cmd+R)

### Prerequisites

Ensure Claude Code CLI is installed and accessible:

```bash
# Check if claude is installed
which claude

# Authenticate if needed
claude auth
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Three-Column Layout                          │
├──────────────┬─────────────────────────┬───────────────────────┤
│   Sidebar    │        Chat View        │    Detail Panel       │
│              │                         │                       │
│ - Sessions   │ - Message list          │ - Tool approval       │
│ - New/Resume │ - User/Assistant msgs   │ - File preview        │
│ - Delete     │ - Code blocks           │ - File browser        │
│              │ - Input field           │                       │
└──────────────┴─────────────────────────┴───────────────────────┘
```

## Project Structure

```
ClaudeCodeUI/
├── ClaudeCodeUIApp.swift           # App entry point
├── Models/
│   ├── Session.swift               # Session data model
│   ├── Message.swift               # Message data model
│   ├── ToolCall.swift              # Tool invocation model
│   └── StreamEvent.swift           # CLI stream event parsing
├── Services/
│   ├── CLIService.swift            # Claude CLI process management
│   ├── SessionManager.swift        # Session CRUD operations
│   └── FileSystemService.swift     # File/directory operations
├── ViewModels/
│   ├── AppState.swift              # Root application state
│   └── ChatViewModel.swift         # Chat message state
└── Views/
    ├── MainView.swift              # Root NavigationSplitView
    ├── Sidebar/
    │   └── SessionListView.swift   # Session list
    ├── Chat/
    │   ├── ChatView.swift          # Chat container
    │   ├── MessageListView.swift   # Message list
    │   ├── MessageBubbleView.swift # Message bubbles
    │   └── InputView.swift         # Text input
    ├── Detail/
    │   ├── DetailPanelView.swift   # Detail panel container
    │   ├── ToolApprovalView.swift  # Tool approval UI
    │   ├── FileBrowserView.swift   # File tree browser
    │   └── FilePreviewView.swift   # File content preview
    └── Components/
        ├── CodeBlockView.swift     # Code block rendering
        ├── MarkdownTextView.swift  # Markdown rendering
        ├── StatusBadge.swift       # Status indicators
        └── ToolCallBadge.swift     # Tool call display
```

## How It Works

Claude Code UI communicates with the Claude Code CLI using subprocess management:

1. **Process Spawning** - Launches `claude` CLI with `--output-format stream-json`
2. **Stdin/Stdout** - Sends user messages via stdin, receives responses via stdout
3. **JSON Streaming** - Parses newline-delimited JSON events in real-time
4. **Tool Approval** - Intercepts tool calls and presents them for user approval

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New session |
| `Cmd+Return` | Send message |
| `Escape` | Deny tool call |
| `Return` | Approve tool call (when focused) |

## Tech Stack

- **SwiftUI** - Native UI framework
- **SwiftData** - Persistence for sessions and messages
- **Foundation.Process** - CLI subprocess management
- **@Observable** - Modern state management

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Claude Code](https://claude.ai/code) by Anthropic
- Built with SwiftUI for macOS
