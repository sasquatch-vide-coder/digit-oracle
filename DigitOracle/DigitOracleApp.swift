import SwiftUI
import SwiftData
import CoreLocation
import GameKit

@main
struct DigitOracleApp: App {
    let container: ModelContainer

    @State private var selectedTab: AppTab = .capture
    @Environment(\.scenePhase) private var scenePhase

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

    private var appLockService = AppLockService.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if TrackedNumberService.shared.hasCompletedOnboarding {
                    ZStack {
                        ContentView(selectedTab: $selectedTab)
                            .onOpenURL { url in
                                handleDeepLink(url)
                            }
                            .onAppear {
                                backfillSightings()
                                migrateFullImagesToPhotoLibrary()
                                backfillLocationNames()
                                authenticateGameCenter()
                            }
                            .onChange(of: GameCenterService.shared.isAuthenticated) { _, authenticated in
                                if authenticated {
                                    GameCenterService.shared.backfillScoresAndAchievements(context: container.mainContext)
                                }
                            }

                        // Privacy overlay — just a visual cover, no auth
                        if appLockService.isEnabled && appLockService.showPrivacyOverlay && !appLockService.isLocked {
                            Color.backgroundPrimary
                                .ignoresSafeArea()
                                .transition(.opacity)
                        }

                        // Lock screen — requires authentication
                        if appLockService.isEnabled && appLockService.isLocked {
                            AppLockView(appLockService: appLockService)
                                .transition(.opacity)
                        }
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        switch newPhase {
                        case .active:
                            appLockService.handleSceneActive()
                            if !GameCenterService.shared.isAuthenticated {
                                authenticateGameCenter()
                            }
                        case .inactive:
                            appLockService.handleSceneInactive()
                        case .background:
                            appLockService.handleSceneBackground()
                        @unknown default:
                            break
                        }
                    }
                } else {
                    OnboardingView()
                }
            }
            .preferredColorScheme(.dark)
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

    private func migrateFullImagesToPhotoLibrary() {
        let key = "hasRunFullImageMigration"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let context = container.mainContext
        guard let sightings = try? context.fetch(FetchDescriptor<Sighting>()) else { return }

        // Extract value-type data before leaving the main actor
        struct MigrationItem {
            let imageFileName: String
            let sourceIdentifier: String
        }
        let items: [(sighting: Sighting, info: MigrationItem)] = sightings.compactMap { sighting in
            guard sighting.hasLocalFullImage, let sourceID = sighting.sourceIdentifier else { return nil }
            return (sighting, MigrationItem(imageFileName: sighting.imageFileName, sourceIdentifier: sourceID))
        }

        Task.detached(priority: .background) {
            var migratedSightings: [Sighting] = []
            for item in items {
                if PhotoLibraryImageService.shared.assetExists(identifier: item.info.sourceIdentifier) {
                    try? ImageStorageService.shared.deleteImage(fileName: item.info.imageFileName)
                    migratedSightings.append(item.sighting)
                }
            }
            if !migratedSightings.isEmpty {
                await MainActor.run {
                    for sighting in migratedSightings {
                        sighting.hasLocalFullImage = false
                    }
                    try? context.save()
                }
            }
            await MainActor.run {
                UserDefaults.standard.set(true, forKey: key)
            }
        }
    }

    private func navigateToVisionsIfSightingsExist() {
        let context = container.mainContext
        let count = (try? context.fetchCount(FetchDescriptor<Sighting>())) ?? 0
        if count > 0 {
            selectedTab = .sightings
        }
    }

    private func backfillLocationNames() {
        let context = container.mainContext
        guard let sightings = try? context.fetch(FetchDescriptor<Sighting>()) else { return }

        let needsBackfill = sightings.filter { $0.latitude != nil && $0.longitude != nil && ($0.locationName?.isEmpty ?? true) }
        guard !needsBackfill.isEmpty else { return }

        // Extract coordinates before leaving the main actor
        struct BackfillItem {
            let latitude: Double
            let longitude: Double
        }
        let items: [(sighting: Sighting, coords: BackfillItem)] = needsBackfill.compactMap { sighting in
            guard let lat = sighting.latitude, let lon = sighting.longitude else { return nil }
            return (sighting, BackfillItem(latitude: lat, longitude: lon))
        }

        Task.detached(priority: .utility) {
            let geocoder = CLGeocoder()
            for item in items {
                let location = CLLocation(latitude: item.coords.latitude, longitude: item.coords.longitude)
                if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
                   let placemark = placemarks.first {
                    var parts: [String] = []
                    if let name = placemark.name { parts.append(name) }
                    if let city = placemark.locality { parts.append(city) }
                    if let state = placemark.administrativeArea { parts.append(state) }
                    if parts.count >= 2 && parts[0] == parts[1] {
                        parts.removeFirst()
                    }
                    let locationName = parts.joined(separator: ", ")
                    await MainActor.run { item.sighting.locationName = locationName }
                }
                // Rate limit geocoding requests
                try? await Task.sleep(for: .milliseconds(200))
            }
            await MainActor.run { try? context.save() }
        }
    }

    private func authenticateGameCenter() {
        // Delay auth slightly so app lock can dismiss first if needed
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !appLockService.isEnabled || !appLockService.isLocked else { return }
            GameCenterService.shared.authenticate()
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "digitoracle" else { return }
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
