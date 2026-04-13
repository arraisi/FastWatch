import Foundation
import SwiftData

@Model
class CompletedFast {
    var id: UUID
    var startTime: Date
    var endTime: Date
    var targetDuration: TimeInterval
    var protocolRawValue: String
    var completedGoal: Bool

    init(from session: FastSession) {
        self.id = session.id
        self.startTime = session.startTime
        self.endTime = session.endTime ?? Date()
        self.targetDuration = session.targetDuration
        self.protocolRawValue = session.protocolType.rawValue
        self.completedGoal = session.completedGoal
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        targetDuration: TimeInterval,
        protocolType: FastingProtocol,
        completedGoal: Bool
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetDuration = targetDuration
        self.protocolRawValue = protocolType.rawValue
        self.completedGoal = completedGoal
    }

    var protocolType: FastingProtocol {
        FastingProtocol(rawValue: protocolRawValue) ?? .sixteen8
    }

    var actualDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}
