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

        // Check for eating session
        if let eating = loadEatingSession() {
            buildEatingTimeline(session: eating, completion: completion)
            return
        }

        // Idle state
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

    private func buildEatingTimeline(session: EatingSession, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
        var entries: [FastWatchEntry] = []
        let now = Date()

        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))
            let remaining = max(0, session.endTime.timeIntervalSince(entryDate))
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
        }

        let nextUpdate = now.addingTimeInterval(15 * 60)
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

        // Check for eating session
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

        // Idle state
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
}
