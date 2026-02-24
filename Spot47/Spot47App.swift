import SwiftUI
import SwiftData

@main
struct Spot47App: App {
    let container: ModelContainer

    @State private var selectedTab: AppTab = .sightings

    init() {
        let schema = Schema([
            Sighting.self,
            Album.self,
            Tag.self,
            UserProfile.self,
            Achievement.self,
            Challenge.self,
            TimeCapsule.self
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView(selectedTab: $selectedTab)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(container)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "spot47" else { return }
        switch url.host {
        case "capture":
            selectedTab = .capture
        case "sightings":
            selectedTab = .sightings
        case "albums":
            selectedTab = .albums
        case "profile":
            selectedTab = .profile
        default:
            break
        }
    }
}
