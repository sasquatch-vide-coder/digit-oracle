import WidgetKit
import SwiftUI

struct CountWidget: Widget {
    let kind = "CountWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountProvider()) { entry in
            CountWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sighting Count")
        .description("Shows your total 47 sighting count.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct CountProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry {
        CountEntry(date: .now, count: 47)
    }

    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(CountEntry(date: .now, count: WidgetData.totalCount))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountEntry>) -> Void) {
        let entry = CountEntry(date: .now, count: WidgetData.totalCount)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct CountEntry: TimelineEntry {
    let date: Date
    let count: Int
}

struct CountWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: CountEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(entry.count)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("47s")
                        .font(.system(size: 9))
                }
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Text("Sightings")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(entry.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Spacer()
            }
        default:
            Text("\(entry.count)")
        }
    }
}
