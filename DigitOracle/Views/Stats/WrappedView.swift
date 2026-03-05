import SwiftUI
import SwiftData

struct WrappedView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @State private var currentPage = 0
    @State private var selectedMonth: Date = Date()

    private let calendar = Calendar.current

    private var displayMonth: Int { calendar.component(.month, from: selectedMonth) }
    private var displayYear: Int { calendar.component(.year, from: selectedMonth) }

    private var monthSightings: [Sighting] {
        sightings.filter {
            calendar.component(.month, from: $0.captureDate) == displayMonth &&
            calendar.component(.year, from: $0.captureDate) == displayYear
        }
    }

    private var yearSightings: [Sighting] {
        sightings.filter {
            calendar.component(.year, from: $0.captureDate) == displayYear
        }
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedMonth)
    }

    private var isCurrentMonth: Bool {
        calendar.component(.month, from: selectedMonth) == calendar.component(.month, from: .now) &&
        calendar.component(.year, from: selectedMonth) == calendar.component(.year, from: .now)
    }

    private var hasPriorMonth: Bool {
        guard let earliest = sightings.last?.captureDate else { return false }
        guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return false }
        let comps = calendar.dateComponents([.year, .month], from: prevMonth)
        guard let prevStart = calendar.date(from: comps),
              let prevEnd = calendar.date(byAdding: .month, value: 1, to: prevStart) else { return false }
        return earliest < prevEnd
    }

    private var pages: [WrappedPage] {
        var result: [WrappedPage] = []

        // Page 1: Month title
        result.append(.title(monthName, displayYear))

        // Page 2: Total count this month
        result.append(.stat(
            "\(monthSightings.count)",
            "visions this \(monthName)",
            "eye.fill",
            .goldLight
        ))

        // Page 3: Revealed count
        let revealed = monthSightings.filter(\.containsTrackedNumber).count
        if revealed > 0 {
            result.append(.stat(
                "\(revealed)",
                "Revealed by the Oracle",
                "sparkles",
                .goldPrimary
            ))
        }

        // Page 4: Top category
        let catCounts = Dictionary(grouping: monthSightings.compactMap(\.category), by: { $0 })
            .mapValues(\.count)
            .sorted { $0.value > $1.value }
        if let top = catCounts.first {
            result.append(.stat(
                top.key.capitalized,
                "was your top vessel with \(top.value.pluralized("vision"))",
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
                .purpleLight
            ))
        }

        // Page 6: Locations
        let locations = Set(monthSightings.compactMap(\.locationName))
        if !locations.isEmpty {
            result.append(.stat(
                "\(locations.count)",
                "sacred ground\(locations.count.pluralSuffix) tread upon",
                "mappin.circle.fill",
                .goldDark
            ))
        }

        // Page 7: Streak (only for current month)
        if isCurrentMonth {
            let streak = StatsCalculator.currentStreak(from: Array(sightings))
            if streak > 0 {
                result.append(.stat(
                    "\(streak)",
                    "day vigil \u{2014} the flame endures!",
                    "flame.fill",
                    .goldLight
                ))
            }
        }

        // Page 8: Year total
        result.append(.stat(
            "\(yearSightings.count)",
            "visions in \(displayYear)\(isCurrentMonth ? " so far" : "")",
            "calendar",
            .purpleAccent
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

    private func goToPriorMonth() {
        if let prev = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            currentPage = 0
            selectedMonth = prev
        }
    }

    private func goToNextMonth() {
        if let next = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            currentPage = 0
            selectedMonth = next
        }
    }

    @ViewBuilder
    private func wrappedPageView(_ page: WrappedPage) -> some View {
        switch page {
        case .title(let month, let year):
            VStack(spacing: 16) {
                Spacer()
                Text("Your")
                    .font(.oracleBody)
                    .foregroundStyle(Color.textSecondary)

                HStack(spacing: 20) {
                    if hasPriorMonth {
                        Button { goToPriorMonth() } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.goldLight.opacity(0.7))
                        }
                    } else {
                        Color.clear.frame(width: 28)
                    }

                    Text("\(month)")
                        .font(.oracleHeading)
                        .foregroundStyle(Color.goldLight)

                    if !isCurrentMonth {
                        Button { goToNextMonth() } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title)
                                .foregroundStyle(Color.goldLight.opacity(0.7))
                        }
                    } else {
                        Color.clear.frame(width: 28)
                    }
                }

                Text("Unveiled")
                    .font(.oracleHeading)
                    .foregroundStyle(Color.goldPrimary)
                Text("\(String(year))")
                    .font(.oracleBody)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
                Text("Swipe to begin →")
                    .font(.oracleCaption)
                    .foregroundStyle(Color.textDimmed)
                    .padding(.bottom, 40)
            }

        case .stat(let value, let label, let icon, _):
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundStyle(Color.goldDark)
                Text(value)
                    .font(.sacredNumber)
                    .foregroundStyle(Color.goldLight)
                Text(label)
                    .font(.oracleBody)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }

        case .finale:
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: 16) {
                    ForEach(TrackedNumberService.shared.trackedNumbers, id: \.self) { number in
                        Text("\(number)")
                            .font(.sacredNumber)
                            .foregroundStyle(Color.goldPrimary)
                    }
                }
                Text("The Oracle watches.")
                    .font(.oracleProphecy)
                    .foregroundStyle(Color.goldLight)
                Text("Every number tells a story.")
                    .font(.oracleBody)
                    .foregroundStyle(Color.textSecondary)
                Spacer()
            }
        }
    }

    private var gradientColors: [Color] {
        let palettes: [[Color]] = [
            // Oracle's Chamber — deep void with purple undertone
            [.backgroundPrimary, Color(red: 0.12, green: 0.06, blue: 0.22), .backgroundSecondary],
            // Golden Prophecy — dark with warm gold glow
            [Color(red: 0.1, green: 0.08, blue: 0.04), Color(red: 0.22, green: 0.17, blue: 0.06), .backgroundPrimary],
            // Mystic Depths — ethereal purple light
            [Color(red: 0.08, green: 0.04, blue: 0.18), .purpleAccent.opacity(0.5), Color(red: 0.06, green: 0.03, blue: 0.12)],
            // Ember Ritual — warm bronze-amber darkness
            [.backgroundPrimary, Color(red: 0.2, green: 0.12, blue: 0.05), Color(red: 0.12, green: 0.06, blue: 0.02)],
            // Midnight Revelation — cool dark with faint gold edge
            [Color(red: 0.05, green: 0.04, blue: 0.1), .backgroundTertiary, Color(red: 0.14, green: 0.11, blue: 0.05)],
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
