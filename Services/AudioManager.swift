import Foundation
import AVFoundation

final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()

    private var bufferHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    private var converter: AVAudioConverter?

    func startListening(_ onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) throws {
        self.bufferHandler = onBuffer

        // Configure audio session
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.mixWithOthers, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)

        // Target format for ShazamKit: 44.1kHz, mono, float32
        let desiredFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                          sampleRate: 44100,
                                          channels: 1,
                                          interleaved: false)!

        // Reuse a converter
        self.converter = AVAudioConverter(from: inputFormat, to: desiredFormat)

        // Install tap with smaller buffer size
        input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, when in
            guard let self = self, let converter = self.converter else { return }

            let outBuffer = AVAudioPCMBuffer(pcmFormat: desiredFormat,
                                             frameCapacity: AVAudioFrameCount(buffer.frameCapacity))!

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }

            converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)

            if let error = error {
                print("Audio conversion error: \(error)")
                return
            }

            onBuffer(outBuffer, when)
        }

        try engine.start()
        print("🎙️ Audio engine started")
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? session.setActive(false)
        print("🛑 Audio engine stopped")
    }
}
