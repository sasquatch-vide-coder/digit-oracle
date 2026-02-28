import SwiftUI
import SwiftData
import WidgetKit

struct PhotoReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let sourceType: String
    var assetIdentifier: String? = nil

    @State private var notes = ""
    @State private var selectedCategory: SightingCategory?
    @State private var newTagName = ""
    @State private var tagNames: [String] = []
    @State private var isSaving = false
    @State private var locationService = LocationService()
    @State private var locationText: String?
    @State private var isFetchingLocation = true
    @State private var ocrResult: OCRResult?
    @State private var isScanning = true
    @State private var selectedAlbumIDs: Set<UUID> = []
    @State private var achievementEngine = AchievementEngine()
    @State private var challengeEngine = ChallengeEngine()
    @State private var celebratingAchievement: Achievement?
    @State private var completedChallenge: Challenge?
    @State private var saveCompleted = false
    @State private var detectedRects: [CGRect] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imagePreview
                statusBanners
                MetadataFormView(
                    notes: $notes,
                    selectedCategory: $selectedCategory,
                    newTagName: $newTagName,
                    tagNames: $tagNames,
                    selectedAlbumIDs: $selectedAlbumIDs
                )
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await saveSighting() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save").bold()
                    }
                }
                .disabled(isSaving)
            }
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await fetchLocation() }
                group.addTask { await runOCR() }
            }
        }
        .overlay {
            if let achievement = celebratingAchievement {
                AchievementCelebrationView(achievement: achievement) {
                    celebratingAchievement = nil
                    if let challenge = challengeEngine.completedChallenge {
                        completedChallenge = challenge
                    } else {
                        dismiss()
                    }
                }
            } else if let challenge = completedChallenge {
                ChallengeCelebrationView(challenge: challenge) {
                    completedChallenge = nil
                    dismiss()
                }
            }
        }
        .sensoryFeedback(.success, trigger: saveCompleted)
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay {
                    if !detectedRects.isEmpty {
                        ImageHighlightOverlay(rects: detectedRects, imageSize: image.size)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)

            if let ocrResult, ocrResult.containsTrackedNumber {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text(matchedNumbersLabel(ocrResult.matchedNumbers) + " detected!")
                }
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.green, in: Capsule())
                .padding(8)
            }
        }
    }

    // MARK: - Status Banners

    private var statusBanners: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                if isFetchingLocation {
                    ProgressView()
                        .controlSize(.small)
                    Text("Getting location...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let locationText {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundStyle(.red)
                    Text(locationText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "location.slash")
                        .foregroundStyle(.secondary)
                    Text("No location available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                if isScanning {
                    ProgressView()
                        .controlSize(.small)
                    Text("Scanning for numbers...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let ocrResult {
                    if ocrResult.containsTrackedNumber {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Found \(ocrResult.matchCount) match\(ocrResult.matchCount == 1 ? "" : "es")")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "text.magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(ocrResult.fullText != nil ? "Text found, but no tracked numbers detected" : "No text detected in image")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut, value: isFetchingLocation)
        .animation(.easeInOut, value: isScanning)
    }

    // MARK: - Actions

    private func fetchLocation() async {
        locationService.requestPermission()
        try? await Task.sleep(for: .milliseconds(500))

        if let result = await locationService.requestLocationWithName() {
            locationText = result.name
        }
        isFetchingLocation = false
    }

    private func runOCR() async {
        let detection = await OCRService.shared.detect(in: image)
        ocrResult = detection.ocr
        isScanning = false
        detectedRects = detection.locationRects
    }

    private func saveSighting() async {
        isSaving = true

        let sightingID = UUID()
        let ownerID = Constants.defaultOwnerID

        do {
            let imageFileName: String
            let thumbFileName: String
            var hasLocalFull = true
            var resolvedSourceIdentifier = assetIdentifier

            if sourceType == "camera" {
                // Camera: try saving to Photo Library, fall back to full on-disk copy
                do {
                    let phID = try await PhotoLibraryImageService.shared.saveToPhotoLibrary(image)
                    resolvedSourceIdentifier = phID
                    thumbFileName = try ImageStorageService.shared.saveThumbnailOnly(image, id: sightingID)
                    imageFileName = "\(sightingID.uuidString)\(Constants.ImageStorage.fullSuffix).jpg"
                    hasLocalFull = false
                } catch {
                    let fileNames = try ImageStorageService.shared.saveImage(image, id: sightingID)
                    imageFileName = fileNames.full
                    thumbFileName = fileNames.thumbnail
                    hasLocalFull = true
                }
            } else if sourceType == "library", assetIdentifier != nil {
                // Library pick: asset already in Photo Library
                thumbFileName = try ImageStorageService.shared.saveThumbnailOnly(image, id: sightingID)
                imageFileName = "\(sightingID.uuidString)\(Constants.ImageStorage.fullSuffix).jpg"
                hasLocalFull = false
            } else {
                // Fallback: full save
                let fileNames = try ImageStorageService.shared.saveImage(image, id: sightingID)
                imageFileName = fileNames.full
                thumbFileName = fileNames.thumbnail
            }

            // Run OCR on in-memory image and cache
            let savedOCR: OCRResult
            let detection = await OCRService.shared.detect(in: image)
            OCRService.shared.saveDetection(detection, for: imageFileName)
            savedOCR = detection.ocr

            let sighting = Sighting(
                ownerUserID: ownerID,
                imageFileName: imageFileName,
                captureDate: .now,
                notes: notes,
                sourceType: sourceType,
                category: selectedCategory?.rawValue,
                latitude: locationService.lastLocation?.coordinate.latitude,
                longitude: locationService.lastLocation?.coordinate.longitude
            )
            sighting.thumbnailFileName = thumbFileName
            sighting.hasLocalFullImage = hasLocalFull
            sighting.sourceIdentifier = resolvedSourceIdentifier
            sighting.imageHash = ImageStorageService.perceptualHash(of: image)
            sighting.locationName = locationText
            sighting.contains47 = savedOCR.matchedNumbers.contains(47)
            sighting.matchedNumbers = savedOCR.matchedNumbers
            sighting.matchCounts = savedOCR.matchCounts
            sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)

            for tagName in tagNames {
                let tag = Tag(name: tagName)
                modelContext.insert(tag)
                sighting.tags.append(tag)
            }

            // Attach to selected albums
            if !selectedAlbumIDs.isEmpty {
                let descriptor = FetchDescriptor<Album>()
                let allAlbums = (try? modelContext.fetch(descriptor)) ?? []
                for album in allAlbums where selectedAlbumIDs.contains(album.id) {
                    sighting.albums.append(album)
                }
            }

            modelContext.insert(sighting)
            try modelContext.save()

            // Update widget data
            let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
            WidgetDataService.update(from: allSightings)
            WidgetCenter.shared.reloadAllTimelines()

            // Check achievements and challenges
            achievementEngine.checkAll(context: modelContext)
            challengeEngine.checkCompletion(sighting: sighting, context: modelContext)

            saveCompleted.toggle()

            if let first = achievementEngine.recentlyUnlocked.first {
                celebratingAchievement = first
            } else if let challenge = challengeEngine.completedChallenge {
                completedChallenge = challenge
            } else {
                dismiss()
            }
        } catch {
            isSaving = false
        }
    }

    private func matchedNumbersLabel(_ numbers: [Int]) -> String {
        if numbers.isEmpty { return "Numbers" }
        return numbers.map(String.init).joined(separator: ", ")
    }
}
