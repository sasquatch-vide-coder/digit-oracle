import Foundation

struct SightingStats {
    let totalCount: Int
    let verifiedCount: Int
    let favoriteCount: Int
    let currentStreak: Int
    let longestStreak: Int
    let bestMonth: (month: String, count: Int)?
    let categoryBreakdown: [(category: String, count: Int)]
    let rarityBreakdown: [(rarity: Int, count: Int)]
    let sightingsByDay: [Date: Int]
    let citiesVisited: Int
    let averagePerWeek: Double
}

enum StatsCalculator {

    static func calculate(from sightings: [Sighting]) -> SightingStats {
        SightingStats(
            totalCount: sightings.count,
            verifiedCount: sightings.filter(\.containsTrackedNumber).count,
            favoriteCount: sightings.filter(\.isFavorite).count,
            currentStreak: currentStreak(from: sightings),
            longestStreak: longestStreak(from: sightings),
            bestMonth: bestMonth(from: sightings),
            categoryBreakdown: categoryBreakdown(from: sightings),
            rarityBreakdown: rarityBreakdown(from: sightings),
            sightingsByDay: sightingsByDay(from: sightings),
            citiesVisited: citiesVisited(from: sightings),
            averagePerWeek: averagePerWeek(from: sightings)
        )
    }

    // MARK: - Streaks

    static func currentStreak(from sightings: [Sighting]) -> Int {
        let calendar = Calendar.current
        let days = Set(sightings.map { calendar.startOfDay(for: $0.captureDate) })

        guard !days.isEmpty else { return 0 }

        var streak = 0
        var date = calendar.startOfDay(for: .now)

        // If no sighting today, start from yesterday
        if !days.contains(date) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }

        while days.contains(date) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }

        return streak
    }

    static func longestStreak(from sightings: [Sighting]) -> Int {
        let calendar = Calendar.current
        let sortedDays = Set(sightings.map { calendar.startOfDay(for: $0.captureDate) }).sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1

        for i in 1..<sortedDays.count {
            if calendar.date(byAdding: .day, value: 1, to: sortedDays[i - 1]) == sortedDays[i] {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }

        return longest
    }

    // MARK: - Best Month

    static func bestMonth(from sightings: [Sighting]) -> (month: String, count: Int)? {
        guard !sightings.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"

        var counts: [String: Int] = [:]
        for s in sightings {
            let key = formatter.string(from: s.captureDate)
            counts[key, default: 0] += 1
        }

        guard let best = counts.max(by: { $0.value < $1.value }) else { return nil }

        // Format nicely
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM"
        if let date = displayFormatter.date(from: best.key) {
            displayFormatter.dateFormat = "MMMM yyyy"
            return (displayFormatter.string(from: date), best.value)
        }
        return (best.key, best.value)
    }

    // MARK: - Breakdowns

    static func categoryBreakdown(from sightings: [Sighting]) -> [(category: String, count: Int)] {
        var counts: [String: Int] = [:]
        for s in sightings {
            let cat = s.category ?? "Uncategorized"
            counts[cat, default: 0] += 1
        }
        return counts.map { (category: $0.key.capitalized, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    static func rarityBreakdown(from sightings: [Sighting]) -> [(rarity: Int, count: Int)] {
        var counts: [Int: Int] = [:]
        for s in sightings {
            counts[s.rarityScore, default: 0] += 1
        }
        return (1...5).compactMap { score in
            guard let count = counts[score], count > 0 else { return nil }
            return (rarity: score, count: count)
        }
    }

    // MARK: - Calendar Data

    static func sightingsByDay(from sightings: [Sighting]) -> [Date: Int] {
        let calendar = Calendar.current
        var counts: [Date: Int] = [:]
        for s in sightings {
            let day = calendar.startOfDay(for: s.captureDate)
            counts[day, default: 0] += 1
        }
        return counts
    }

    // MARK: - Location

    static func citiesVisited(from sightings: [Sighting]) -> Int {
        let locations = Set(sightings.compactMap(\.locationName))
        return locations.count
    }

    // MARK: - Average

    static func averagePerWeek(from sightings: [Sighting]) -> Double {
        guard let earliest = sightings.min(by: { $0.captureDate < $1.captureDate })?.captureDate else {
            return 0
        }
        let weeks = max(1, Calendar.current.dateComponents([.weekOfYear], from: earliest, to: .now).weekOfYear ?? 1)
        return Double(sightings.count) / Double(weeks)
    }
}
