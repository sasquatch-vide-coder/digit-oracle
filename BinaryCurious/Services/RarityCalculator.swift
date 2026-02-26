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

        // OCR verification bonus - tracked number actually detected in text
        if sighting.containsTrackedNumber {
            score += 0.5
        }

        // Location uniqueness bonus
        if let name = sighting.locationName, !name.isEmpty {
            let existingLocations = Set(totalSightings.compactMap(\.locationName))
            if !existingLocations.contains(name) {
                score += 0.75  // New location bonus
            }
        }

        // Special date bonus: Nth day of year or month/day decomposition for any tracked number
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: sighting.captureDate) ?? 0
        let components = Calendar.current.dateComponents([.month, .day], from: sighting.captureDate)
        let trackedNumbers = TrackedNumberService.shared.trackedNumbers

        let hasSpecialDate = trackedNumbers.contains { number in
            // Day N of year
            if number >= 1 && number <= 366 && dayOfYear == number { return true }
            // Month/day decomposition (e.g. 47 → April 7, 314 → March 14)
            let (month, day) = Self.decomposeToDate(number)
            if let month, let day, components.month == month && components.day == day { return true }
            return false
        }
        if hasSpecialDate {
            score += 1.0
        }

        return min(5, max(1, Int(score.rounded())))
    }

    /// Decompose a number into (month, day). E.g. 47 → (4, 7), 314 → (3, 14).
    static func decomposeToDate(_ number: Int) -> (Int?, Int?) {
        let month: Int
        let day: Int

        if number >= 10 && number <= 99 {
            month = number / 10
            day = number % 10
        } else if number >= 100 && number <= 999 {
            month = number / 100
            day = number % 100
        } else if number >= 1000 && number <= 9999 {
            month = (number / 100) % 100
            day = number % 100
        } else {
            return (nil, nil)
        }

        guard month >= 1 && month <= 12 && day >= 1 && day <= 31 else {
            return (nil, nil)
        }
        return (month, day)
    }
}
