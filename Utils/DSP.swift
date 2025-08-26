import Foundation
import Accelerate

struct DSPConfig {
    static let sampleRate: Double = 44100.0
    static let frameLength: Int = 4096
    static let hopLength: Int = 2048
    static let minFrequency: Double = 50.0
    static let maxFrequency: Double = 1100.0
}

enum PitchUtil {
    static func frequencyToMIDINote(_ f: Double) -> Int {
        guard f > 0 else { return 0 }
        return Int(round(69 + 12 * log2(f / 440.0)))
    }
    static func midiToName(_ midi: Int) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let i = (midi % 12 + 12) % 12
        return names[i]
    }
}
