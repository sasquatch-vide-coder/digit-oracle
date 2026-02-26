import Foundation

@Observable
final class TrackedNumberService {
    static let shared = TrackedNumberService()

    private let defaults: UserDefaults?
    private let trackedNumbersKey = "tracked_numbers"
    private let onboardingKey = "has_completed_number_onboarding"
    private let libraryScanOfferKey = "has_offered_library_scan"

    var trackedNumbers: [Int] {
        didSet { persist() }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults?.set(hasCompletedOnboarding, forKey: onboardingKey) }
    }

    var hasOfferedLibraryScan: Bool {
        didSet { defaults?.set(hasOfferedLibraryScan, forKey: libraryScanOfferKey) }
    }

    var primaryNumber: Int {
        trackedNumbers.first ?? 47
    }

    /// String representations of each tracked number for OCR matching.
    var patterns: [String] {
        trackedNumbers.map(String.init)
    }

    private init() {
        let suite = UserDefaults(suiteName: Constants.appGroupIdentifier)
        self.defaults = suite

        if let stored = suite?.array(forKey: trackedNumbersKey) as? [Int], !stored.isEmpty {
            self.trackedNumbers = stored
        } else {
            self.trackedNumbers = Constants.TrackedNumbers.defaultNumbers
        }

        self.hasCompletedOnboarding = suite?.bool(forKey: onboardingKey) ?? false
        self.hasOfferedLibraryScan = suite?.bool(forKey: libraryScanOfferKey) ?? false
    }

    // MARK: - Mutators

    func addNumber(_ number: Int) {
        guard !trackedNumbers.contains(number),
              trackedNumbers.count < Constants.TrackedNumbers.maxTrackedNumbers else { return }
        trackedNumbers.append(number)
    }

    func removeNumber(_ number: Int) {
        guard trackedNumbers.count > 1 else { return }
        trackedNumbers.removeAll { $0 == number }
    }

    func reorder(from source: IndexSet, to destination: Int) {
        trackedNumbers.move(fromOffsets: source, toOffset: destination)
    }

    func resetToDefaults() {
        trackedNumbers = Constants.TrackedNumbers.defaultNumbers
        hasCompletedOnboarding = false
        hasOfferedLibraryScan = false
        defaults?.removeObject(forKey: trackedNumbersKey)
        UserDefaults.standard.removeObject(forKey: "lastLibraryScanDate")
    }

    // MARK: - Persistence

    private func persist() {
        defaults?.set(trackedNumbers, forKey: trackedNumbersKey)
    }
}
