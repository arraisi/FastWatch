import SwiftUI
import WidgetKit

struct FastWatchWidgetEntryView: View {
    let entry: FastWatchEntry

    var body: some View {
        ZStack {
            if entry.isActive {
                activeView
            } else {
                idleView
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    private var activeView: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(ringColor.opacity(0.3), lineWidth: 4)

            // Progress arc
            Circle()
                .trim(from: 0, to: min(entry.progress, 1.0))
                .stroke(ringColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            if entry.isGoalReached {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.yellow)
            } else {
                Text(entry.remainingText)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
            }
        }
        .padding(2)
    }

    private var idleView: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)

            Image(systemName: "play.fill")
                .font(.system(size: 12))
                .foregroundStyle(.gray)
        }
        .padding(2)
    }

    private var ringColor: Color {
        if entry.isGoalReached { return .yellow }
        if entry.progress >= 0.75 { return .blue }
        if entry.progress >= 0.50 { return .teal }
        return .green
    }
}

struct FastWatchWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FastWatchWidgetEntryView(entry: FastWatchEntry(
                date: Date(), progress: 0.65, remainingText: "6h",
                isActive: true, isGoalReached: false
            ))
            .previewDisplayName("Active")

            FastWatchWidgetEntryView(entry: FastWatchEntry(
                date: Date(), progress: 1.0, remainingText: "0m",
                isActive: true, isGoalReached: true
            ))
            .previewDisplayName("Goal Reached")

            FastWatchWidgetEntryView(entry: FastWatchEntry(
                date: Date(), progress: 0, remainingText: "",
                isActive: false, isGoalReached: false
            ))
            .previewDisplayName("Idle")
        }
        .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
