import Foundation
import WhisperKit

final class TranscriptionService: @unchecked Sendable {
    private var whisperKit: WhisperKit?
    private var currentModel: WhisperModelType?
    private var currentLanguage: String?

    var isModelLoaded: Bool { whisperKit != nil }

    /// Load or switch WhisperKit model. This auto-downloads if needed.
    func loadModel(_ modelType: WhisperModelType, language: String = "es") async throws {
        if currentModel == modelType, whisperKit != nil {
            currentLanguage = language
            return
        }

        // Unload previous
        whisperKit = nil
        currentModel = nil

        print("[Sasayaku] Loading WhisperKit model: \(modelType.rawValue)")
        let config = WhisperKitConfig(
            model: "openai_whisper-\(modelType.rawValue)",
            verbose: true,
            logLevel: .info
        )
        let kit = try await WhisperKit(config)
        self.whisperKit = kit
        self.currentModel = modelType
        self.currentLanguage = language
        print("[Sasayaku] WhisperKit model loaded: \(modelType.rawValue)")
    }

    func transcribe(audioFrames: [Float]) async throws -> String {
        guard let whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }

        let duration = Double(audioFrames.count) / 16000.0
        let maxAmplitude = audioFrames.map { abs($0) }.max() ?? 0
        print("[Sasayaku] Transcribing \(String(format: "%.1f", duration))s audio, max amplitude: \(String(format: "%.4f", maxAmplitude)), language: \(currentLanguage ?? "auto")")

        let options = DecodingOptions(
            language: currentLanguage,
            temperature: 0.0,
            usePrefillPrompt: true
        )

        let results = try await whisperKit.transcribe(audioArray: audioFrames, decodeOptions: options)
        let text = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        print("[Sasayaku] Result: '\(text)'")
        return text
    }

    func unloadModel() {
        whisperKit = nil
        currentModel = nil
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
