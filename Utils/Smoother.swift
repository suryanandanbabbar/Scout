import Foundation

final class ExponentialSmoother {
    private var value: Double = 0
    private let alpha: Double
    private var initialized = false
    
    init(alpha: Double = 0.3) { self.alpha = alpha }
    
    func push(_ x: Double) -> Double {
        if !initialized {
            value = x
            initialized = true
        } else {
            value = alpha * x + (1 - alpha) * value
        }
        return value
    }
}
