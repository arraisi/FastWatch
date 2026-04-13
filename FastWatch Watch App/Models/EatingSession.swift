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
}
