import Foundation

struct DetectedNote: Identifiable, Equatable {
    let id = UUID()
    let name: String   // e.g., C, C#, D, ...
    let frequency: Double
    let midi: Int
    let confidence: Double
}
