import SwiftUI
import WidgetKit

struct FastWatchWidget: Widget {
    let kind: String = "FastWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastWatchTimelineProvider()) { entry in
            FastWatchWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("FastWatch")
        .description("Track your fasting progress.")
        .supportedFamilies([.accessoryCorner, .accessoryCircular])
    }
}
