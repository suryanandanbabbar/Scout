import Foundation
import AVFoundation
import Accelerate

final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    
    private let levelSmoother = ExponentialSmoother(alpha: 0.2)

    @Published var audioLevel: Float = 0.0

    func startListening(_ onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) throws {
        try session.setCategory(.playAndRecord,
                                mode: .measurement,
                                options: [.mixWithOthers, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let input = engine.inputNode
        let inputFormat = input.inputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, when in
            guard let self = self else { return }
            self.calculateAudioLevel(from: buffer)
            onBuffer(buffer, when)
        }

        try engine.start()
        print("🎙️ Audio engine started")
    }

    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        audioLevel = 0.0
        try? session.setActive(false)
        print("🛑 Audio engine stopped")
    }
    
    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        
        // Calculate root mean square (RMS)
        var magnitude: Float = 0
        vDSP_rmsqv(channelData[0], 1, &magnitude, vDSP_Length(frameLength))
        
        // Clamp the value to a 0-1 range
        let clampedMagnitude = max(0, min(1, magnitude))
        
        // Increasing the amplification for more sensitivity
        let amplificationFactor: Float = 40.0
        let amplified = clampedMagnitude * amplificationFactor
        
        // Smooth the value to prevent jitter
        let smoothedLevel = self.levelSmoother.push(Double(amplified))
        
        DispatchQueue.main.async {
            self.audioLevel = Float(smoothedLevel)
        }
    }
}
