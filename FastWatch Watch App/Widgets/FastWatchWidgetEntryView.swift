import SwiftUI
import WidgetKit

struct FastWatchWidgetEntryView: View {
    let entry: FastWatchEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCorner:
            cornerView
        default:
            circularView
                .containerBackground(.clear, for: .widget)
        }
    }

    // MARK: - Corner (bar gauge like battery)

    var cornerView: some View {
        ZStack {
            if entry.isActive {
                if entry.isGoalReached {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                } else {
                    Text(entry.remainingText)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                }
            } else {
                Image(systemName: "timer")
                    .font(.title3)
            }
        }
        .widgetCurvesContent()
        .widgetLabel {
            if entry.isActive {
                Gauge(value: min(entry.progress, 1.0)) {
                    Text("Fast")
                } currentValueLabel: {
                    Text(entry.remainingText)
                }
                .gaugeStyle(.accessoryLinear)
                .tint(ringColor)
            } else {
                Text("FastWatch")
            }
        }
    }

    // MARK: - Circular (fallback)

    var circularView: some View {
        ZStack {
            if entry.isActive {
                ZStack {
                    Circle()
                        .stroke(ringColor.opacity(0.3), lineWidth: 4)
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
            } else {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                .padding(2)
            }
        }
    }

    private var ringColor: Color {
        if entry.isGoalReached { return .yellow }
        if entry.progress >= 0.75 { return .blue }
        if entry.progress >= 0.50 { return .teal }
        return .green
    }
}

// Previews (corner gauge rendered as standalone since widget context not available)
#Preview("Corner Active") {
    let entry = FastWatchEntry(
        date: Date(), progress: 0.65, remainingText: "6h",
        isActive: true, isGoalReached: false
    )
    VStack(spacing: 12) {
        Gauge(value: min(entry.progress, 1.0)) {
            Image(systemName: "timer")
        } currentValueLabel: {
            Text(entry.remainingText)
        }
        .gaugeStyle(.accessoryLinear)
        .tint(.teal)

        Text("Corner complication preview")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .frame(width: 160)
    .padding()
}

#Preview("Corner Goal Reached") {
    VStack(spacing: 12) {
        Gauge(value: 1.0) {
            Image(systemName: "checkmark.circle.fill")
        }
        .gaugeStyle(.accessoryLinear)
        .tint(.yellow)

        Text("Goal reached")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
    .frame(width: 160)
    .padding()
}

#Preview("Circular Active") {
    FastWatchWidgetEntryView(entry: FastWatchEntry(
        date: Date(), progress: 0.65, remainingText: "6h",
        isActive: true, isGoalReached: false
    )).circularView
    .frame(width: 76, height: 76)
}

#Preview("Circular Idle") {
    FastWatchWidgetEntryView(entry: FastWatchEntry(
        date: Date(), progress: 0, remainingText: "",
        isActive: false, isGoalReached: false
    )).circularView
    .frame(width: 76, height: 76)
}
