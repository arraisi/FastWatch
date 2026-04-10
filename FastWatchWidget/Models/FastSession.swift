import Foundation

struct FastSession: Identifiable, Codable {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var targetDuration: TimeInterval
    var protocolType: FastingProtocol
    var isActive: Bool

    var actualDuration: TimeInterval? {
        guard let endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var completedGoal: Bool {
        guard let actual = actualDuration else { return false }
        return actual >= targetDuration
    }

    var elapsed: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var remaining: TimeInterval {
        max(0, targetDuration - elapsed)
    }

    var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return elapsed / targetDuration
    }

    var targetEndTime: Date {
        startTime.addingTimeInterval(targetDuration)
    }
}
