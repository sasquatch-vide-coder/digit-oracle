import Foundation

enum RarityCalculator {
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
