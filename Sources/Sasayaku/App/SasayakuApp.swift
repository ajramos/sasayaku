import SwiftUI

@main
struct SasayakuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()
    @State private var coordinator: AppCoordinator?

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environment(appState)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarIcon)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(menuBarIconColor)
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: appState.recordingState, initial: true) { _, _ in
            if coordinator == nil {
                coordinator = AppCoordinator(appState: appState)
                coordinator?.setup()
            }
        }
    }

    private var menuBarIcon: String {
        switch appState.recordingState {
        case .idle: "mic"
        case .recording: "mic.circle.fill"
        case .transcribing: "mic.badge.xmark"
        case .error: "mic.slash"
        }
    }

    private var menuBarIconColor: Color {
        switch appState.recordingState {
        case .idle: .primary
        case .recording: .green
        case .transcribing: .orange
        case .error: .red
        }
    }
}

@MainActor
final class AppCoordinator {
    private let appState: AppState
    private let audioService = AudioCaptureService()
    private let transcriptionService = TranscriptionService()
    private let hotkeyService = HotkeyService()
    private let downloader = ModelDownloader()

    init(appState: AppState) {
        self.appState = appState
    }

    func setup() {
        appState.isModelDownloaded = appState.selectedModel.isDownloaded

        hotkeyService.onRecordingStarted = { [weak self] in
            self?.startRecording()
        }
        hotkeyService.onRecordingStopped = { [weak self] in
            self?.stopRecording()
        }
        hotkeyService.start()

        // Load model if already downloaded
        if appState.isModelDownloaded {
            transcriptionService.loadModel(appState.selectedModel, language: appState.selectedLanguage)
        }

        // Listen for download requests
        NotificationCenter.default.addObserver(
            forName: .downloadModel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.downloadModel()
            }
        }
    }

    private func startRecording() {
        print("[Sasayaku] startRecording called, state=\(appState.recordingState), modelDownloaded=\(appState.isModelDownloaded)")
        guard appState.recordingState == .idle else { return }

        guard appState.isModelDownloaded else {
            appState.recordingState = .error("Download a model first")
            Task {
                try? await Task.sleep(for: .seconds(3))
                if case .error = appState.recordingState {
                    appState.recordingState = .idle
                }
            }
            return
        }

        do {
            try audioService.startRecording()
            appState.recordingState = .recording
            print("[Sasayaku] Recording started")
        } catch {
            print("[Sasayaku] Recording failed: \(error)")
            appState.recordingState = .error(error.localizedDescription)
        }
    }

    private func stopRecording() {
        print("[Sasayaku] stopRecording called, state=\(appState.recordingState)")
        guard appState.isRecording else { return }
        appState.recordingState = .transcribing

        Task {
            let audioFrames = audioService.stopRecording()
            print("[Sasayaku] Got \(audioFrames.count) audio frames (\(String(format: "%.1f", Double(audioFrames.count) / 16000))s)")

            guard !audioFrames.isEmpty else {
                print("[Sasayaku] No audio frames captured")
                appState.recordingState = .idle
                return
            }

            do {
                let text = try await transcriptionService.transcribe(
                    audioFrames: audioFrames
                )
                print("[Sasayaku] Transcription: '\(text)'")

                guard !text.isEmpty else {
                    appState.recordingState = .idle
                    return
                }

                appState.lastTranscription = text
                TextInsertionService.insertText(text)
                appState.recordingState = .idle
            } catch {
                appState.recordingState = .error(error.localizedDescription)
                // Auto-recover to idle after 3 seconds
                try? await Task.sleep(for: .seconds(3))
                appState.recordingState = .idle
            }
        }
    }

    private func downloadModel() {
        guard !appState.isDownloading else { return }
        appState.isDownloading = true
        appState.downloadProgress = 0

        let model = appState.selectedModel
        Task {
            do {
                _ = try await downloader.download(model: model) { [weak self] progress in
                    Task { @MainActor in
                        self?.appState.downloadProgress = progress
                    }
                }
                appState.isModelDownloaded = true
                appState.isDownloading = false
                transcriptionService.loadModel(model, language: appState.selectedLanguage)
            } catch {
                appState.isDownloading = false
                appState.recordingState = .error("Download failed: \(error.localizedDescription)")
            }
        }
    }
}
