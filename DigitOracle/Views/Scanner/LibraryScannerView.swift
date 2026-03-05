import SwiftUI
import SwiftData
import WidgetKit

struct LibraryScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scanner = LibraryScannerService()
    @State private var achievementEngine = AchievementEngine()
    @State private var importedIdentifiers: Set<String> = []
    @State private var importedHashes: [String] = []
    @State private var isFullRescan = false
    @State private var savedCount = 0
    @State private var unsavedCount = 0

    var autoStart = false

    var body: some View {
        NavigationStack {
            Group {
                switch scanner.state {
                case .idle:
                    preScanView
                case .scanning:
                    scanningView
                case .completed, .cancelled:
                    completedView
                }
            }
            .navigationTitle("Peer into the Archive")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        scanner.cancel()
                        finalizeScan()
                        dismiss()
                    }
                }
            }
            .task {
                if autoStart && scanner.state == .idle {
                    await startScan()
                }
            }
        }
    }

    // MARK: - Pre-scan

    private var preScanView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Let the Oracle Peer into Thy Archive")
                .font(.title2.bold())

            Text("The Oracle shall examine all thy captured visions for signs of the sacred numbers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let lastDate = scanner.lastScanDate {
                Text("Last scanned: \(lastDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button {
                isFullRescan = false
                Task { await startScan() }
            } label: {
                Label(scanner.lastScanDate != nil ? "Seek New Visions" : "Begin the Search", systemImage: "magnifyingglass")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            if scanner.lastScanDate != nil {
                Button {
                    isFullRescan = true
                    scanner.resetLastScanDate()
                    Task { await startScan() }
                } label: {
                    Text("Reexamine All Visions")
                        .font(.subheadline)
                }
            }

            Spacer()
        }
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 16) {
            progressHeader

            if scanner.matches.isEmpty {
                ContentUnavailableView {
                    Label(isFullRescan ? "The Oracle examines all visions..." : "The Oracle seeks new visions...", systemImage: "text.magnifyingglass")
                } description: {
                    Text("Searching for the sacred numbers within thy visions")
                }
                .frame(maxHeight: .infinity)
            } else {
                matchesGrid
            }
        }
    }

    // MARK: - Completed

    private var completedView: some View {
        Group {
            if scanner.matches.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "photo.badge.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No Signs Found")
                        .font(.title2.bold())
                    Text("Thy visions hold no signs of the sacred numbers. Seek them through the Oracle's eye!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.successGreen)

                        Text("\(savedCount.pluralized("vision")) saved")
                            .font(.headline)
                    }
                    .padding()

                    matchesGrid

                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .onAppear {
                    finalizeScan()
                }
            }
        }
    }

    // MARK: - Components

    private var progressHeader: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(scanner.scannedCount), total: max(Double(scanner.totalCount), 1))
                .tint(.accentColor)

            HStack {
                Text("\(scanner.scannedCount) / \(scanner.totalCount) visions examined")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(savedCount) saved")
                    .font(.caption.bold())
                    .foregroundStyle(Color.goldPrimary)
            }

            if let startDate = scanner.scanStartDate {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let elapsed = context.date.timeIntervalSince(startDate)
                    HStack {
                        Text("\(formattedDuration(elapsed)) elapsed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if scanner.scannedCount >= 5, scanner.scannedCount < scanner.totalCount {
                            let perPhoto = elapsed / Double(scanner.scannedCount)
                            let remaining = perPhoto * Double(scanner.totalCount - scanner.scannedCount)
                            Text("~\(formattedDuration(remaining)) remaining")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button("Stop", role: .cancel) {
                scanner.cancel()
            }
            .font(.subheadline)
        }
        .padding()
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private var matchesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(scanner.matches) { result in
                    ScanResultCard(result: result)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func startScan() async {
        let hasAccess: Bool
        switch scanner.authorizationStatus {
        case .authorized, .limited:
            hasAccess = true
        case .notDetermined:
            hasAccess = await scanner.requestAccess()
        default:
            hasAccess = false
        }

        guard hasAccess else {
            scanner.errorMessage = "The Oracle requires access to thy archive."
            return
        }

        // Load already-imported asset identifiers and image hashes to skip duplicates
        let descriptor = FetchDescriptor<Sighting>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        importedIdentifiers = Set(existing.compactMap(\.sourceIdentifier))
        importedHashes = existing.compactMap(\.imageHash)

        savedCount = 0
        unsavedCount = 0

        // Wire up auto-save callback
        scanner.onMatch = { result in
            saveSighting(from: result)
        }

        scanner.startScan(excludingIdentifiers: importedIdentifiers, excludingHashes: importedHashes, sinceDate: isFullRescan ? nil : scanner.lastScanDate)
    }

    private func saveSighting(from result: LibraryScanResult) {
        // Safety-net duplicate check: sourceIdentifier
        if importedIdentifiers.contains(result.id) { return }
        // Safety-net duplicate check: perceptual hash
        if let newHash = result.hash,
           importedHashes.contains(where: { ImageStorageService.isPerceptualDuplicate($0, newHash) }) {
            return
        }
        // Also check SwiftData for anything saved since scan started
        let allExisting = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        if allExisting.contains(where: { $0.sourceIdentifier == result.id }) { return }
        if let newHash = result.hash,
           allExisting.contains(where: {
               guard let h = $0.imageHash else { return false }
               return ImageStorageService.isPerceptualDuplicate(h, newHash)
           }) { return }

        let sightingID = UUID()
        let ownerID = Constants.defaultOwnerID

        do {
            let thumbFileName = try ImageStorageService.shared.saveThumbnailOnly(result.scanImage, id: sightingID)
            let syntheticFullName = "\(sightingID.uuidString)\(Constants.ImageStorage.fullSuffix).jpg"

            OCRService.shared.saveDetection(result.detection, for: syntheticFullName)
            let ocrResult = result.detection.ocr

            let sighting = Sighting(
                ownerUserID: ownerID,
                imageFileName: syntheticFullName,
                captureDate: result.creationDate ?? .now,
                sourceType: "library_scan",
                latitude: result.asset.location?.coordinate.latitude,
                longitude: result.asset.location?.coordinate.longitude
            )
            sighting.thumbnailFileName = thumbFileName
            sighting.hasLocalFullImage = false
            sighting.imageHash = result.hash
            sighting.contains47 = ocrResult.matchedNumbers.contains(47)
            sighting.matchedNumbers = ocrResult.matchedNumbers
            sighting.matchCounts = ocrResult.matchCounts
            sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)
            sighting.sourceIdentifier = result.id
            sighting.detectedText = ocrResult.fullText

            modelContext.insert(sighting)
            savedCount += 1
            unsavedCount += 1

            // Accumulate within-session dedup state
            importedIdentifiers.insert(result.id)
            if let hash = result.hash { importedHashes.append(hash) }

            // Batch save every 20 sightings
            if unsavedCount >= 20 {
                try? modelContext.save()
                unsavedCount = 0
            }
        } catch {
            // thumbnail save failed, skip this sighting
        }
    }

    private func finalizeScan() {
        guard savedCount > 0 else { return }

        try? modelContext.save()
        unsavedCount = 0

        let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        WidgetDataService.update(from: allSightings)
        WidgetCenter.shared.reloadAllTimelines()

        achievementEngine.checkAll(context: modelContext)

        // Report to Game Center
        let allAchievements = (try? modelContext.fetch(FetchDescriptor<Achievement>())) ?? []
        let longestStreak = StatsCalculator.longestStreak(from: allSightings)
        GameCenterService.shared.submitScores(totalSightings: allSightings.count, longestStreak: longestStreak)
        GameCenterService.shared.reportAchievements(allAchievements)
    }
}
