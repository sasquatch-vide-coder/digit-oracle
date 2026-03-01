import WidgetKit
import SwiftUI

struct QuickCaptureWidget: Widget {
    let kind = "QuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickCaptureProvider()) { entry in
            QuickCaptureView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Summon")
        .description("Summon the Oracle's sight.")
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
            Image(systemName: "eye.fill")
                .font(.system(size: 32))
                .foregroundColor(Color(red: 0.788, green: 0.659, blue: 0.298))

            Text("Summon")
                .font(.caption.bold())
                .foregroundColor(Color(red: 0.910, green: 0.878, blue: 0.816))

            Text("\(entry.totalCount) visions")
                .font(.caption2)
                .foregroundColor(Color(red: 0.620, green: 0.584, blue: 0.537))
        }
        .widgetURL(URL(string: "digitoracle://capture"))
    }
}
