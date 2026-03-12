import Foundation
import SwiftWhisper

final class TranscriptionService: @unchecked Sendable {
    private var whisper: Whisper?
    private var currentModelType: WhisperModelType?

    func loadModel(_ modelType: WhisperModelType, language: String = "es") {
        guard modelType.isDownloaded else { return }

        if currentModelType == modelType, whisper != nil {
            return
        }

        var params: WhisperParams = .default
        params.language = WhisperLanguage(rawValue: language) ?? .spanish
        params.no_context = true
        params.single_segment = false
        params.print_progress = false
        params.print_timestamps = false

        whisper = Whisper(fromFileURL: modelType.localURL, withParams: params)
        currentModelType = modelType
    }

    func transcribe(audioFrames: [Float]) async throws -> String {
        guard let whisper else {
            throw TranscriptionError.modelNotLoaded
        }

        // Log audio stats for debugging
        let duration = Double(audioFrames.count) / 16000.0
        let maxAmplitude = audioFrames.map { abs($0) }.max() ?? 0
        print("[Sasayaku] Transcribing \(String(format: "%.1f", duration))s audio, max amplitude: \(String(format: "%.4f", maxAmplitude)), language: \(whisper.params.language)")

        let segments = try await whisper.transcribe(audioFrames: audioFrames)
        let text = segments.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Sasayaku] Segments: \(segments.count), text: '\(text)'")
        return text
    }

    func unloadModel() {
        whisper = nil
        currentModelType = nil
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotDownloaded
    case modelNotLoaded

    var errorDescription: String? {
        switch self {
        case .modelNotDownloaded: "Whisper model not downloaded"
        case .modelNotLoaded: "Whisper model not loaded"
        }
    }
}
