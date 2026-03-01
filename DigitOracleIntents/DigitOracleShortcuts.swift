import AppIntents

struct QuickCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Summon a Vision"
    static var description: IntentDescription = "Open Digit Oracle to divine a new vision"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        // The app will open to the capture tab via the openAppWhenRun flag
        return .result()
    }
}

struct ViewStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "View Stats"
    static var description: IntentDescription = "See your Digit Oracle statistics"
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct DigitOracleShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickCaptureIntent(),
            phrases: [
                "Summon a vision with \(.applicationName)",
                "I spotted a number in \(.applicationName)",
                "Log a vision in \(.applicationName)",
                "Open \(.applicationName) camera"
            ],
            shortTitle: "Summon Vision",
            systemImageName: "camera.fill"
        )
        AppShortcut(
            intent: ViewStatsIntent(),
            phrases: [
                "Show my stats in \(.applicationName)",
                "How many visions in \(.applicationName)",
                "My \(.applicationName) streak",
                "Open \(.applicationName) stats"
            ],
            shortTitle: "View Stats",
            systemImageName: "chart.bar.fill"
        )
    }
}
