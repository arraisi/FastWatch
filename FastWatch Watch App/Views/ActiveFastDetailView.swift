import SwiftUI

struct ActiveFastDetailView: View {
    @Environment(FastingManager.self) private var manager

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { _ in
            let _ = manager.updateState()
            detailContent
        }
        .navigationTitle("Active Fast")
    }

    private var detailContent: some View {
        List {
            if let fast = manager.activeFast {
                Section("Progress") {
                    LabeledContent("Elapsed") {
                        Text(fast.elapsed.formattedHoursMinutes)
                            .monospacedDigit()
                    }
                    LabeledContent("Remaining") {
                        Text(fast.remaining.formattedHoursMinutes)
                            .monospacedDigit()
                    }
                    LabeledContent("Progress") {
                        Text("\(Int(fast.progress * 100))%")
                            .monospacedDigit()
                    }
                }

                Section("Times") {
                    LabeledContent("Started") {
                        Text(fast.startTime, style: .time)
                    }
                    LabeledContent("Goal") {
                        Text(fast.targetEndTime, style: .time)
                    }
                }

                Section("Protocol") {
                    Text(fast.protocolType.displayName)
                }

                let zone = FastingZone.zone(for: fast.elapsed / 3600)
                Section("Fasting Zone") {
                    HStack(spacing: 8) {
                        Image(systemName: zone.icon)
                            .foregroundStyle(zone.color)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.rawValue)
                                .font(.headline)
                            Text(zone.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "No Active Fast",
                    systemImage: "timer",
                    description: Text("Start a fast to see details.")
                )
            }
        }
    }
}

#Preview("Active 8h In") {
    let manager = FastingManager()
    manager.startFast(protocolType: .sixteen8)
    return NavigationStack {
        ActiveFastDetailView()
    }
    .environment(manager)
}

#Preview("No Active Fast") {
    NavigationStack {
        ActiveFastDetailView()
    }
    .environment(FastingManager())
}
