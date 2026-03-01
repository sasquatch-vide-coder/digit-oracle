import SwiftUI
import SwiftData
import CoreLocation

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

    var body: some Scene {
        WindowGroup {
            Group {
                if TrackedNumberService.shared.hasCompletedOnboarding {
                    ContentView(selectedTab: $selectedTab)
                        .onOpenURL { url in
                            handleDeepLink(url)
                        }
                        .onAppear {
                            backfillSightings()
                            migrateFullImagesToPhotoLibrary()
                            backfillLocationNames()
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            if newPhase == .active {
                                selectedTab = .capture
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

        Task.detached(priority: .background) {
            var migrated = 0
            for sighting in sightings where sighting.hasLocalFullImage && sighting.sourceIdentifier != nil {
                if PhotoLibraryImageService.shared.assetExists(identifier: sighting.sourceIdentifier!) {
                    try? ImageStorageService.shared.deleteImage(fileName: sighting.imageFileName)
                    await MainActor.run { sighting.hasLocalFullImage = false }
                    migrated += 1
                }
            }
            if migrated > 0 {
                await MainActor.run { try? context.save() }
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

        let needsBackfill = sightings.filter { $0.latitude != nil && $0.longitude != nil && ($0.locationName == nil || $0.locationName!.isEmpty) }
        guard !needsBackfill.isEmpty else { return }

        Task.detached(priority: .utility) {
            let geocoder = CLGeocoder()
            for sighting in needsBackfill {
                guard let lat = sighting.latitude, let lon = sighting.longitude else { continue }
                let location = CLLocation(latitude: lat, longitude: lon)
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
                    await MainActor.run { sighting.locationName = locationName }
                }
                // Rate limit geocoding requests
                try? await Task.sleep(for: .milliseconds(200))
            }
            await MainActor.run { try? context.save() }
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
