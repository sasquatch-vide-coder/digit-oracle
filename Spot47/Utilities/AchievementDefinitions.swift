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
        AchievementDef(key: "first_blood", name: "First Blood", description: "Capture your first 47 sighting", icon: "1.circle.fill", target: 1),
        AchievementDef(key: "getting_started", name: "Getting Started", description: "Capture 10 sightings", icon: "10.circle.fill", target: 10),
        AchievementDef(key: "half_century", name: "Half Century", description: "Capture 50 sightings", icon: "star.circle.fill", target: 50),
        AchievementDef(key: "century_club", name: "Century Club", description: "Capture 100 sightings", icon: "crown.fill", target: 100),

        // Time-based
        AchievementDef(key: "night_owl", name: "Night Owl", description: "Capture a sighting after midnight", icon: "moon.fill", target: 1),
        AchievementDef(key: "early_bird", name: "Early Bird", description: "Capture a sighting before 7 AM", icon: "sunrise.fill", target: 1),
        AchievementDef(key: "rapid_fire", name: "Rapid Fire", description: "Capture 3 sightings in one hour", icon: "bolt.fill", target: 3),

        // Category
        AchievementDef(key: "the_naturalist", name: "The Naturalist", description: "Capture 10 'Natural' sightings", icon: "leaf.fill", target: 10),
        AchievementDef(key: "sharpshooter", name: "Sharpshooter", description: "Get 10 OCR-verified sightings", icon: "scope", target: 10),
        // Streaks
        AchievementDef(key: "streak_7", name: "Lucky 7", description: "Maintain a 7-day streak", icon: "flame.fill", target: 7),
        AchievementDef(key: "streak_30", name: "Monthly Master", description: "Maintain a 30-day streak", icon: "flame.circle.fill", target: 30),
        AchievementDef(key: "streak_47", name: "The 47 Streak", description: "Maintain a 47-day streak!", icon: "trophy.fill", target: 47),

        // Special
        AchievementDef(key: "forty_seven_on_47", name: "47 on 47", description: "Capture a sighting on the 47th day of the year", icon: "calendar.badge.exclamationmark", target: 1),
        AchievementDef(key: "rare_hunter", name: "Rare Hunter", description: "Capture 5 Legendary sightings", icon: "diamond.fill", target: 5),
        AchievementDef(key: "world_traveler", name: "World Traveler", description: "Spot 47s in 5+ distinct locations", icon: "globe.americas.fill", target: 5),

        // Organization
        AchievementDef(key: "tagmaster", name: "Tag Enthusiast", description: "Use 10+ distinct tags", icon: "tag.fill", target: 10),
        AchievementDef(key: "album_collector", name: "Collector", description: "Create 5+ albums", icon: "rectangle.stack.fill", target: 5),

        // Capture modes
        AchievementDef(key: "ar_spotter", name: "AR Spotter", description: "Capture using AR scan mode", icon: "arkit", target: 1),
    ]

    static func definition(for key: String) -> AchievementDef? {
        all.first { $0.key == key }
    }
}
