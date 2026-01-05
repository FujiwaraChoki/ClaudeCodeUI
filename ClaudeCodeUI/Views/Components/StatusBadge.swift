import SwiftUI

struct StatusBadge: View {
    let status: SessionStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .active: return .green
        case .idle: return .orange
        case .terminated: return .gray
        }
    }

    private var statusText: String {
        switch status {
        case .active: return "Active"
        case .idle: return "Idle"
        case .terminated: return "Ended"
        }
    }
}

struct ToolStatusBadge: View {
    let status: ToolCallStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)

            Text(statusText)
                .font(.caption2)
        }
        .foregroundStyle(statusColor)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var iconName: String {
        switch status {
        case .pending: return "clock"
        case .approved: return "checkmark"
        case .denied: return "xmark"
        case .executing: return "play.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var statusText: String {
        switch status {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .denied: return "Denied"
        case .executing: return "Running"
        case .completed: return "Done"
        case .failed: return "Failed"
        }
    }

    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        case .executing: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        StatusBadge(status: .active)
        StatusBadge(status: .idle)
        StatusBadge(status: .terminated)

        Divider()

        ToolStatusBadge(status: .pending)
        ToolStatusBadge(status: .approved)
        ToolStatusBadge(status: .denied)
        ToolStatusBadge(status: .executing)
        ToolStatusBadge(status: .completed)
        ToolStatusBadge(status: .failed)
    }
    .padding()
}
