import Foundation
import SwiftData

@Observable
class AchievementEngine {
    /// Recently unlocked achievement keys from the last check, for triggering celebrations.
    var recentlyUnlocked: [Achievement] = []

    /// Sync achievement records with current definitions (migrate keys, update names/icons, seed missing).
    static func syncDefinitions(context: ModelContext) {
        var achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        // Migrate renamed keys
        if let arSpotter = achievements.first(where: { $0.key == "ar_spotter" }) {
            if let def = AchievementDefinitions.definition(for: "archivist") {
                arSpotter.key = def.key
                arSpotter.name = def.name
                arSpotter.descriptionText = def.description
                arSpotter.iconName = def.icon
            }
        }

        // Update names/descriptions for existing achievements to match current definitions
        for achievement in achievements {
            if let def = AchievementDefinitions.definition(for: achievement.key) {
                achievement.name = def.name
                achievement.descriptionText = def.description
                achievement.iconName = def.icon
            }
        }

        // Seed missing achievements
        let existingKeys = Set(achievements.map(\.key))
        for def in AchievementDefinitions.all where !existingKeys.contains(def.key) {
            let a = def.toModel()
            context.insert(a)
            achievements.append(a)
        }

        try? context.save()
    }

    /// Check all achievements against current data and unlock any that are earned.
    func checkAll(context: ModelContext) {
        Self.syncDefinitions(context: context)

        let sightings = (try? context.fetch(FetchDescriptor<Sighting>())) ?? []
        let albums = (try? context.fetch(FetchDescriptor<Album>())) ?? []
        let achievements = (try? context.fetch(FetchDescriptor<Achievement>())) ?? []

        recentlyUnlocked = []

        for achievement in achievements where !achievement.isUnlocked {
            let (earned, progress) = evaluate(
                key: achievement.key,
                sightings: sightings,
                albums: albums
            )
            achievement.progress = progress
            if earned {
                achievement.unlockedAt = .now
                recentlyUnlocked.append(achievement)
            }
        }

        try? context.save()
    }

    // MARK: - Evaluation

    private func evaluate(
        key: String,
        sightings: [Sighting],
        albums: [Album]
    ) -> (earned: Bool, progress: Double) {
        guard let def = AchievementDefinitions.definition(for: key) else {
            return (false, 0)
        }

        let target = Double(def.target)

        switch key {

        // Milestones
        case "first_blood", "getting_started", "half_century", "century_club":
            let count = Double(sightings.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        // Time-based
        case "night_owl":
            let has = sightings.contains { Calendar.current.component(.hour, from: $0.captureDate) < 5 }
            return (has, has ? 1.0 : 0.0)

        case "early_bird":
            let has = sightings.contains { Calendar.current.component(.hour, from: $0.captureDate) >= 5 && Calendar.current.component(.hour, from: $0.captureDate) < 7 }
            return (has, has ? 1.0 : 0.0)

        case "rapid_fire":
            let earned = hasRapidFire(sightings: sightings)
            return (earned, earned ? 1.0 : 0.0)

        // Category
        case "the_naturalist":
            let count = Double(sightings.filter { $0.category == "natural" }.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        case "sharpshooter":
            let count = Double(sightings.filter(\.containsTrackedNumber).count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        // Streaks
        case "streak_7", "streak_30", "streak_47":
            let longest = Double(StatsCalculator.longestStreak(from: sightings))
            return (longest >= target, target > 0 ? min(1.0, longest / target) : 0)

        // Special
        case "forty_seven_on_47":
            let has = sightings.contains {
                (Calendar.current.ordinality(of: .day, in: .year, for: $0.captureDate) ?? 0) == 47
            }
            return (has, has ? 1.0 : 0.0)

        case "rare_hunter":
            let count = Double(sightings.filter { $0.rarityScore == 5 }.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        case "world_traveler":
            let locations = Set(sightings.compactMap(\.locationName))
            let count = Double(locations.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        // Organization
        case "tagmaster":
            let allTags = Set(sightings.flatMap(\.tags).map(\.name))
            let count = Double(allTags.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        case "album_collector":
            let count = Double(albums.count)
            return (count >= target, target > 0 ? min(1.0, count / target) : 0)

        // Archive
        case "archivist":
            let has = sightings.contains { $0.sourceType == "library_scan" }
            return (has, has ? 1.0 : 0.0)

        default:
            return (false, 0)
        }
    }

    private func hasRapidFire(sightings: [Sighting]) -> Bool {
        let sorted = sightings.sorted { $0.captureDate < $1.captureDate }
        guard sorted.count >= 3 else { return false }
        for i in 0..<(sorted.count - 2) {
            let diff = sorted[i + 2].captureDate.timeIntervalSince(sorted[i].captureDate)
            if diff <= 3600 { return true }
        }
        return false
    }
}
