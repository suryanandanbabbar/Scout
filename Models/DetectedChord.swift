import Foundation

struct DetectedChord: Identifiable, Equatable {
    let id = UUID()
    let root: String    // e.g., C, D#, F
    let quality: String // "maj" or "min"
    let confidence: Double
    
    var displayName: String { "\(root)\(quality == "maj" ? "" : "m")" }
}

