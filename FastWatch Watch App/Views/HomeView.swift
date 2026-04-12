import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(FastingManager.self) private var manager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            TimelineView(.animation(minimumInterval: 1.0)) { context in
                let _ = manager.updateState()
                content
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: HistoryView()) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
        }
        .onAppear {
            manager.modelContext = modelContext
        }
    }

    private var content: some View {
        VStack(spacing: 4) {
            NavigationLink(destination: ActiveFastDetailView()) {
                ZStack {
                    ProgressRingView(
                        progress: manager.currentProgress,
                        color: manager.ringColor,
                        lineWidth: 10
                    )

                    VStack(spacing: 2) {
                        Text(manager.elapsedTime.formattedHHMM)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()

                        if manager.isActive {
                            Text("-\(manager.remainingTime.formattedHoursMinutes)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(manager.currentZone.rawValue)
                                .font(.system(size: 9))
                                .foregroundStyle(manager.currentZone.color)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(!manager.isActive)
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .padding(.horizontal, 35)

            Text(manager.currentProtocolLabel)
                .font(.caption2)
                .foregroundStyle(.secondary)

            actionButton
        }
        .padding(.horizontal, 4)
        .padding(.bottom,25)
    }

    @ViewBuilder
    private var actionButton: some View {
        switch manager.state {
        case .idle:
            Button(action: { manager.startFast() }) {
                Label("Start Fast", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.green)

        case .fasting:
            Button(action: { manager.endFast() }) {
                Label("End Fast", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)

        case .eating(let until, _):
            VStack(spacing: 2) {
                Text("Eating until \(until, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button(action: { manager.startFast() }) {
                    Label("Start Fast", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .tint(.green)
            }
        }
    }
}

#Preview("Idle") {
    HomeView()
        .environment(FastingManager())
        .modelContainer(for: CompletedFast.self, inMemory: true)
}

#Preview("Fasting") {
    let manager = FastingManager()
    manager.startFast(protocolType: .sixteen8)
    return HomeView()
        .environment(manager)
        .modelContainer(for: CompletedFast.self, inMemory: true)
}
