@preconcurrency import AVFoundation
import Foundation

final class AudioCaptureService: @unchecked Sendable {
    private var audioEngine: AVAudioEngine?
    private var audioBuffer: [Float] = []
    private let lock = NSLock()
    private var tapInstalled = false
    private var tapCallCount = 0

    func startRecording() throws {
        // Create a fresh engine each time to avoid keeping the mic active
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let hwFormat = inputNode.outputFormat(forBus: 0)
        print("[Sasayaku] Hardware format: rate=\(hwFormat.sampleRate) ch=\(hwFormat.channelCount)")

        // CRITICAL: Access mainMixerNode to force the audio graph to be built.
        // Without this, taps on inputNode may never fire at certain sample rates.
        let mixer = engine.mainMixerNode
        mixer.outputVolume = 0

        // Create a 16kHz mono format for Whisper
        let whisperFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false)!

        // Create converter if sample rate differs
        let needsConversion = hwFormat.sampleRate != 16000 || hwFormat.channelCount != 1
        var converter: AVAudioConverter?
        if needsConversion {
            converter = AVAudioConverter(from: hwFormat, to: whisperFormat)
            if converter == nil {
                print("[Sasayaku] WARNING: Could not create converter — will use manual resampling")
            } else {
                print("[Sasayaku] Converter ready: \(hwFormat.sampleRate)Hz/\(hwFormat.channelCount)ch → 16000Hz/1ch")
            }
        }

        lock.lock()
        audioBuffer = []
        tapCallCount = 0
        lock.unlock()

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            guard let self else { return }

            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0, let floatData = buffer.floatChannelData else { return }

            var samples: [Float]

            if let converter {
                let ratio = 16000.0 / buffer.format.sampleRate
                let outputFrames = AVAudioFrameCount(Double(frameLength) * ratio)
                guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: whisperFormat, frameCapacity: outputFrames) else { return }

                var error: NSError?
                let inputBuffer = buffer
                var hasProvidedInput = false
                converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                    if hasProvidedInput {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    hasProvidedInput = true
                    outStatus.pointee = .haveData
                    return inputBuffer
                }

                if let error {
                    print("[Sasayaku] Converter error: \(error)")
                    return
                }

                guard let outData = outputBuffer.floatChannelData, outputBuffer.frameLength > 0 else { return }
                samples = Array(UnsafeBufferPointer(start: outData[0], count: Int(outputBuffer.frameLength)))
            } else if buffer.format.sampleRate != 16000 {
                let raw = Array(UnsafeBufferPointer(start: floatData[0], count: frameLength))
                samples = Self.resample(raw, from: buffer.format.sampleRate, to: 16000)
            } else {
                samples = Array(UnsafeBufferPointer(start: floatData[0], count: frameLength))
            }

            self.lock.lock()
            self.tapCallCount += 1
            self.audioBuffer.append(contentsOf: samples)
            let count = self.tapCallCount
            let total = self.audioBuffer.count
            self.lock.unlock()

            if count <= 3 || count % 50 == 0 {
                print("[Sasayaku] TAP #\(count): \(frameLength)→\(samples.count) frames, total=\(total)")
            }
        }
        tapInstalled = true

        engine.prepare()
        do {
            try engine.start()
            self.audioEngine = engine
            print("[Sasayaku] Audio engine started — recording")
        } catch {
            print("[Sasayaku] Audio engine start failed: \(error)")
            throw AudioError.noInputDevice
        }
    }

    func stopRecording() -> [Float] {
        if tapInstalled, let engine = audioEngine {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        // Stop and release the engine so macOS hides the mic indicator
        audioEngine?.stop()
        audioEngine = nil

        lock.lock()
        let result = audioBuffer
        let taps = tapCallCount
        audioBuffer = []
        tapCallCount = 0
        lock.unlock()

        print("[Sasayaku] Stopped: \(result.count) frames from \(taps) callbacks")
        return result
    }

    private static func resample(_ input: [Float], from sourceRate: Double, to targetRate: Double) -> [Float] {
        let ratio = targetRate / sourceRate
        let outputLength = Int(Double(input.count) * ratio)
        guard outputLength > 0 else { return [] }

        var output = [Float](repeating: 0, count: outputLength)
        for i in 0..<outputLength {
            let srcIdx = Double(i) / ratio
            let idx = Int(srcIdx)
            let frac = Float(srcIdx - Double(idx))
            let s0 = input[min(idx, input.count - 1)]
            let s1 = input[min(idx + 1, input.count - 1)]
            output[i] = s0 + frac * (s1 - s0)
        }
        return output
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
