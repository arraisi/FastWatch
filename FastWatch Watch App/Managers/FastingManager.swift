import Foundation
import SwiftUI
import SwiftData
import WidgetKit

@Observable
class FastingManager {
    enum FastState: Equatable {
        case idle
        case fasting(startTime: Date, protocolType: FastingProtocol)
        case eating(until: Date, protocolType: FastingProtocol)
    }

    private(set) var state: FastState = .idle
    private(set) var activeFast: FastSession?
    var modelContext: ModelContext?

    private let notificationManager = NotificationManager()
    let healthKitManager = HealthKitManager()
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

    func startFast(protocolType: FastingProtocol? = nil) {
        let proto = protocolType ?? preferences.defaultProtocol
        let now = Date()
        let duration: TimeInterval
        if proto == .custom {
            duration = preferences.customFastingHours * 3600
        } else {
            duration = proto.fastingDuration
        }

        let session = FastSession(
            id: UUID(),
            startTime: now,
            targetDuration: duration,
            protocolType: proto,
            isActive: true
        )

        activeFast = session
        state = .fasting(startTime: now, protocolType: proto)
        persistActiveFast()

        notificationManager.scheduleGoalNotification(
            at: now.addingTimeInterval(duration),
            protocolName: proto.displayName
        )

        if preferences.notifyOnMilestones {
            notificationManager.scheduleMilestoneNotifications(
                startTime: now,
                duration: duration
            )
        }

        if preferences.overtimeReminder {
            notificationManager.scheduleOvertimeReminder(
                startTime: now,
                targetDuration: duration
            )
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func endFast() {
        guard let _ = activeFast else { return }
        completeFast()
    }

    private func completeFast() {
        guard var session = activeFast else { return }
        let proto = session.protocolType
        session.endTime = Date()
        session.isActive = false

        if let context = modelContext {
            let completed = CompletedFast(from: session)
            context.insert(completed)
        }

        if preferences.healthKitEnabled {
            healthKitManager.saveFast(
                startTime: session.startTime,
                endTime: session.endTime ?? Date()
            ) { _ in }
        }

        notificationManager.cancelPendingNotifications()
        activeFast = nil
        clearPersistedFast()

        let eatingDuration = proto.eatingDuration ?? (proto.fastingDuration > 0 ? 6 * 3600 : 0)
        if eatingDuration > 0 {
            let eatingEnd = Date().addingTimeInterval(eatingDuration)
            state = .eating(until: eatingEnd, protocolType: proto)

            if preferences.notifyEatingWindowEnding {
                let reminderMinutes = preferences.eatingWindowReminderMinutes
                let reminderTime = eatingEnd.addingTimeInterval(-Double(reminderMinutes * 60))
                notificationManager.scheduleEatingWindowReminder(at: reminderTime, minutesLeft: reminderMinutes)
            }
        } else {
            state = .idle
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    func updateState() {
        switch state {
        case .fasting:
            guard let fast = activeFast else { return }
            if fast.elapsed >= fast.targetDuration {
                if preferences.hapticsEnabled {
                    notificationManager.playSuccessHaptic()
                }
                completeFast()
            }
        case .eating(let until, let protocolType):
            if Date() >= until {
                startFast(protocolType: protocolType)
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
        state = .fasting(startTime: session.startTime, protocolType: session.protocolType)
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
        case .fasting(_, let p), .eating(_, let p):
            return p.displayName
        default:
            return preferences.defaultProtocol.displayName
        }
    }

    var currentZone: FastingZone {
        guard let fast = activeFast else { return .fed }
        return FastingZone.zone(for: fast.elapsed / 3600)
    }

    // MARK: - History Stats

    func fetchHistory() -> [CompletedFast] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CompletedFast>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func weeklyStats() -> (count: Int, totalHours: Double) {
        guard let context = modelContext else { return (0, 0) }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        var descriptor = FetchDescriptor<CompletedFast>(
            predicate: #Predicate { $0.startTime >= weekAgo }
        )
        descriptor.sortBy = [SortDescriptor(\.startTime)]
        let fasts = (try? context.fetch(descriptor)) ?? []
        let totalSeconds = fasts.reduce(0.0) { $0 + $1.actualDuration }
        return (fasts.count, totalSeconds / 3600)
    }

    func currentStreak() -> Int {
        let history = fetchHistory()
        guard !history.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        while true {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
            let hasfast = history.contains { fast in
                fast.startTime >= checkDate && fast.startTime < dayEnd && fast.completedGoal
            }
            if hasfast {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else if streak == 0 {
                // today might not have a fast yet, check yesterday
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
                let prevEnd = calendar.date(byAdding: .day, value: 1, to: checkDate)!
                let hasPrevFast = history.contains { fast in
                    fast.startTime >= checkDate && fast.startTime < prevEnd && fast.completedGoal
                }
                if hasPrevFast {
                    streak += 1
                    guard let prevPrev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                    checkDate = prevPrev
                } else {
                    break
                }
            } else {
                break
            }
        }
        return streak
    }
}
