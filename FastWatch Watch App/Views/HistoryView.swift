import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(FastingManager.self) private var manager
    @Query(sort: \CompletedFast.startTime, order: .reverse) private var fasts: [CompletedFast]

    var body: some View {
        List {
            if !fasts.isEmpty {
                weeklySummary
            }

            if fasts.isEmpty {
                ContentUnavailableView(
                    "No Fasts Yet",
                    systemImage: "clock",
                    description: Text("Complete a fast to see it here.")
                )
            } else {
                ForEach(fasts) { fast in
                    NavigationLink(destination: FastDetailView(fast: fast)) {
                        fastRow(fast)
                    }
                }
            }
        }
        .navigationTitle("History")
    }

    private var weeklySummary: some View {
        let stats = manager.weeklyStats()
        let streak = manager.currentStreak()

        return Section("This Week") {
            HStack {
                statBox(value: "\(stats.count)", label: "Fasts")
                Divider()
                statBox(value: String(format: "%.0f", stats.totalHours), label: "Hours")
                Divider()
                statBox(value: "\(streak)", label: "Streak")
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func fastRow(_ fast: CompletedFast) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(fast.startTime, style: .date)
                    .font(.caption)
                Text(fast.protocolType.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(fast.actualDuration.formattedHoursMinutes)
                    .font(.caption)
                    .monospacedDigit()
                Image(systemName: fast.completedGoal ? "checkmark.circle.fill" : "xmark.circle")
                    .font(.caption2)
                    .foregroundStyle(fast.completedGoal ? .green : .orange)
            }
        }
    }
}

#Preview("History") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CompletedFast.self, configurations: config)

    let now = Date()
    let sampleFasts = [
        CompletedFast(
            startTime: now.addingTimeInterval(-17 * 3600),
            endTime: now.addingTimeInterval(-1 * 3600),
            targetDuration: 16 * 3600,
            protocolType: .sixteen8,
            completedGoal: true
        ),
        CompletedFast(
            startTime: now.addingTimeInterval(-42 * 3600),
            endTime: now.addingTimeInterval(-24 * 3600),
            targetDuration: 18 * 3600,
            protocolType: .eighteen6,
            completedGoal: true
        ),
        CompletedFast(
            startTime: now.addingTimeInterval(-72 * 3600),
            endTime: now.addingTimeInterval(-62 * 3600),
            targetDuration: 16 * 3600,
            protocolType: .sixteen8,
            completedGoal: false
        ),
    ]
    for fast in sampleFasts {
        container.mainContext.insert(fast)
    }

    return NavigationStack {
        HistoryView()
    }
    .environment(FastingManager())
    .modelContainer(container)
}

#Preview("History Empty") {
    NavigationStack {
        HistoryView()
    }
    .environment(FastingManager())
    .modelContainer(for: CompletedFast.self, inMemory: true)
}
