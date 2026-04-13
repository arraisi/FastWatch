import Foundation

struct EatingSession: Codable {
    let startTime: Date
    let endTime: Date
    let protocolType: FastingProtocol

    var remainingTime: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var isExpired: Bool {
        Date() >= endTime
    }

    var progress: Double {
        let total = endTime.timeIntervalSince(startTime)
        guard total > 0 else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(elapsed / total, 1.0)
    }
}
