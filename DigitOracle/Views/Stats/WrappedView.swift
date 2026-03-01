import SwiftUI
import SwiftData

struct WrappedView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @State private var currentPage = 0

    private let calendar = Calendar.current

    private var currentMonth: Int { calendar.component(.month, from: .now) }
    private var currentYear: Int { calendar.component(.year, from: .now) }

    private var monthSightings: [Sighting] {
        sightings.filter {
            calendar.component(.month, from: $0.captureDate) == currentMonth &&
            calendar.component(.year, from: $0.captureDate) == currentYear
        }
    }

    private var yearSightings: [Sighting] {
        sightings.filter {
            calendar.component(.year, from: $0.captureDate) == currentYear
        }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: .now)
    }

    private var pages: [WrappedPage] {
        var result: [WrappedPage] = []

        // Page 1: Month title
        result.append(.title(monthName, currentYear))

        // Page 2: Total count this month
        result.append(.stat(
            "\(monthSightings.count)",
            "visions this \(monthName)",
            "eye.fill",
            .blue
        ))

        // Page 3: Verified count
        let verified = monthSightings.filter(\.containsTrackedNumber).count
        if verified > 0 {
            result.append(.stat(
                "\(verified)",
                "OCR-verified finds",
                "checkmark.seal.fill",
                .green
            ))
        }

        // Page 4: Top category
        let catCounts = Dictionary(grouping: monthSightings.compactMap(\.category), by: { $0 })
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        if let top = catCounts.first {
            result.append(.stat(
                top.key.capitalized,
                "was your top category with \(top.value) vision\(top.value == 1 ? "" : "s")",
                SightingCategory(rawValue: top.key)?.iconName ?? "tag.fill",
                SightingCategory(rawValue: top.key)?.color ?? .gray
            ))
        }

        // Page 5: Rarest find
        if let rarest = monthSightings.max(by: { $0.rarityScore < $1.rarityScore }), rarest.rarityScore >= 3 {
            result.append(.stat(
                Constants.Rarity.label(for: rarest.rarityScore),
                "was your rarest find: \"\(rarest.notes.prefix(40))\"",
                "diamond.fill",
                .purple
            ))
        }

        // Page 6: Locations
        let locations = Set(monthSightings.compactMap(\.locationName))
        if !locations.isEmpty {
            result.append(.stat(
                "\(locations.count)",
                "unique location\(locations.count == 1 ? "" : "s") visited",
                "mappin.circle.fill",
                .red
            ))
        }

        // Page 7: Streak
        let streak = StatsCalculator.currentStreak(from: Array(sightings))
        if streak > 0 {
            result.append(.stat(
                "\(streak)",
                "day streak — keep it going!",
                "flame.fill",
                .orange
            ))
        }

        // Page 8: Year total
        result.append(.stat(
            "\(yearSightings.count)",
            "visions in \(currentYear) so far",
            "calendar",
            .indigo
        ))

        // Final page
        result.append(.finale)

        return result
    }

    var body: some View {
        TabView(selection: $currentPage) {
            ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                wrappedPageView(page)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func wrappedPageView(_ page: WrappedPage) -> some View {
        switch page {
        case .title(let month, let year):
            VStack(spacing: 16) {
                Spacer()
                Text("Your")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                Text("\(month)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Wrapped")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(String(year))")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("Swipe to begin →")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 40)
            }

        case .stat(let value, let label, let icon, _):
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }

        case .finale:
            VStack(spacing: 20) {
                Spacer()
                Text("\(TrackedNumberService.shared.primaryNumber)")
                    .font(.system(size: 100, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Keep spotting!")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.8))
                Text("Every number tells a story.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
            }
        }
    }

    private var gradientColors: [Color] {
        let palettes: [[Color]] = [
            [.indigo, .purple, .pink],
            [.blue, .cyan, .teal],
            [.orange, .red, .pink],
            [.purple, .blue, .indigo],
            [.teal, .green, .mint],
        ]
        let index = currentPage % palettes.count
        return palettes[index]
    }
}

enum WrappedPage {
    case title(String, Int)
    case stat(String, String, String, Color)
    case finale
}
