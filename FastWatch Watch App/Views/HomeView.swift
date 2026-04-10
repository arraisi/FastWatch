import SwiftUI

struct HomeView: View {
    @Environment(FastingManager.self) private var manager

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0)) { context in
            let _ = manager.updateState()
            content
        }
    }

    private var content: some View {
        VStack(spacing: 4) {
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
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .padding(.horizontal, 30)

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

        case .fasting, .goalReached:
            Button(action: { manager.endFast() }) {
                Label("End Fast", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .tint(.red)

        case .eating(let until):
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(FastingManager())
    }
}
