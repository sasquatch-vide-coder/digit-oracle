import Foundation

struct AchievementDef {
    let key: String
    let name: String
    let description: String
    let icon: String
    let target: Int  // target count for progressive achievements

    func toModel() -> Achievement {
        Achievement(key: key, name: name, descriptionText: description, iconName: icon)
    }
}

enum AchievementDefinitions {
    static let all: [AchievementDef] = [
        // Milestones
        AchievementDef(key: "first_blood", name: "First Glimpse", description: "Record thy first vision", icon: "1.circle.fill", target: 1),
        AchievementDef(key: "getting_started", name: "Devoted Seeker", description: "Record 10 visions", icon: "10.circle.fill", target: 10),
        AchievementDef(key: "half_century", name: "Keeper of Omens", description: "Record 50 visions", icon: "star.circle.fill", target: 50),
        AchievementDef(key: "century_club", name: "The Centennial Seer", description: "Record 100 visions", icon: "crown.fill", target: 100),

        // Time-based
        AchievementDef(key: "night_owl", name: "Midnight Vigil", description: "Record a vision between midnight and 5 AM", icon: "moon.fill", target: 1),
        AchievementDef(key: "early_bird", name: "Dawn Watcher", description: "Record a vision between 5 AM and 7 AM", icon: "sunrise.fill", target: 1),
        AchievementDef(key: "rapid_fire", name: "The Flood", description: "Record 3 visions within a single hour", icon: "bolt.fill", target: 3),

        // Category
        AchievementDef(key: "the_naturalist", name: "Eye of the Wild", description: "Record 10 visions in the Natural category", icon: "leaf.fill", target: 10),
        AchievementDef(key: "sharpshooter", name: "Oracle's Chosen", description: "Record 10 visions where the Oracle divines thy sacred number", icon: "scope", target: 10),

        // Streaks
        AchievementDef(key: "streak_7", name: "Eternal Flame", description: "Record at least one vision per day for 7 days in a row", icon: "flame.fill", target: 7),
        AchievementDef(key: "streak_30", name: "Undying Devotion", description: "Record at least one vision per day for 30 days in a row", icon: "flame.circle.fill", target: 30),
        AchievementDef(key: "streak_47", name: "The Sacred Vigil", description: "Record at least one vision per day for 47 days in a row", icon: "trophy.fill", target: 47),

        // Special
        AchievementDef(key: "forty_seven_on_47", name: "The Ordained Day", description: "Record a vision on February 16th — the 47th day of the year", icon: "calendar.badge.exclamationmark", target: 1),
        AchievementDef(key: "rare_hunter", name: "Prophet of Legends", description: "Record 5 visions rated Prophecy Fulfilled", icon: "diamond.fill", target: 5),
        AchievementDef(key: "world_traveler", name: "The Wandering Seer", description: "Record visions in 5 different locations", icon: "globe.americas.fill", target: 5),

        // Organization
        AchievementDef(key: "tagmaster", name: "Keeper of Glyphs", description: "Use 10 different tags across thy visions", icon: "tag.fill", target: 10),
        AchievementDef(key: "album_collector", name: "Scroll Weaver", description: "Create 5 scrolls", icon: "rectangle.stack.fill", target: 5),

        // Archive
        AchievementDef(key: "archivist", name: "The Archivist", description: "Peer into the Archive and offer a vision unto the Oracle", icon: "books.vertical.fill", target: 1),
    ]

    static func definition(for key: String) -> AchievementDef? {
        all.first { $0.key == key }
    }
}
