import SwiftUI
import SwiftData

@main
struct BinaryCuriousApp: App {
    let container: ModelContainer

    @State private var selectedTab: AppTab = .capture

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
            if TrackedNumberService.shared.hasCompletedOnboarding {
                if TrackedNumberService.shared.hasOfferedLibraryScan {
                    ContentView(selectedTab: $selectedTab)
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                        .onAppear { backfillSightings() }
                } else {
                    OnboardingScanOfferView()
                }
            } else {
                NumberSelectionView(isOnboarding: true)
            }
        }
        .modelContainer(container)
    }

    /// Backfill existing sightings that have contains47 but empty matchedNumbers.
    private func backfillSightings() {
        let context = container.mainContext
        guard let sightings = try? context.fetch(FetchDescriptor<Sighting>()) else { return }

        var needsSave = false
        for sighting in sightings where sighting.contains47 && sighting.matchedNumbers.isEmpty {
            sighting.matchedNumbers = [47]

            sighting.matchCounts = ["47": 1]
            needsSave = true
        }

        if needsSave {
            try? context.save()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "binarycurious" else { return }
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
