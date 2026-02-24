import WidgetKit
import SwiftUI

struct QuickCaptureWidget: Widget {
    let kind = "QuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickCaptureProvider()) { entry in
            QuickCaptureView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Capture")
        .description("Tap to capture a 47 sighting.")
        .supportedFamilies([.systemSmall])
    }
}

struct QuickCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickCaptureEntry {
        QuickCaptureEntry(date: .now, totalCount: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickCaptureEntry) -> Void) {
        completion(QuickCaptureEntry(date: .now, totalCount: WidgetData.totalCount))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickCaptureEntry>) -> Void) {
        let entry = QuickCaptureEntry(date: .now, totalCount: WidgetData.totalCount)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct QuickCaptureEntry: TimelineEntry {
    let date: Date
    let totalCount: Int
}

struct QuickCaptureView: View {
    let entry: QuickCaptureEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "camera.fill")
                .font(.system(size: 32))
                .foregroundStyle(.blue)

            Text("Spot a 47")
                .font(.caption.bold())

            Text("\(entry.totalCount) total")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .widgetURL(URL(string: "spot47://capture"))
    }
}
