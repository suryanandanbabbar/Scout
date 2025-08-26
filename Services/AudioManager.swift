import Foundation
import AVFoundation

final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    private let engine = AVAudioEngine()
    private let session = AVAudioSession.sharedInstance()
    
    private var bufferHandler: ((AVAudioPCMBuffer, AVAudioTime) -> Void)?
    
    func startListening(_ onBuffer: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) throws {
        self.bufferHandler = onBuffer
        
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        
        let input = engine.inputNode
        let format = input.inputFormat(forBus: 0)
        let desired = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 1, interleaved: false)!
        let converter = AVAudioConverter(from: format, to: desired)!
        
        input.installTap(onBus: 0, bufferSize: 4096, format: format) { [weak self] buffer, when in
            guard let self = self else { return }
            let outBuffer = AVAudioPCMBuffer(pcmFormat: desired, frameCapacity: AVAudioFrameCount(4096))!
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            converter.convert(to: outBuffer, error: &error, withInputFrom: inputBlock)
            if error == nil {
                onBuffer(outBuffer, when)
            }
        }
        
        try engine.start()
    }
    
    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        try? session.setActive(false)
    }
}
