import SwiftUI
import WidgetKit

struct FastWatchWidgetEntryView: View {
    let entry: FastWatchEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCorner:
            cornerView
        case .accessoryRectangular:
            rectangularView
                .containerBackground(.clear, for: .widget)
        default:
            circularView
                .containerBackground(.clear, for: .widget)
        }
    }

    // MARK: - Corner (bar gauge like battery)

    var cornerView: some View {
        Image(systemName: entry.isActive
              ? (entry.isGoalReached ? "checkmark" : "timer")
              : "timer")
            .font(.system(size: 24))
            .foregroundStyle(entry.isActive ? ringColor : .gray)
            .widgetCurvesContent()
            .widgetLabel {
                if entry.isActive {
                    Gauge(value: min(entry.progress, 1.0)) {
                        Text(entry.remainingText)
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(ringColor)
                } else {
                    Text("FastWatch")
                }
            }
    }

    // MARK: - Rectangular (Smart Stack)

    var rectangularView: some View {
        Group {
            if entry.isActive {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: entry.isGoalReached ? "checkmark.circle.fill" : "timer")
                            .foregroundStyle(ringColor)
                        Text(entry.protocolName)
                            .font(.headline)
                        Spacer()
                        Text(entry.isGoalReached ? "Done!" : entry.remainingText)
                            .font(.system(.body, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }

                    Gauge(value: min(entry.progress, 1.0)) {
                        EmptyView()
                    }
                    .gaugeStyle(.accessoryLinear)
                    .tint(ringColor)

                    HStack {
                        Text(entry.zoneName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(entry.elapsedText + " elapsed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "timer")
                            .foregroundStyle(.secondary)
                        Text("FastWatch")
                            .font(.headline)
                    }
                    Text("No active fast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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

// MARK: - Previews

private let previewActiveEntry = FastWatchEntry(
    date: Date(), progress: 0.65, remainingText: "6h", elapsedText: "10h",
    isActive: true, isGoalReached: false, zoneName: "Fat Burning", protocolName: "16:8"
)

private let previewGoalEntry = FastWatchEntry(
    date: Date(), progress: 1.0, remainingText: "0m", elapsedText: "16h",
    isActive: true, isGoalReached: true, zoneName: "Ketosis", protocolName: "16:8"
)

private let previewIdleEntry = FastWatchEntry(
    date: Date(), progress: 0, remainingText: "", elapsedText: "",
    isActive: false, isGoalReached: false, zoneName: "", protocolName: ""
)

#Preview("Rectangular Active") {
    FastWatchWidgetEntryView(entry: previewActiveEntry).rectangularView
        .frame(width: 180, height: 70)
        .padding()
}

#Preview("Rectangular Goal") {
    FastWatchWidgetEntryView(entry: previewGoalEntry).rectangularView
        .frame(width: 180, height: 70)
        .padding()
}

#Preview("Rectangular Idle") {
    FastWatchWidgetEntryView(entry: previewIdleEntry).rectangularView
        .frame(width: 180, height: 70)
        .padding()
}

#Preview("Corner Active") {
    let entry = previewActiveEntry
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

#Preview("Circular Active") {
    FastWatchWidgetEntryView(entry: previewActiveEntry).circularView
        .frame(width: 76, height: 76)
}

#Preview("Circular Idle") {
    FastWatchWidgetEntryView(entry: previewIdleEntry).circularView
        .frame(width: 76, height: 76)
}
