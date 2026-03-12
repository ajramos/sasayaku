import SwiftUI

struct StatusIndicator: View {
    let state: RecordingState
    var isModelReady: Bool = true

    var body: some View {
        HStack(spacing: 10) {
            // Animated status orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(indicatorColor.opacity(state == .recording ? 0.3 : 0.15))
                    .frame(width: 32, height: 32)
                    .scaleEffect(state == .recording ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: state == .recording)

                // Inner circle
                Circle()
                    .fill(indicatorColor)
                    .frame(width: 12, height: 12)

                // Icon overlay
                Image(systemName: iconName)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(statusLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(statusDetail)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var needsSetup: Bool {
        !isModelReady && state == .idle
    }

    private var indicatorColor: Color {
        if needsSetup { return .yellow }
        switch state {
        case .idle: return .green
        case .recording: return .red
        case .transcribing: return .orange
        case .error: return .red
        }
    }

    private var iconName: String {
        if needsSetup { return "arrow.down" }
        switch state {
        case .idle: return "mic.fill"
        case .recording: return "waveform"
        case .transcribing: return "text.cursor"
        case .error: return "xmark"
        }
    }

    private var statusLabel: String {
        if needsSetup { return "Setup needed" }
        switch state {
        case .idle: return "Ready"
        case .recording: return "Listening..."
        case .transcribing: return "Transcribing..."
        case .error(let msg): return msg
        }
    }

    private var statusDetail: String {
        if needsSetup { return "Download a model below to start" }
        switch state {
        case .idle: return "Hold ⌥ Option to speak"
        case .recording: return "Release to transcribe"
        case .transcribing: return "Processing audio"
        case .error: return "Try again"
        }
    }
}
