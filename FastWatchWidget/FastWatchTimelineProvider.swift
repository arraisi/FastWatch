import WidgetKit
import Foundation

struct FastWatchEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let remainingText: String
    let elapsedText: String
    let isActive: Bool
    let isGoalReached: Bool
    let zoneName: String
    let protocolName: String
    // Eating state fields
    let isEating: Bool
    let eatingRemainingText: String
    let eatingProgress: Double
}

struct FastWatchTimelineProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.fastwatch.shared") ?? .standard

    func placeholder(in context: Context) -> FastWatchEntry {
        FastWatchEntry(
            date: Date(),
            progress: 0.65,
            remainingText: "6h",
            elapsedText: "10h",
            isActive: true,
            isGoalReached: false,
            zoneName: "Fat Burning",
            protocolName: "16:8",
            isEating: false,
            eatingRemainingText: "",
            eatingProgress: 0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FastWatchEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
        // Check for active fast first
        if let session = loadActiveFast() {
            buildFastingTimeline(session: session, completion: completion)
            return
        }

        // Check for eating session (non-expired)
        if let eating = loadEatingSession() {
            buildEatingTimeline(session: eating, completion: completion)
            return
        }

        // T006, T007: Check for recently-expired eating session (transition to fasting)
        if let expiredEating = loadExpiredEatingSession() {
            buildTransitionFastingTimeline(
                eatingEndTime: expiredEating.endTime,
                protocolType: expiredEating.protocolType,
                completion: completion
            )
            return
        }

        // Idle state (legitimate "No FastTime" - no session data)
        let entry = FastWatchEntry(
            date: Date(),
            progress: 0,
            remainingText: "",
            elapsedText: "",
            isActive: false,
            isGoalReached: false,
            zoneName: "",
            protocolName: "",
            isEating: false,
            eatingRemainingText: "",
            eatingProgress: 0
        )
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }

    private func buildFastingTimeline(session: FastSession, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {

        var entries: [FastWatchEntry] = []
        let now = Date()

        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))
            let elapsed = entryDate.timeIntervalSince(session.startTime)
            let progress = session.targetDuration > 0 ? elapsed / session.targetDuration : 0
            let remaining = max(0, session.targetDuration - elapsed)
            let goalReached = elapsed >= session.targetDuration
            let zone = FastingZone.zone(for: elapsed / 3600)

            entries.append(FastWatchEntry(
                date: entryDate,
                progress: progress,
                remainingText: remaining.shortFormatted,
                elapsedText: elapsed.shortFormatted,
                isActive: true,
                isGoalReached: goalReached,
                zoneName: zone.rawValue,
                protocolName: session.protocolType.displayName,
                isEating: false,
                eatingRemainingText: "",
                eatingProgress: 0
            ))
        }

        let nextUpdate = now.addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    // MARK: - Eating Timeline with Transition (T011-T015)

    private func buildEatingTimeline(session: EatingSession, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
        var entries: [FastWatchEntry] = []
        let now = Date()
        let targetFastingDuration = session.protocolType.fastingDuration

        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))

            // T012: Conditional logic - if before eating end, show eating; else show fasting
            if entryDate < session.endTime {
                // Still in eating window
                let remaining = session.endTime.timeIntervalSince(entryDate)
                let total = session.endTime.timeIntervalSince(session.startTime)
                let elapsed = entryDate.timeIntervalSince(session.startTime)
                let progress = total > 0 ? min(elapsed / total, 1.0) : 0

                entries.append(FastWatchEntry(
                    date: entryDate,
                    progress: 0,
                    remainingText: "",
                    elapsedText: "",
                    isActive: false,
                    isGoalReached: false,
                    zoneName: "",
                    protocolName: session.protocolType.displayName,
                    isEating: true,
                    eatingRemainingText: remaining.shortFormatted,
                    eatingProgress: progress
                ))
            } else {
                // T013, T014: Transitioned to fasting - calculate from eating end time
                let fastingElapsed = entryDate.timeIntervalSince(session.endTime)
                let progress = targetFastingDuration > 0 ? fastingElapsed / targetFastingDuration : 0
                let remaining = max(0, targetFastingDuration - fastingElapsed)
                let goalReached = fastingElapsed >= targetFastingDuration
                let zone = FastingZone.zone(for: fastingElapsed / 3600)

                entries.append(FastWatchEntry(
                    date: entryDate,
                    progress: progress,
                    remainingText: remaining.shortFormatted,
                    elapsedText: fastingElapsed.shortFormatted,
                    isActive: true,
                    isGoalReached: goalReached,
                    zoneName: zone.rawValue,
                    protocolName: session.protocolType.displayName,
                    isEating: false,
                    eatingRemainingText: "",
                    eatingProgress: 0
                ))
            }
        }

        // T015: Refresh at eating end time (or 15 min from now if already past)
        let nextUpdate = max(session.endTime, now.addingTimeInterval(15 * 60))
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> FastWatchEntry {
        // Check for active fast
        if let session = loadActiveFast() {
            let elapsed = Date().timeIntervalSince(session.startTime)
            let progress = session.targetDuration > 0 ? elapsed / session.targetDuration : 0
            let remaining = max(0, session.targetDuration - elapsed)
            let zone = FastingZone.zone(for: elapsed / 3600)

            return FastWatchEntry(
                date: Date(),
                progress: progress,
                remainingText: remaining.shortFormatted,
                elapsedText: elapsed.shortFormatted,
                isActive: true,
                isGoalReached: elapsed >= session.targetDuration,
                zoneName: zone.rawValue,
                protocolName: session.protocolType.displayName,
                isEating: false,
                eatingRemainingText: "",
                eatingProgress: 0
            )
        }

        // Check for eating session (non-expired)
        if let eating = loadEatingSession() {
            let remaining = eating.remainingTime
            return FastWatchEntry(
                date: Date(),
                progress: 0,
                remainingText: "",
                elapsedText: "",
                isActive: false,
                isGoalReached: false,
                zoneName: "",
                protocolName: eating.protocolType.displayName,
                isEating: true,
                eatingRemainingText: remaining.shortFormatted,
                eatingProgress: eating.progress
            )
        }

        // T022: Check for expired eating session (transition to fasting)
        if let expiredEating = loadExpiredEatingSession() {
            let fastingElapsed = Date().timeIntervalSince(expiredEating.endTime)
            let targetDuration = expiredEating.protocolType.fastingDuration
            let progress = targetDuration > 0 ? fastingElapsed / targetDuration : 0
            let remaining = max(0, targetDuration - fastingElapsed)
            let zone = FastingZone.zone(for: fastingElapsed / 3600)

            return FastWatchEntry(
                date: Date(),
                progress: progress,
                remainingText: remaining.shortFormatted,
                elapsedText: fastingElapsed.shortFormatted,
                isActive: true,
                isGoalReached: fastingElapsed >= targetDuration,
                zoneName: zone.rawValue,
                protocolName: expiredEating.protocolType.displayName,
                isEating: false,
                eatingRemainingText: "",
                eatingProgress: 0
            )
        }

        // Idle state (legitimate "No FastTime")
        return FastWatchEntry(
            date: Date(),
            progress: 0,
            remainingText: "",
            elapsedText: "",
            isActive: false,
            isGoalReached: false,
            zoneName: "",
            protocolName: "",
            isEating: false,
            eatingRemainingText: "",
            eatingProgress: 0
        )
    }

    private func loadActiveFast() -> FastSession? {
        guard let data = defaults.data(forKey: "activeFast"),
              let session = try? JSONDecoder().decode(FastSession.self, from: data),
              session.isActive
        else { return nil }
        return session
    }

    private func loadEatingSession() -> EatingSession? {
        guard let data = defaults.data(forKey: "eatingSession"),
              let session = try? JSONDecoder().decode(EatingSession.self, from: data),
              !session.isExpired
        else { return nil }
        return session
    }

    // MARK: - Transition Detection (T004)

    /// Loads an expired eating session for transition detection.
    /// Returns session if expired within last 24 hours (not stale data).
    private func loadExpiredEatingSession() -> EatingSession? {
        guard let data = defaults.data(forKey: "eatingSession"),
              let session = try? JSONDecoder().decode(EatingSession.self, from: data),
              session.isExpired,
              Date().timeIntervalSince(session.endTime) < 24 * 3600
        else { return nil }
        return session
    }

    // MARK: - Transition Timeline Builder (T005, T008-T010)

    /// Builds a fasting timeline starting from when eating ended.
    /// Used when eating session expired but no active fast exists yet.
    private func buildTransitionFastingTimeline(
        eatingEndTime: Date,
        protocolType: FastingProtocol,
        completion: @escaping (Timeline<FastWatchEntry>) -> Void
    ) {
        var entries: [FastWatchEntry] = []
        let now = Date()
        let targetDuration = protocolType.fastingDuration

        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))
            let elapsed = entryDate.timeIntervalSince(eatingEndTime)
            let progress = targetDuration > 0 ? elapsed / targetDuration : 0
            let remaining = max(0, targetDuration - elapsed)
            let goalReached = elapsed >= targetDuration
            let zone = FastingZone.zone(for: elapsed / 3600)

            entries.append(FastWatchEntry(
                date: entryDate,
                progress: progress,
                remainingText: remaining.shortFormatted,
                elapsedText: elapsed.shortFormatted,
                isActive: true,
                isGoalReached: goalReached,
                zoneName: zone.rawValue,
                protocolName: protocolType.displayName,
                isEating: false,
                eatingRemainingText: "",
                eatingProgress: 0
            ))
        }

        let nextUpdate = now.addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}
