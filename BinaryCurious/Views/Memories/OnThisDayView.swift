import SwiftUI
import SwiftData

struct OnThisDayView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private let calendar = Calendar.current

    private var memories: [YearMemory] {
        let today = calendar.dateComponents([.month, .day], from: .now)
        let currentYear = calendar.component(.year, from: .now)

        var byYear: [Int: [Sighting]] = [:]

        for sighting in sightings {
            let comps = calendar.dateComponents([.year, .month, .day], from: sighting.captureDate)
            if comps.month == today.month && comps.day == today.day,
               let year = comps.year, year < currentYear {
                byYear[year, default: []].append(sighting)
            }
        }

        return byYear.sorted { $0.key > $1.key }
            .map { YearMemory(year: $0.key, sightings: $0.value) }
    }

    private var todaysSightings: [Sighting] {
        sightings.filter { calendar.isDateInToday($0.captureDate) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.accentColor)
                    Text("On This Day")
                        .font(.title2.bold())
                    Text(Date.now.formatted(.dateTime.month(.wide).day()))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                if memories.isEmpty && todaysSightings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("No memories for today yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Keep spotting numbers and you'll see past sightings from this date here!")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.horizontal, 40)
                }

                // Today's sightings
                if !todaysSightings.isEmpty {
                    memorySection(title: "Today", sightings: todaysSightings)
                }

                // Past years
                ForEach(memories) { memory in
                    memorySection(
                        title: yearsAgoText(memory.year),
                        sightings: memory.sightings
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Memories")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func memorySection(title: String, sightings: [Sighting]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            ForEach(sightings) { sighting in
                MemoryCard(sighting: sighting)
            }
        }
    }

    private func yearsAgoText(_ year: Int) -> String {
        let diff = Calendar.current.component(.year, from: .now) - year
        if diff == 1 { return "1 Year Ago" }
        return "\(diff) Years Ago"
    }
}

// MARK: - Memory Card

struct MemoryCard: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            SightingThumbnailView(sighting: sighting, size: 80)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                if !sighting.notes.isEmpty {
                    Text(sighting.notes)
                        .font(.subheadline)
                        .lineLimit(2)
                }

                if let location = sighting.locationName {
                    Label(location, systemImage: "mappin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(sighting.captureDate.formatted(date: .long, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if sighting.containsTrackedNumber {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Year Memory

struct YearMemory: Identifiable {
    let id = UUID()
    let year: Int
    let sightings: [Sighting]
}
