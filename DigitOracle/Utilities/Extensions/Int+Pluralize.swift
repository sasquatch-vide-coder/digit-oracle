import Foundation

extension Int {
    /// Returns "" for 1, "s" for all other counts.
    var pluralSuffix: String { self == 1 ? "" : "s" }

    /// Returns "count word" or "count words" (e.g., `3.pluralized("vision")` → "3 visions").
    func pluralized(_ word: String) -> String {
        "\(self) \(word)\(pluralSuffix)"
    }
}
