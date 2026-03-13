import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                    Text("Sasayaku")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("v1.1")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Status card
            StatusIndicator(state: appState.recordingState, isModelReady: appState.isModelReady)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(statusCardColor)
                )
                .padding(.horizontal, 12)

            // Model loading indicator
            if appState.isLoadingModel {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading \(appState.selectedModel.rawValue) model...")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(.blue.opacity(0.06))
                )
                .padding(.horizontal, 12)
                .padding(.top, 8)
            }

            // Last transcription
            if !appState.lastTranscription.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label("Last result", systemImage: "text.quote")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.quaternary)
                            .textCase(.uppercase)
                        Spacer()
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(appState.lastTranscription, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .help("Copy to clipboard")
                    }

                    Text(appState.lastTranscription)
                        .font(.system(size: 12))
                        .lineLimit(4)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
                        )
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
            }

            Spacer().frame(height: 12)

            Divider()
                .padding(.horizontal, 12)

            // Menu items
            VStack(spacing: 0) {
                MenuRow(icon: "gear", label: "Settings") {
                    SettingsWindowController.shared.show(appState: appState)
                }
                MenuRow(icon: "power", label: "Quit", tint: .secondary) {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .frame(width: 300)
    }

    private var statusCardColor: Color {
        switch appState.recordingState {
        case .recording: .red.opacity(0.08)
        case .transcribing: .orange.opacity(0.08)
        case .error: .red.opacity(0.06)
        default: .primary.opacity(0.04)
        }
    }
}

// MARK: - Settings Window

@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    private var window: NSWindow?

    func show(appState: AppState) {
        if let window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView(appState: appState)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Sasayaku Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 360, height: 400))
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}

// MARK: - Components

private struct MenuRow: View {
    let icon: String
    let label: String
    var tint: Color = .accentColor
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 16)
                    .foregroundStyle(isHovered ? .white : .secondary)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(isHovered ? .white : .primary)
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isHovered ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

extension Notification.Name {
    static let loadModel = Notification.Name("loadModel")
}
