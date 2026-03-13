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
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
        .onChange(of: appState.recordingState, initial: true) { _, _ in
            if coordinator == nil {
                coordinator = AppCoordinator(appState: appState)
                coordinator?.setup()
            }
        }
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        switch appState.recordingState {
        case .idle:
            Image(systemName: "waveform")
        case .recording:
            HStack(spacing: 3) {
                Image(systemName: "waveform")
                Circle()
                    .fill(.red)
                    .frame(width: 7, height: 7)
            }
        case .transcribing:
            HStack(spacing: 3) {
                Image(systemName: "waveform")
                Image(systemName: "ellipsis")
                    .font(.system(size: 8))
            }
        case .error:
            HStack(spacing: 3) {
                Image(systemName: "waveform")
                Image(systemName: "exclamationmark")
                    .font(.system(size: 8, weight: .bold))
            }
        }
    }
}

private func ts() -> String {
    let f = DateFormatter()
    f.dateFormat = "HH:mm:ss.SSS"
    return f.string(from: Date())
}

@MainActor
final class AppCoordinator {
    private let appState: AppState
    private let audioService = AudioCaptureService()
    private let transcriptionService = TranscriptionService()
    private let hotkeyService = HotkeyService()

    init(appState: AppState) {
        self.appState = appState
    }

    func setup() {
        hotkeyService.onRecordingStarted = { [weak self] in
            self?.startRecording()
        }
        hotkeyService.onRecordingStopped = { [weak self] in
            self?.stopRecording()
        }
        hotkeyService.start()

        // Auto-load model on startup
        loadModel()

        // Listen for model change requests from Settings
        NotificationCenter.default.addObserver(
            forName: .loadModel,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadModel()
            }
        }
    }

    private func loadModel() {
        guard !appState.isLoadingModel else { return }
        appState.isLoadingModel = true
        appState.isModelReady = false

        let model = appState.selectedModel
        let language = appState.selectedLanguage
        Task {
            do {
                print("[Sasayaku] Loading model \(model.rawValue)...")
                try await transcriptionService.loadModel(model, language: language)
                appState.isModelReady = true
                appState.isLoadingModel = false
                print("[Sasayaku] Model ready: \(model.rawValue)")
            } catch {
                appState.isLoadingModel = false
                appState.recordingState = .error("Model load failed: \(error.localizedDescription)")
                print("[Sasayaku] Model load failed: \(error)")
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    if case .error = appState.recordingState {
                        appState.recordingState = .idle
                    }
                }
            }
        }
    }

    private func startRecording() {
        print("[Sasayaku] startRecording called, state=\(appState.recordingState), modelReady=\(appState.isModelReady)")
        guard appState.recordingState == .idle else { return }

        guard appState.isModelReady else {
            let msg = appState.isLoadingModel ? "Model is loading, please wait..." : "Model not ready"
            appState.recordingState = .error(msg)
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
            let audioDuration = String(format: "%.1f", Double(audioFrames.count) / 16000)
            print("[Sasayaku] \(ts()) Got \(audioFrames.count) frames (\(audioDuration)s)")

            guard !audioFrames.isEmpty else {
                print("[Sasayaku] \(ts()) No audio frames captured")
                appState.recordingState = .idle
                return
            }

            do {
                print("[Sasayaku] \(ts()) Transcribing...")
                let text = try await transcriptionService.transcribe(
                    audioFrames: audioFrames
                )
                print("[Sasayaku] \(ts()) Done: '\(text)'")

                guard !text.isEmpty else {
                    appState.recordingState = .idle
                    return
                }

                appState.lastTranscription = text
                TextInsertionService.insertText(text)
                appState.recordingState = .idle
            } catch {
                appState.recordingState = .error(error.localizedDescription)
                try? await Task.sleep(for: .seconds(3))
                appState.recordingState = .idle
            }
        }
    }
}
