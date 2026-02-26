import SwiftUI
import SwiftData
import WidgetKit

struct LibraryScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var scanner = LibraryScannerService()
    @State private var selectedIDs: Set<String> = []
    @State private var isImporting = false
    @State private var importedCount: Int?
    @State private var achievementEngine = AchievementEngine()
    @State private var importedIdentifiers: Set<String> = []
    @State private var isFullRescan = false

    var body: some View {
        NavigationStack {
            Group {
                switch scanner.state {
                case .idle:
                    preScanView
                case .scanning:
                    scanningView
                case .completed, .cancelled:
                    resultsView
                }
            }
            .navigationTitle("Scan Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        scanner.cancel()
                        dismiss()
                    }
                }
            }
            .alert("Import Complete", isPresented: .init(
                get: { importedCount != nil },
                set: { if !$0 { importedCount = nil } }
            )) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                if let count = importedCount {
                    Text("Imported \(count) sighting\(count == 1 ? "" : "s").")
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

            Text("Find Numbers in Your Photos")
                .font(.title2.bold())

            Text("Scan your photo library to discover existing photos that contain your tracked numbers.")
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
                Label(scanner.lastScanDate != nil ? "Scan New Photos" : "Scan Library", systemImage: "magnifyingglass")
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
                    Text("Rescan Entire Library")
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
                    Label(isFullRescan ? "Scanning entire library..." : "Scanning new photos...", systemImage: "text.magnifyingglass")
                } description: {
                    Text("Looking for numbers in your photos")
                }
                .frame(maxHeight: .infinity)
            } else {
                matchesGrid
            }
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 0) {
            if scanner.matches.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "photo.badge.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No Numbers Found")
                        .font(.title2.bold())
                    Text("None of your photos contained your tracked numbers. Try capturing some with the camera!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                resultsHeader
                matchesGrid
                importBar
            }
        }
    }

    // MARK: - Components

    private var progressHeader: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(scanner.scannedCount), total: max(Double(scanner.totalCount), 1))
                .tint(.accentColor)

            HStack {
                Text("\(scanner.scannedCount) / \(scanner.totalCount) photos scanned")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(scanner.matches.count) match\(scanner.matches.count == 1 ? "" : "es")")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
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

    private var resultsHeader: some View {
        HStack {
            Text("\(scanner.matches.count) photo\(scanner.matches.count == 1 ? "" : "s") with matches")
                .font(.headline)
            Spacer()
            Button(selectedIDs.count == scanner.matches.count ? "Deselect All" : "Select All") {
                if selectedIDs.count == scanner.matches.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(scanner.matches.map(\.id))
                }
            }
            .font(.subheadline)
        }
        .padding()
    }

    private var matchesGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(scanner.matches) { result in
                    ScanResultCard(
                        result: result,
                        isSelected: selectedIDs.contains(result.id),
                        onToggle: { toggleSelection(result.id) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private var importBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                Button {
                    Task { await importSelected() }
                } label: {
                    if isImporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Import \(selectedIDs.isEmpty ? "All" : "Selected") (\(selectedIDs.isEmpty ? scanner.matches.count : selectedIDs.count))")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
            }
            .padding()
            .background(.bar)
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
            scanner.errorMessage = "Photo library access is required to scan."
            return
        }

        // Load already-imported asset identifiers to skip duplicates
        let descriptor = FetchDescriptor<Sighting>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        importedIdentifiers = Set(existing.compactMap(\.sourceIdentifier))

        scanner.startScan(excludingIdentifiers: importedIdentifiers, sinceDate: isFullRescan ? nil : scanner.lastScanDate)
    }

    private func toggleSelection(_ id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func importSelected() async {
        isImporting = true
        let toImport: [LibraryScanResult]
        if selectedIDs.isEmpty {
            toImport = scanner.matches
        } else {
            toImport = scanner.matches.filter { selectedIDs.contains($0.id) }
        }

        // Fetch existing source identifiers to skip duplicates at import time
        let existingDescriptor = FetchDescriptor<Sighting>()
        let existingSightings = (try? modelContext.fetch(existingDescriptor)) ?? []
        let alreadyImported = Set(existingSightings.compactMap(\.sourceIdentifier))

        var count = 0
        let ownerID = Constants.defaultOwnerID

        for result in toImport {
            // Skip if this asset was already imported
            if alreadyImported.contains(result.id) { continue }

            guard let fullImage = await scanner.loadFullImage(for: result) else { continue }

            let sightingID = UUID()
            do {
                let fileNames = try ImageStorageService.shared.saveImage(fullImage, id: sightingID)

                let sighting = Sighting(
                    ownerUserID: ownerID,
                    imageFileName: fileNames.full,
                    captureDate: result.creationDate ?? .now,
                    sourceType: "library_scan",
                    latitude: result.asset.location?.coordinate.latitude,
                    longitude: result.asset.location?.coordinate.longitude
                )
                sighting.thumbnailFileName = fileNames.thumbnail
                sighting.contains47 = result.ocrResult.matchedNumbers.contains(47)
                sighting.matchedNumbers = result.ocrResult.matchedNumbers
                sighting.matchCounts = result.ocrResult.matchCounts
                sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)
                sighting.sourceIdentifier = result.id

                modelContext.insert(sighting)
                count += 1
            } catch {
                continue
            }
        }

        if count > 0 {
            try? modelContext.save()

            let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
            WidgetDataService.update(from: allSightings)
            WidgetCenter.shared.reloadAllTimelines()

            achievementEngine.checkAll(context: modelContext)
        }

        isImporting = false
        importedCount = count
    }
}
