import Foundation

struct DetectedNote: Identifiable, Equatable {
    let id = UUID()
    let name: String   // C, C#, D, etc.
    let frequency: Double
    let midi: Int
    let confidence: Double
}
