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
        AchievementDef(key: "first_blood", name: "First Blood", description: "Record thy first vision", icon: "1.circle.fill", target: 1),
        AchievementDef(key: "getting_started", name: "Getting Started", description: "Record 10 visions", icon: "10.circle.fill", target: 10),
        AchievementDef(key: "half_century", name: "Half Century", description: "Record 50 visions", icon: "star.circle.fill", target: 50),
        AchievementDef(key: "century_club", name: "Century Club", description: "Record 100 visions", icon: "crown.fill", target: 100),

        // Time-based
        AchievementDef(key: "night_owl", name: "Night Owl", description: "Record a vision after midnight", icon: "moon.fill", target: 1),
        AchievementDef(key: "early_bird", name: "Early Bird", description: "Record a vision before dawn", icon: "sunrise.fill", target: 1),
        AchievementDef(key: "rapid_fire", name: "Rapid Fire", description: "Record 3 visions in one hour", icon: "bolt.fill", target: 3),

        // Category
        AchievementDef(key: "the_naturalist", name: "The Naturalist", description: "Record 10 natural visions", icon: "leaf.fill", target: 10),
        AchievementDef(key: "sharpshooter", name: "Sharpshooter", description: "Gain 10 revealed visions", icon: "scope", target: 10),
        // Streaks
        AchievementDef(key: "streak_7", name: "Lucky 7", description: "Maintain a 7-day streak", icon: "flame.fill", target: 7),
        AchievementDef(key: "streak_30", name: "Monthly Master", description: "Maintain a 30-day streak", icon: "flame.circle.fill", target: 30),
        AchievementDef(key: "streak_47", name: "The 47 Streak", description: "Maintain a 47-day streak!", icon: "trophy.fill", target: 47),

        // Special
        AchievementDef(key: "forty_seven_on_47", name: "47 on 47", description: "Record a vision on the 47th day", icon: "calendar.badge.exclamationmark", target: 1),
        AchievementDef(key: "rare_hunter", name: "Rare Hunter", description: "Record 5 legendary visions", icon: "diamond.fill", target: 5),
        AchievementDef(key: "world_traveler", name: "World Traveler", description: "Spot numbers in 5+ distinct locations", icon: "globe.americas.fill", target: 5),

        // Organization
        AchievementDef(key: "tagmaster", name: "Tag Enthusiast", description: "Use 10+ distinct tags", icon: "tag.fill", target: 10),
        AchievementDef(key: "album_collector", name: "Collector", description: "Create 5+ scrolls", icon: "rectangle.stack.fill", target: 5),

        // Capture modes
        AchievementDef(key: "ar_spotter", name: "AR Spotter", description: "Capture using AR scan mode", icon: "arkit", target: 1),
    ]

    static func definition(for key: String) -> AchievementDef? {
        all.first { $0.key == key }
    }
}
