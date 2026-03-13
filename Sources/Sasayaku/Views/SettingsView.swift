import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.blue)
                Text("Settings")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 16) {
                    // Model
                    SettingsCard(title: "Model", icon: "cpu", color: .purple) {
                        Picker("Model", selection: $appState.selectedModel) {
                            ForEach(WhisperModelType.allCases) { model in
                                VStack(alignment: .leading) {
                                    Text(model.displayName)
                                }
                                .tag(model)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: appState.selectedModel) { _, _ in
                            NotificationCenter.default.post(name: .loadModel, object: nil)
                        }

                        if appState.isLoadingModel {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Downloading & loading...")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                        } else if appState.isModelReady {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 11))
                                Text("Ready")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundStyle(.green)
                        }

                        Text(appState.selectedModel.description)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }

                    // Language
                    SettingsCard(title: "Language", icon: "globe", color: .blue) {
                        Picker("Language", selection: $appState.selectedLanguage) {
                            Text("Spanish").tag("es")
                            Text("English").tag("en")
                            Text("Auto-detect").tag("auto")
                        }
                        .labelsHidden()
                    }

                    // Hotkey
                    SettingsCard(title: "Hotkey", icon: "command.circle", color: .orange) {
                        HStack {
                            Text("Option (⌥)")
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("Hold to record")
                                .font(.system(size: 11))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.orange.opacity(0.1))
                                )
                                .foregroundStyle(.orange)
                        }
                    }

                    // Permissions
                    SettingsCard(title: "Permissions", icon: "lock.shield.fill", color: .green) {
                        HStack {
                            Text("Accessibility")
                                .font(.system(size: 12))
                            Spacer()
                            if Permissions.isAccessibilityEnabled {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("Granted")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundStyle(.green)
                            } else {
                                Button("Grant Access") {
                                    Permissions.promptAccessibility()
                                }
                                .controlSize(.small)
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .frame(width: 360, height: 400)
    }
}

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }

            VStack(spacing: 10) {
                content
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.background)
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
            )
        }
    }
}
