import Foundation
import SwiftUI
import SwiftData
import WidgetKit
import WatchKit  // T017: For background refresh scheduling

@Observable
class FastingManager {
    enum FastState: Equatable {
        case idle
        case fasting(startTime: Date, protocolType: FastingProtocol)
        case eating(startTime: Date, until: Date, protocolType: FastingProtocol)
    }

    private(set) var state: FastState = .idle
    private(set) var activeFast: FastSession?
    var modelContext: ModelContext?

    private let notificationManager = NotificationManager()
    let healthKitManager = HealthKitManager()
    private let defaults: UserDefaults
    private static let activeFastKey = "activeFast"
    private static let eatingSessionKey = "eatingSession"

    init() {
        defaults = UserDefaults(suiteName: "group.com.fastwatch.shared") ?? .standard
        restoreActiveFast()
        if case .idle = state {
            restoreEatingState()
        }
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
        clearPersistedEatingState()
        notificationManager.cancelEatingNotifications()

        let proto = protocolType ?? preferences.defaultProtocol
        let now = Date()
        let duration: TimeInterval
        if proto == .custom {
            duration = preferences.customFastingHours * 3600
        } else {
            duration = proto.fastingDuration
        }

        guard duration >= 3600 else { return } // Minimum 1 hour

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

        notificationManager.cancelFastingNotifications()
        notificationManager.removeDeliveredFastingNotifications()
        activeFast = nil
        clearPersistedFast()

        let eatingDuration = proto.eatingDuration ?? (proto.fastingDuration > 0 ? 6 * 3600 : 0)
        if eatingDuration > 0 {
            let now = Date()
            let eatingEnd = now.addingTimeInterval(eatingDuration)
            state = .eating(startTime: now, until: eatingEnd, protocolType: proto)
            persistEatingState(startTime: now, endTime: eatingEnd, protocolType: proto)

            if preferences.notifyEatingWindowEnding {
                let reminderMinutes = preferences.eatingWindowReminderMinutes
                let reminderTime = eatingEnd.addingTimeInterval(-Double(reminderMinutes * 60))
                notificationManager.scheduleEatingWindowReminder(at: reminderTime, minutesLeft: reminderMinutes)
            }

            // T016, T018: Schedule background refresh at eating end for widget sync
            scheduleBackgroundRefreshAtEatingEnd(eatingEnd, protocolType: proto)
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
        case .eating(_, let until, let protocolType):
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

        // Cancel any leftover eating notifications from previous session
        notificationManager.cancelEatingNotifications()
        notificationManager.removeDeliveredEatingNotifications()

        activeFast = session
        state = .fasting(startTime: session.startTime, protocolType: session.protocolType)

        // Re-schedule notifications for remaining milestones
        rescheduleNotificationsForRestoredFast(session)
    }

    private func rescheduleNotificationsForRestoredFast(_ session: FastSession) {
        let goalDate = session.startTime.addingTimeInterval(session.targetDuration)

        // Re-schedule goal notification if not yet reached
        if goalDate > Date() {
            notificationManager.scheduleGoalNotification(
                at: goalDate,
                protocolName: session.protocolType.displayName
            )
        }

        // Re-schedule remaining milestones
        if preferences.notifyOnMilestones {
            notificationManager.scheduleMilestoneNotifications(
                startTime: session.startTime,
                duration: session.targetDuration
            )
        }

        // Re-schedule overtime reminder
        if preferences.overtimeReminder {
            notificationManager.scheduleOvertimeReminder(
                startTime: session.startTime,
                targetDuration: session.targetDuration
            )
        }
    }

    // MARK: - Background Refresh (T016, T018)

    /// Schedules a background refresh at eating end time to ensure widget sync.
    /// This is a backup mechanism - the widget timeline handles most cases.
    private func scheduleBackgroundRefreshAtEatingEnd(_ eatingEnd: Date, protocolType: FastingProtocol) {
        WKApplication.shared().scheduleBackgroundRefresh(
            withPreferredDate: eatingEnd,
            userInfo: ["action": "eatingEnded", "protocolType": protocolType.rawValue] as NSDictionary
        ) { error in
            if let error = error {
                print("[FastingManager] Background refresh scheduling failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Eating State Persistence

    private func persistEatingState(startTime: Date, endTime: Date, protocolType: FastingProtocol) {
        let session = EatingSession(startTime: startTime, endTime: endTime, protocolType: protocolType)
        guard let data = try? JSONEncoder().encode(session) else { return }
        defaults.set(data, forKey: Self.eatingSessionKey)
    }

    private func clearPersistedEatingState() {
        defaults.removeObject(forKey: Self.eatingSessionKey)
    }

    private func restoreEatingState() {
        guard let data = defaults.data(forKey: Self.eatingSessionKey),
              let session = try? JSONDecoder().decode(EatingSession.self, from: data),
              !session.isExpired
        else {
            clearPersistedEatingState()
            return
        }

        // Cancel any leftover fasting notifications from previous session
        notificationManager.cancelFastingNotifications()
        notificationManager.removeDeliveredFastingNotifications()

        state = .eating(startTime: session.startTime, until: session.endTime, protocolType: session.protocolType)

        // Re-schedule eating window reminder if needed
        if preferences.notifyEatingWindowEnding {
            let reminderMinutes = preferences.eatingWindowReminderMinutes
            let reminderTime = session.endTime.addingTimeInterval(-Double(reminderMinutes * 60))
            if reminderTime > Date() {
                notificationManager.scheduleEatingWindowReminder(at: reminderTime, minutesLeft: reminderMinutes)
            }
        }
    }

    // MARK: - Computed Helpers

    var isActive: Bool {
        if case .idle = state { return false }
        return true
    }

    var currentProgress: Double {
        switch state {
        case .eating(let start, let until, _):
            let total = until.timeIntervalSince(start)
            guard total > 0 else { return 0 }
            let elapsed = Date().timeIntervalSince(start)
            return min(elapsed / total, 1.0)
        default:
            return activeFast?.progress ?? 0
        }
    }

    var elapsedTime: TimeInterval {
        switch state {
        case .eating(let start, _, _):
            return Date().timeIntervalSince(start)
        default:
            return activeFast?.elapsed ?? 0
        }
    }

    var remainingTime: TimeInterval {
        switch state {
        case .eating(_, let until, _):
            return max(0, until.timeIntervalSince(Date()))
        default:
            return activeFast?.remaining ?? 0
        }
    }

    var ringColor: Color {
        if case .eating = state { return .orange }
        let p = currentProgress
        if p >= 1.0 { return .yellow }
        if p >= 0.75 { return .blue }
        if p >= 0.50 { return Color.teal }
        return .green
    }

    var currentProtocolLabel: String {
        switch state {
        case .fasting(_, let p), .eating(_, _, let p):
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

    func clearHistory() {
        guard let context = modelContext else { return }
        do {
            try context.delete(model: CompletedFast.self)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }

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
