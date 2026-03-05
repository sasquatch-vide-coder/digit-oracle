import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var importedShareCount: Int?
    @State private var orphanedSightings: [Sighting] = []
    @State private var showOrphanAlert = false
    @State private var achievementEngine = AchievementEngine()
    @State private var challengeEngine = ChallengeEngine()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Summon", systemImage: "camera.fill", value: .capture) {
                NavigationStack {
                    CaptureView()
                }
            }

            Tab("Visions", systemImage: "eye", value: .sightings) {
                NavigationStack {
                    SightingListView()
                }
            }

            Tab("Scrolls", systemImage: "rectangle.stack.fill", value: .albums) {
                NavigationStack {
                    AlbumListView()
                }
            }

            Tab("Oracle\u{2019}s Eye", systemImage: "person.fill", value: .profile) {
                NavigationStack {
                    StatsOverviewView()
                }
            }
        }
        .tint(.goldPrimary)
        .task {
            await refreshWidgetData()
            await importPendingShares()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await importPendingShares() }
                Task { await checkForOrphanedSightings() }
            }
        }
        .onChange(of: selectedTab) {
            if selectedTab != .capture && !orphanedSightings.isEmpty {
                showOrphanAlert = true
            }
        }
        .alert("Lost Visions", isPresented: $showOrphanAlert) {
            Button("Release", role: .destructive) {
                deleteOrphanedSightings()
            }
            Button("Keep", role: .cancel) { }
        } message: {
            let count = orphanedSightings.count
            Text("\(count) vision\(count == 1 ? " has" : "s have") faded from thy mortal gallery. Shall the Oracle release \(count == 1 ? "it" : "them")?")
        }
        .overlay(alignment: .top) {
            if let count = importedShareCount {
                importBanner(count: count)
            }
        }
    }

    private func refreshWidgetData() async {
        let sightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        WidgetDataService.update(from: sightings)
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func importPendingShares() async {
        guard PendingSightingService.hasPendingItems else { return }
        let pending = PendingSightingService.loadAllPending()
        guard !pending.isEmpty else {
            PendingSightingService.setHasPendingItems(false)
            return
        }

        // Collect existing hashes for duplicate detection
        let existingSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        var knownHashes = existingSightings.compactMap(\.imageHash)

        var count = 0
        for item in pending {
            // Check for duplicate before saving image files
            if let hash = ImageStorageService.perceptualHash(of: item.image),
               knownHashes.contains(where: { ImageStorageService.isPerceptualDuplicate($0, hash) }) {
                try? PendingSightingService.deletePendingItem(id: item.metadata.id)
                continue
            }

            let fileNames = try? ImageStorageService.shared.saveImage(item.image, id: item.metadata.id)
            guard let fileNames else { continue }

            // OCR the saved JPEG and cache results so detail view uses same data
            guard let savedImage = ImageStorageService.shared.loadImage(fileName: fileNames.full) else { continue }
            let detection = await OCRService.shared.detect(in: savedImage)
            OCRService.shared.saveDetection(detection, for: fileNames.full)
            let ocrResult = detection.ocr

            let sighting = Sighting(
                ownerUserID: Constants.defaultOwnerID,
                imageFileName: fileNames.full,
                captureDate: item.metadata.captureDate,
                notes: item.metadata.notes,
                sourceType: "share"
            )
            sighting.thumbnailFileName = fileNames.thumbnail
            sighting.hasLocalFullImage = true
            let imageHash = ImageStorageService.perceptualHash(of: item.image)
            sighting.imageHash = imageHash
            sighting.contains47 = ocrResult.matchedNumbers.contains(47)
            sighting.matchedNumbers = ocrResult.matchedNumbers
            sighting.matchCounts = ocrResult.matchCounts
            sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)

            modelContext.insert(sighting)
            if let imageHash { knownHashes.append(imageHash) }
            try? PendingSightingService.deletePendingItem(id: item.metadata.id)
            count += 1
        }

        if count > 0 {
            try? modelContext.save()
            await refreshWidgetData()

            // Check achievements and challenges
            achievementEngine.checkAll(context: modelContext)
            // challengeEngine needs a specific sighting; check all active challenges
            let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
            let allAchievements = (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
            let longestStreak = StatsCalculator.longestStreak(from: allSightings)
            GameCenterService.shared.submitScores(totalSightings: allSightings.count, longestStreak: longestStreak)
            GameCenterService.shared.reportAchievements(allAchievements)

            importedShareCount = count

            // Auto-hide after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            importedShareCount = nil
        }

        PendingSightingService.setHasPendingItems(false)
    }

    private func checkForOrphanedSightings() async {
        let descriptor = FetchDescriptor<Sighting>(
            predicate: #Predicate { $0.sourceIdentifier != nil }
        )
        guard let sightings = try? modelContext.fetch(descriptor),
              !sightings.isEmpty else { return }

        var identifierMap: [String: [Sighting]] = [:]
        for sighting in sightings {
            guard let id = sighting.sourceIdentifier else { continue }
            identifierMap[id, default: []].append(sighting)
        }
        let allIdentifiers = Array(identifierMap.keys)
        let missing = PhotoLibraryImageService.shared.findMissingIdentifiers(from: allIdentifiers)

        guard !missing.isEmpty else { return }
        orphanedSightings = missing.flatMap { identifierMap[$0] ?? [] }
        if selectedTab != .capture {
            showOrphanAlert = true
        }
    }

    private func deleteOrphanedSightings() {
        for sighting in orphanedSightings {
            try? ImageStorageService.shared.deleteImages(for: sighting.id)
            let jsonName = sighting.imageFileName.replacingOccurrences(of: "_full.jpg", with: "_detection.json")
            let cacheURL = ImageStorageService.shared.thumbnailURL(for: jsonName)
            try? FileManager.default.removeItem(at: cacheURL)
            modelContext.delete(sighting)
        }
        try? modelContext.save()
        orphanedSightings = []

        Task {
            await refreshWidgetData()
        }
    }

    private func importBanner(count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down.fill")
            Text("The Oracle hath received \(count.pluralized("vision")).")
        }
        .font(.subheadline.bold())
        .foregroundColor(.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.goldDark, in: Capsule())
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring, value: importedShareCount)
    }
}

#Preview {
    ContentView(selectedTab: .constant(.capture))
}
