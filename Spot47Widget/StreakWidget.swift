import WidgetKit
import SwiftUI

struct StreakWidget: Widget {
    let kind = "StreakWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
            StreakWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Shows your current 47 sighting streak.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct StreakProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, streak: WidgetData.currentStreak))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let entry = StreakEntry(date: .now, streak: WidgetData.currentStreak)
        let timeline = Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600)))
        completion(timeline)
    }
}

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

struct StreakWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: StreakEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                    Text("\(entry.streak)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Label("Streak", systemImage: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(entry.streak) day\(entry.streak == 1 ? "" : "s")")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                }
                Spacer()
            }
        default:
            Text("\(entry.streak)")
        }
    }
}
