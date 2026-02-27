import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    @Binding var selectedTab: AppTab
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @State private var importedShareCount: Int?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Capture", systemImage: "camera.fill", value: .capture) {
                NavigationStack {
                    CaptureView()
                }
            }

            Tab("Sightings", systemImage: "eye", value: .sightings) {
                NavigationStack {
                    SightingListView()
                }
            }

            Tab("Albums", systemImage: "rectangle.stack.fill", value: .albums) {
                NavigationStack {
                    AlbumListView()
                }
            }

            Tab("Profile", systemImage: "person.fill", value: .profile) {
                NavigationStack {
                    StatsOverviewView()
                }
            }
        }
        .tint(.accentColor)
        .task {
            await refreshWidgetData()
            await importPendingShares()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await importPendingShares() }
            }
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

        var count = 0
        for item in pending {
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
            sighting.imageHash = ImageStorageService.perceptualHash(of: item.image)
            sighting.contains47 = ocrResult.matchedNumbers.contains(47)
            sighting.matchedNumbers = ocrResult.matchedNumbers
            sighting.matchCounts = ocrResult.matchCounts
            sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)

            modelContext.insert(sighting)
            try? PendingSightingService.deletePendingItem(id: item.metadata.id)
            count += 1
        }

        if count > 0 {
            try? modelContext.save()
            await refreshWidgetData()
            importedShareCount = count

            // Auto-hide after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            importedShareCount = nil
        }

        PendingSightingService.setHasPendingItems(false)
    }

    private func importBanner(count: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down.fill")
            Text("Imported \(count) sighting\(count == 1 ? "" : "s") from share")
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.green, in: Capsule())
        .padding(.top, 8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring, value: importedShareCount)
    }
}

#Preview {
    ContentView(selectedTab: .constant(.capture))
}
