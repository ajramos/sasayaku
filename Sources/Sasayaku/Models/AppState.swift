import SwiftUI

enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)
}

@Observable
@MainActor
final class AppState {
    var recordingState: RecordingState = .idle
    var lastTranscription: String = ""
    var selectedModel: WhisperModelType = .base
    var selectedLanguage: String = "es"
    var isModelReady: Bool = false
    var isLoadingModel: Bool = false
    var statusText: String = "Ready"

    var isRecording: Bool {
        recordingState == .recording
    }

    var isTranscribing: Bool {
        recordingState == .transcribing
    }
}
