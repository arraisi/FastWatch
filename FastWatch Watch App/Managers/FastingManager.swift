import Foundation
import SwiftUI

@Observable
class FastingManager {
    enum FastState: Equatable {
        case idle
        case fasting(startTime: Date, protocolType: FastingProtocol)
        case goalReached(startTime: Date, protocolType: FastingProtocol)
        case eating(until: Date)
    }

    private(set) var state: FastState = .idle
    private(set) var activeFast: FastSession?
    private(set) var history: [FastSession] = []

    private let notificationManager = NotificationManager()
    private let defaults: UserDefaults
    private static let activeFastKey = "activeFast"

    init() {
        defaults = UserDefaults(suiteName: "group.com.fastwatch.shared") ?? .standard
        restoreActiveFast()
    }

    var preferences: UserPreferences {
        get {
            guard let data = UserDefaults.standard.data(forKey: "userPreferences"),
                  let prefs = try? JSONDecoder().decode(UserPreferences.self, from: data)
            else { return UserPreferences() }
            return prefs
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "userPreferences")
            }
        }
    }

    // MARK: - Actions

    func startFast(protocolType: FastingProtocol = .sixteen8) {
        let now = Date()
        let duration = protocolType.fastingDuration

        let session = FastSession(
            id: UUID(),
            startTime: now,
            targetDuration: duration,
            protocolType: protocolType,
            isActive: true
        )

        activeFast = session
        state = .fasting(startTime: now, protocolType: protocolType)
        persistActiveFast()

        notificationManager.scheduleGoalNotification(
            at: now.addingTimeInterval(duration),
            protocolName: protocolType.displayName
        )

        if preferences.notifyOnMilestones {
            notificationManager.scheduleMilestoneNotifications(
                startTime: now,
                duration: duration
            )
        }
    }

    func endFast() {
        guard var session = activeFast else { return }
        session.endTime = Date()
        session.isActive = false

        history.insert(session, at: 0)

        notificationManager.cancelPendingNotifications()

        if case .goalReached(_, let protocolType) = state,
           let eatingDuration = protocolType.eatingDuration {
            let eatingEnd = Date().addingTimeInterval(eatingDuration)
            state = .eating(until: eatingEnd)
            activeFast = nil
            clearPersistedFast()

            if preferences.notifyEatingWindowEnding {
                let reminderMinutes = preferences.eatingWindowReminderMinutes
                let reminderTime = eatingEnd.addingTimeInterval(-Double(reminderMinutes * 60))
                notificationManager.scheduleEatingWindowReminder(at: reminderTime, minutesLeft: reminderMinutes)
            }
        } else {
            state = .idle
            activeFast = nil
            clearPersistedFast()
        }
    }

    func updateState() {
        guard let fast = activeFast else { return }

        switch state {
        case .fasting(let startTime, let protocolType):
            if fast.elapsed >= fast.targetDuration {
                state = .goalReached(startTime: startTime, protocolType: protocolType)
                if preferences.hapticsEnabled {
                    notificationManager.playSuccessHaptic()
                }
            }
        case .eating(let until):
            if Date() >= until {
                state = .idle
            }
        default:
            break
        }
    }

    // MARK: - Persistence

    private func persistActiveFast() {
        guard let fast = activeFast,
              let data = try? JSONEncoder().encode(fast)
        else { return }
        defaults.set(data, forKey: Self.activeFastKey)
    }

    private func clearPersistedFast() {
        defaults.removeObject(forKey: Self.activeFastKey)
    }

    private func restoreActiveFast() {
        guard let data = defaults.data(forKey: Self.activeFastKey),
              let session = try? JSONDecoder().decode(FastSession.self, from: data),
              session.isActive
        else { return }

        activeFast = session

        if session.elapsed >= session.targetDuration {
            state = .goalReached(startTime: session.startTime, protocolType: session.protocolType)
        } else {
            state = .fasting(startTime: session.startTime, protocolType: session.protocolType)
        }
    }

    // MARK: - Computed Helpers

    var isActive: Bool {
        if case .idle = state { return false }
        return true
    }

    var currentProgress: Double {
        activeFast?.progress ?? 0
    }

    var elapsedTime: TimeInterval {
        activeFast?.elapsed ?? 0
    }

    var remainingTime: TimeInterval {
        activeFast?.remaining ?? 0
    }

    var ringColor: Color {
        let p = currentProgress
        if p >= 1.0 { return .yellow }
        if p >= 0.75 { return .blue }
        if p >= 0.50 { return Color.teal }
        return .green
    }

    var currentProtocolLabel: String {
        switch state {
        case .fasting(_, let p), .goalReached(_, let p):
            return p.displayName
        default:
            return preferences.defaultProtocol.displayName
        }
    }
}
