import Foundation

enum RarityCalculator {

    /// Auto-score rarity 1-5 based on contextual factors.
    static func autoScore(for sighting: Sighting, totalSightings: [Sighting] = []) -> Int {
        var score: Double = 1.0

        // Time of day bonus
        let hour = Calendar.current.component(.hour, from: sighting.captureDate)
        if hour >= 0 && hour < 5 {
            score += 1.5  // Late night / early morning is rare
        } else if hour >= 5 && hour < 7 {
            score += 0.75  // Early bird
        }

        // Category bonus
        if let category = sighting.category {
            switch category {
            case "serendipitous": score += 1.5
            case "natural": score += 0.75
            case "handwritten": score += 0.5
            case "architectural": score += 0.25
            case "digital": score += 0.0
            case "printed": score += 0.0
            default: break
            }
        }

        // OCR verification bonus - 47 actually detected in text
        if sighting.contains47 {
            score += 0.5
        }

        // Location uniqueness bonus
        if let name = sighting.locationName, !name.isEmpty {
            let existingLocations = Set(totalSightings.compactMap(\.locationName))
            if !existingLocations.contains(name) {
                score += 0.75  // New location bonus
            }
        }

        // Special date bonus: 47th day of year (Feb 16), April 7
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: sighting.captureDate) ?? 0
        let components = Calendar.current.dateComponents([.month, .day], from: sighting.captureDate)
        if dayOfYear == 47 || (components.month == 4 && components.day == 7) {
            score += 1.0
        }

        return min(5, max(1, Int(score.rounded())))
    }
}
