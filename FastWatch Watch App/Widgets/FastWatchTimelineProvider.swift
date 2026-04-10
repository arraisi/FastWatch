import WidgetKit
import Foundation

struct FastWatchEntry: TimelineEntry {
    let date: Date
    let progress: Double
    let remainingText: String
    let isActive: Bool
    let isGoalReached: Bool
}

struct FastWatchTimelineProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.com.fastwatch.shared") ?? .standard

    func placeholder(in context: Context) -> FastWatchEntry {
        FastWatchEntry(
            date: Date(),
            progress: 0.65,
            remainingText: "6h",
            isActive: true,
            isGoalReached: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FastWatchEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastWatchEntry>) -> Void) {
        guard let session = loadActiveFast() else {
            let entry = FastWatchEntry(
                date: Date(),
                progress: 0,
                remainingText: "",
                isActive: false,
                isGoalReached: false
            )
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }

        var entries: [FastWatchEntry] = []
        let now = Date()

        // Generate entries every 15 minutes for the next 2 hours
        for minuteOffset in stride(from: 0, through: 120, by: 15) {
            let entryDate = now.addingTimeInterval(Double(minuteOffset * 60))
            let elapsed = entryDate.timeIntervalSince(session.startTime)
            let progress = session.targetDuration > 0 ? elapsed / session.targetDuration : 0
            let remaining = max(0, session.targetDuration - elapsed)
            let goalReached = elapsed >= session.targetDuration

            entries.append(FastWatchEntry(
                date: entryDate,
                progress: progress,
                remainingText: remaining.shortFormatted,
                isActive: true,
                isGoalReached: goalReached
            ))
        }

        let nextUpdate = now.addingTimeInterval(15 * 60)
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> FastWatchEntry {
        guard let session = loadActiveFast() else {
            return FastWatchEntry(
                date: Date(),
                progress: 0,
                remainingText: "",
                isActive: false,
                isGoalReached: false
            )
        }

        let elapsed = Date().timeIntervalSince(session.startTime)
        let progress = session.targetDuration > 0 ? elapsed / session.targetDuration : 0
        let remaining = max(0, session.targetDuration - elapsed)

        return FastWatchEntry(
            date: Date(),
            progress: progress,
            remainingText: remaining.shortFormatted,
            isActive: true,
            isGoalReached: elapsed >= session.targetDuration
        )
    }

    private func loadActiveFast() -> FastSession? {
        guard let data = defaults.data(forKey: "activeFast"),
              let session = try? JSONDecoder().decode(FastSession.self, from: data),
              session.isActive
        else { return nil }
        return session
    }
}
