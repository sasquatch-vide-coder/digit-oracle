import AppIntents

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a Sighting"
    static var description: IntentDescription = "Open Binary Curious to capture a new sighting"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        // The app will open to the capture tab via the openAppWhenRun flag
        return .result()
    }
}

struct ViewStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Stats"
    static var description: IntentDescription = "See your Binary Curious statistics"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct BinaryCuriousShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "Capture a sighting with \(.applicationName)",
                "I spotted a number in \(.applicationName)",
                "Log a sighting in \(.applicationName)",
                "Open \(.applicationName) camera"
            ],
            shortTitle: "Capture Sighting",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "Show my stats in \(.applicationName)",
                "How many sightings in \(.applicationName)",
                "My \(.applicationName) streak",
                "Open \(.applicationName) stats"
            ],
            shortTitle: "View Stats",
            systemImageName: "chart.bar.fill"
        )
    }
}
