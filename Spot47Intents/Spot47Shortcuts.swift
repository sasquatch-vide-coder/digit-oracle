import AppIntents

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a 47"
    static var description: IntentDescription = "Open Spot47 to capture a new 47 sighting"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        // The app will open to the capture tab via the openAppWhenRun flag
        return .result()
    }
}

struct ViewStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "View 47 Stats"
    static var description: IntentDescription = "See your Spot47 statistics"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct Spot47ShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "Capture a 47 with \(.applicationName)",
                "I spotted a 47 in \(.applicationName)",
                "Log a 47 sighting in \(.applicationName)",
                "Open \(.applicationName) camera"
            ],
            shortTitle: "Capture a 47",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "Show my stats in \(.applicationName)",
                "How many 47s in \(.applicationName)",
                "My \(.applicationName) streak",
                "Open \(.applicationName) stats"
            ],
            shortTitle: "View Stats",
            systemImageName: "chart.bar.fill"
        )
    }
}
