import WidgetKit
import SwiftUI

struct RecentSightingWidget: Widget {
    let kind = "RecentSightingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RecentSightingProvider()) { entry in
            RecentSightingView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Recent Vision")
        .description("The Oracle recalls a recent vision.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct RecentSightingProvider: TimelineProvider {
    func placeholder(in context: Context) -> RecentSightingEntry {
        RecentSightingEntry(
            date: .now,
            notes: "Found a 47!",
            sightingDate: .now,
            category: "digital",
            location: nil,
            thumbnailData: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RecentSightingEntry) -> Void) {
        let entry = makeRandomEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentSightingEntry>) -> Void) {
        // Create multiple entries so the widget rotates through sightings
        let sightings = WidgetData.sharedSightings
        var entries: [RecentSightingEntry] = []
        let now = Date.now

        if sightings.isEmpty {
            entries.append(RecentSightingEntry(
                date: now,
                notes: "The void reveals nothing yet",
                sightingDate: nil,
                category: "",
                location: nil,
                thumbnailData: nil
            ))
        } else {
            // Create an entry for each sighting, spaced 30 min apart
            let shuffled = sightings.shuffled()
            for (index, sighting) in shuffled.enumerated() {
                let entryDate = now.addingTimeInterval(Double(index) * 1800)
                let imageData = WidgetData.loadImage(fileName: sighting.fileName)?.jpegData(compressionQuality: 0.8)
                entries.append(RecentSightingEntry(
                    date: entryDate,
                    notes: sighting.notes,
                    sightingDate: sighting.date,
                    category: sighting.category,
                    location: sighting.location,
                    thumbnailData: imageData
                ))
            }
        }

        let refreshDate = now.addingTimeInterval(Double(max(entries.count, 1)) * 1800)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    private func makeRandomEntry() -> RecentSightingEntry {
        let sightings = WidgetData.sharedSightings
        if let sighting = sightings.randomElement() {
            let imageData = WidgetData.loadImage(fileName: sighting.fileName)?.jpegData(compressionQuality: 0.8)
            return RecentSightingEntry(
                date: .now,
                notes: sighting.notes,
                sightingDate: sighting.date,
                category: sighting.category,
                location: sighting.location,
                thumbnailData: imageData
            )
        }
        return RecentSightingEntry(
            date: .now,
            notes: WidgetData.latestNotes,
            sightingDate: WidgetData.latestDate,
            category: WidgetData.latestCategory,
            location: nil,
            thumbnailData: nil
        )
    }
}

struct RecentSightingEntry: TimelineEntry {
    let date: Date
    let notes: String
    let sightingDate: Date?
    let category: String
    let location: String?
    let thumbnailData: Data?
}

struct RecentSightingView: View {
    @Environment(\.widgetFamily) var family
    let entry: RecentSightingEntry

    var body: some View {
        if let imageData = entry.thumbnailData,
           let uiImage = UIImage(data: imageData) {
            imageWidget(uiImage: uiImage)
        } else {
            textOnlyWidget
        }
    }

    private func imageWidget(uiImage: UIImage) -> some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            // Gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 2) {
                Spacer()

                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(family == .systemMedium ? .subheadline.bold() : .caption.bold())
                        .foregroundStyle(.white)
                        .lineLimit(family == .systemMedium ? 2 : 1)
                }

                HStack(spacing: 6) {
                    if !entry.category.isEmpty {
                        Text(entry.category.capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.white.opacity(0.25), in: Capsule())
                            .foregroundStyle(.white)
                    }

                    if let location = entry.location, family == .systemMedium {
                        Text(location)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(1)
                    }

                    Spacer()

                    if let date = entry.sightingDate {
                        Text(date, style: .relative)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(12)
        }
        .widgetURL(URL(string: "digitoracle://sightings"))
    }

    private var textOnlyWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(Color(red: 0.788, green: 0.659, blue: 0.298))
                Text("Recent Vision")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(entry.notes)
                .font(.subheadline)
                .lineLimit(family == .systemMedium ? 3 : 2)

            Spacer()

            HStack {
                if !entry.category.isEmpty {
                    Text(entry.category.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.788, green: 0.659, blue: 0.298).opacity(0.2), in: Capsule())
                }
                Spacer()
                if let date = entry.sightingDate {
                    Text(date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .widgetURL(URL(string: "digitoracle://sightings"))
    }
}
