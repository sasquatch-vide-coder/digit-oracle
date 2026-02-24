import SwiftUI
import SwiftData
import WidgetKit

struct PhotoReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let image: UIImage
    let sourceType: String

    @State private var notes = ""
    @State private var selectedCategory: SightingCategory?
    @State private var rarityScore = 1
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

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imagePreview
                statusBanners
                MetadataFormView(
                    notes: $notes,
                    selectedCategory: $selectedCategory,
                    rarityScore: $rarityScore,
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
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 4)

            if let ocrResult, ocrResult.contains47 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("47 detected!")
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
                    Text("Scanning for 47...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let ocrResult {
                    if ocrResult.contains47 {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("Found \(ocrResult.matchCount) occurrence\(ocrResult.matchCount == 1 ? "" : "s") of 47")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "text.magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(ocrResult.fullText != nil ? "Text found, but no 47 detected" : "No text detected in image")
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
        let result = await OCRService.shared.detectText(in: image)
        ocrResult = result
        isScanning = false
    }

    private func saveSighting() async {
        isSaving = true

        let sightingID = UUID()
        let ownerID = Constants.defaultOwnerID

        do {
            let fileNames = try ImageStorageService.shared.saveImage(image, id: sightingID)

            let sighting = Sighting(
                ownerUserID: ownerID,
                imageFileName: fileNames.full,
                captureDate: .now,
                notes: notes,
                sourceType: sourceType,
                category: selectedCategory?.rawValue,
                rarityScore: rarityScore,
                latitude: locationService.lastLocation?.coordinate.latitude,
                longitude: locationService.lastLocation?.coordinate.longitude
            )
            sighting.thumbnailFileName = fileNames.thumbnail
            sighting.locationName = locationText
            sighting.detectedText = ocrResult?.fullText
            sighting.contains47 = ocrResult?.contains47 ?? false

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
}
