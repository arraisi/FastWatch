import SwiftUI
import SwiftData

struct FastDetailView: View {
    let fast: CompletedFast

    var body: some View {
        List {
            Section("Protocol") {
                Text(fast.protocolType.displayName)
            }

            Section("Times") {
                LabeledContent("Started") {
                    Text(fast.startTime, style: .time)
                }
                LabeledContent("Ended") {
                    Text(fast.endTime, style: .time)
                }
            }

            Section("Duration") {
                LabeledContent("Target") {
                    Text(fast.targetDuration.formattedHoursMinutes)
                        .monospacedDigit()
                }
                LabeledContent("Actual") {
                    Text(fast.actualDuration.formattedHoursMinutes)
                        .monospacedDigit()
                }
            }

            Section {
                HStack {
                    Spacer()
                    Image(systemName: fast.completedGoal ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.title3)
                    Text(fast.completedGoal ? "Completed" : "Ended Early")
                        .font(.headline)
                    Spacer()
                }
                .foregroundStyle(fast.completedGoal ? .green : .orange)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Detail")
    }
}

#Preview("Completed Fast") {
    let now = Date()
    let fast = CompletedFast(
        startTime: now.addingTimeInterval(-17 * 3600),
        endTime: now.addingTimeInterval(-1 * 3600),
        targetDuration: 16 * 3600,
        protocolType: .sixteen8,
        completedGoal: true
    )
    return NavigationStack {
        FastDetailView(fast: fast)
    }
    .modelContainer(for: CompletedFast.self, inMemory: true)
}

#Preview("Ended Early") {
    let now = Date()
    let fast = CompletedFast(
        startTime: now.addingTimeInterval(-10 * 3600),
        endTime: now.addingTimeInterval(-2 * 3600),
        targetDuration: 16 * 3600,
        protocolType: .sixteen8,
        completedGoal: false
    )
    return NavigationStack {
        FastDetailView(fast: fast)
    }
    .modelContainer(for: CompletedFast.self, inMemory: true)
}
