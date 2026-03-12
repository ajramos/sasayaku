@preconcurrency import AVFoundation
import Foundation

final class AudioCaptureService: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var audioBuffer: [Float] = []
    private let lock = NSLock()
    private let targetSampleRate: Double = 16000

    func startRecording() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        print("[Sasayaku] Native audio format: \(nativeFormat.sampleRate)Hz, \(nativeFormat.channelCount)ch, \(nativeFormat.commonFormat.rawValue)")

        guard nativeFormat.sampleRate > 0 else {
            throw AudioError.noInputDevice
        }

        lock.lock()
        audioBuffer = []
        lock.unlock()

        // Use nil format to get the native format — most reliable
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            guard let self else { return }
            let samples = Self.extractAndResample(buffer: buffer, targetRate: self.targetSampleRate)
            if !samples.isEmpty {
                self.lock.lock()
                self.audioBuffer.append(contentsOf: samples)
                self.lock.unlock()
            }
        }

        engine.prepare()
        try engine.start()
        self.audioEngine = engine
        print("[Sasayaku] Audio engine started, recording...")
    }

    func stopRecording() -> [Float] {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        lock.lock()
        let result = audioBuffer
        audioBuffer = []
        lock.unlock()

        return result
    }

    /// Extract float samples from buffer and resample to target rate if needed
    private static func extractAndResample(buffer: AVAudioPCMBuffer, targetRate: Double) -> [Float] {
        let sourceRate = buffer.format.sampleRate
        let channelCount = buffer.format.channelCount
        let frameLength = Int(buffer.frameLength)

        guard frameLength > 0 else { return [] }

        // Get mono float samples
        var monoSamples: [Float]

        if let floatData = buffer.floatChannelData {
            // Already float format — take first channel
            monoSamples = Array(UnsafeBufferPointer(start: floatData[0], count: frameLength))
        } else if let int16Data = buffer.int16ChannelData {
            // Convert int16 to float
            monoSamples = (0..<frameLength).map { i in
                Float(int16Data[0][i]) / Float(Int16.max)
            }
        } else if let int32Data = buffer.int32ChannelData {
            // Convert int32 to float
            monoSamples = (0..<frameLength).map { i in
                Float(int32Data[0][i]) / Float(Int32.max)
            }
        } else {
            return []
        }

        // If multi-channel, we already took channel 0 (mono)

        // Resample if needed
        guard sourceRate != targetRate else { return monoSamples }

        let ratio = targetRate / sourceRate
        let outputLength = Int(Double(monoSamples.count) * ratio)
        guard outputLength > 0 else { return [] }

        // Simple linear interpolation resampling
        var resampled = [Float](repeating: 0, count: outputLength)
        for i in 0..<outputLength {
            let srcIndex = Double(i) / ratio
            let srcIndexFloor = Int(srcIndex)
            let frac = Float(srcIndex - Double(srcIndexFloor))

            let s0 = monoSamples[min(srcIndexFloor, monoSamples.count - 1)]
            let s1 = monoSamples[min(srcIndexFloor + 1, monoSamples.count - 1)]
            resampled[i] = s0 + frac * (s1 - s0)
        }

        return resampled
    }
}

enum AudioError: LocalizedError {
    case converterCreationFailed
    case noInputDevice

    var errorDescription: String? {
        switch self {
        case .converterCreationFailed: "Failed to create audio converter"
        case .noInputDevice: "No audio input device found"
        }
    }
}
