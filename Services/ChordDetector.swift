import Foundation
import Accelerate
import AVFoundation

final class ChordDetector: ObservableObject {
    @Published var currentChord: DetectedChord?
    @Published var currentNote: DetectedNote?
    
    private let smoother = ExponentialSmoother(alpha: 0.25)
    
    // FFT setup
    private var fftSetup: vDSP_DFT_Setup?
    private var window: [Float] = []
    private var inReal: [Float] = []
    private var inImag: [Float] = []
    private var outReal: [Float] = []
    private var outImag: [Float] = []
    private let n: Int = DSPConfig.frameLength
    
    init() {
        fftSetup = vDSP_DFT_zop_CreateSetup(nil, vDSP_Length(n), .FORWARD)
        window = vDSP.window(ofType: Float.self, usingSequence: .hanningDenormalized, count: n, isHalfWindow: false)
        inReal = .init(repeating: 0, count: n)
        inImag = .init(repeating: 0, count: n)
        outReal = .init(repeating: 0, count: n)
        outImag = .init(repeating: 0, count: n)
    }
    
    deinit {
        if let s = fftSetup {
            vDSP_DFT_DestroySetup(s)
        }
    }
    
    func process(buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        if frames < n { return }
        
        // Taking last n samples to form a frame
        let ptr = UnsafeBufferPointer(start: data + frames - n, count: n)
        var frame = Array(ptr)
        
        // Window
        vDSP.multiply(frame, window, result: &frame)
        
        // Real FFT via DFT (complex)
        inReal = frame
        inImag = .init(repeating: 0, count: n)
        vDSP_DFT_Execute(fftSetup!, inReal, inImag, &outReal, &outImag)
        
        // Magnitude spectrum
        var mags = [Float](repeating: 0, count: n/2)
        vDSP.hypot(outReal[0..<(n/2)], outImag[0..<(n/2)], result: &mags)
        
        // Chromagram (12 bins)
        let chroma = chromagram(magnitude: mags, sampleRate: Float(DSPConfig.sampleRate))
        
        // Chord template correlation (major/minor triads)
        let (chord, cConf) = bestChord(from: chroma)
        let smConf = smoother.push(cConf)
        DispatchQueue.main.async {
            self.currentChord = DetectedChord(root: chord.0, quality: chord.1, confidence: smConf)
        }
        
        // Monophonic pitch estimate (YIN simplified on the same frame center)
        if let f0 = yinPitch(frame: frame, sampleRate: Float(DSPConfig.sampleRate)) {
            let freq = Double(f0)
            let midi = PitchUtil.frequencyToMIDINote(freq)
            let name = PitchUtil.midiToName(midi)
            DispatchQueue.main.async {
                self.currentNote = DetectedNote(name: name, frequency: freq, midi: midi, confidence: min(1.0, Double(smConf)))
            }
        }
    }
    
    private func chromagram(magnitude: [Float], sampleRate: Float) -> [Float] {
        let nBins = magnitude.count
        let binHz = sampleRate / Float(DSPConfig.frameLength)
        var chroma = [Float](repeating: 0, count: 12)
        
        for k in 1..<nBins {
            let freq = Float(k) * binHz
            if freq < 50 || freq > 5000 { continue }
            let midi = 69.0 + 12.0 * log2f(freq / 440.0)
            let pc = Int(round(midi)).mod12
            chroma[pc] += magnitude[k]
        }
        // Normalize
        var sum: Float = 0
        vDSP_sve(chroma, 1, &sum, vDSP_Length(12))
        if sum > 0 {
            vDSP.divide(chroma, sum, result: &chroma)
        }
        return chroma
    }
    
    private func bestChord(from chroma: [Float]) -> ((String, String), Double) {
        // 12 major & minor templates
        let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        var bestScore: Float = -1
        var best: (Int, String) = (0, "maj")
        
        for root in 0..<12 {
            // Major: root, +4, +7
            var majTemplate = [Float](repeating: 0, count: 12)
            majTemplate[root] = 1; majTemplate[(root+4)%12] = 0.8; majTemplate[(root+7)%12] = 0.7
            let majScore = dot(chroma, majTemplate)
            
            // Minor: root, +3, +7
            var minTemplate = [Float](repeating: 0, count: 12)
            minTemplate[root] = 1; minTemplate[(root+3)%12] = 0.8; minTemplate[(root+7)%12] = 0.7
            let minScore = dot(chroma, minTemplate)
            
            if majScore > bestScore { bestScore = majScore; best = (root, "maj") }
            if minScore > bestScore { bestScore = minScore; best = (root, "min") }
        }
        let conf = Double(min(1.0, max(0.0, bestScore)))
        return ((noteNames[best.0], best.1), conf)
    }
    
    private func dot(_ a: [Float], _ b: [Float]) -> Float {
        var result: Float = 0
        vDSP_dotpr(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
    }
    
    private func yinPitch(frame: [Float], sampleRate: Float) -> Float? {
        // Basic YIN difference function + cumulative mean normalized difference
        let n = frame.count
        let maxLag = Int(sampleRate / 50)   // 50 Hz
        let minLag = Int(sampleRate / 1100) // 1100 Hz
        if maxLag >= n { return nil }
        
        var diff = [Float](repeating: 0, count: maxLag+1)
        for tau in minLag...maxLag {
            var sum: Float = 0
            for i in 0..<(n - tau) {
                let d = frame[i] - frame[i+tau]
                sum += d*d
            }
            diff[tau] = sum
        }
        // Cumulative mean normalized difference
        var cmnd = [Float](repeating: 0, count: maxLag+1)
        var runningSum: Float = 0
        for tau in minLag...maxLag {
            runningSum += diff[tau]
            cmnd[tau] = diff[tau] * Float(tau) / (runningSum == 0 ? 1 : runningSum)
        }
        // Picking first dip below threshold
        let thresh: Float = 0.1
        var tauEstimate: Int? = nil
        for tau in minLag...maxLag {
            if cmnd[tau] < thresh {
                while tau+1 <= maxLag && cmnd[tau+1] < cmnd[tau] { tauEstimate = tau+1; break }
                tauEstimate = tauEstimate ?? tau
                break
            }
        }
        guard let tau0 = tauEstimate else { return nil }
        // Parabolic interpolation around tau0 for better resolution
        let tau = Float(tau0)
        let y1 = cmnd[max(minLag, tau0-1)], y2 = cmnd[tau0], y3 = cmnd[min(maxLag, tau0+1)]
        let denom = (y1 - 2*y2 + y3)
        let tauRefined = tau + 0.5 * (y1 - y3) / (denom == 0 ? 1 : denom)
        let f0 = sampleRate / tauRefined
        if f0.isFinite && f0 > 50 && f0 < 1100 { return f0 }
        return nil
    }
}

fileprivate extension Int {
    var mod12: Int { let m = self % 12; return m >= 0 ? m : m + 12 }
}





