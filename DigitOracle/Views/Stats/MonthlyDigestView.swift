import SwiftUI
import SwiftData

struct MonthlyDigestView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @State private var selectedMonth = Date.now

    private let calendar = Calendar.current

    private var monthSightings: [Sighting] {
        let comps = calendar.dateComponents([.year, .month], from: selectedMonth)
        return sightings.filter {
            let sc = calendar.dateComponents([.year, .month], from: $0.captureDate)
            return sc.year == comps.year && sc.month == comps.month
        }
    }

    private var monthTitle: String {
        selectedMonth.formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Month navigation
                HStack {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.title3.bold())
                    Spacer()
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(calendar.isDate(selectedMonth, equalTo: .now, toGranularity: .month))
                }
                .padding(.horizontal)

                if monthSightings.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("No visions this month")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    digestContent
                }
            }
            .padding()
        }
        .navigationTitle("Monthly Digest")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var digestContent: some View {
        VStack(spacing: 16) {
            // Total
            StatCard(
                title: "Visions",
                value: "\(monthSightings.count)",
                icon: "eye.fill",
                color: .blue
            )

            // Highlights grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                let verified = monthSightings.filter(\.containsTrackedNumber).count
                StatCard(title: "Verified", value: "\(verified)", icon: "checkmark.seal.fill", color: .green)

                let favorites = monthSightings.filter(\.isFavorite).count
                StatCard(title: "Favorites", value: "\(favorites)", icon: "heart.fill", color: .red)

                let locations = Set(monthSightings.compactMap(\.locationName)).count
                StatCard(title: "Locations", value: "\(locations)", icon: "mappin.circle.fill", color: .orange)

                let categories = Set(monthSightings.compactMap(\.category)).count
                StatCard(title: "Categories", value: "\(categories)", icon: "tag.fill", color: .purple)
            }

            // Top sighting
            if let best = monthSightings.max(by: { $0.rarityScore < $1.rarityScore }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rarest Find")
                        .font(.headline)

                    MemoryCard(sighting: best)
                }
            }

            // Category breakdown
            let catCounts = Dictionary(grouping: monthSightings.compactMap(\.category), by: { $0 })
                .mapValues(\.count)
                .sorted { $0.value > $1.value }

            if !catCounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Categories")
                        .font(.headline)

                    ForEach(catCounts, id: \.key) { cat, count in
                        HStack {
                            if let sc = SightingCategory(rawValue: cat) {
                                Label(sc.displayName, systemImage: sc.iconName)
                                    .font(.subheadline)
                            } else {
                                Text(cat.capitalized)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(count)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}
