import SwiftUI

struct SightingImageSection: View {
    let sighting: Sighting
    @Binding var showHighlights: Bool
    var rescanID: UUID
    var onImageLoaded: ((UIImage?) -> Void)?

    @State private var fullImage: UIImage?
    @State private var detectedRects: [CGRect] = []
    @State private var isDetecting = true
    @State private var isLoadingImage = true
    @State private var imageUnavailable = false
    @State private var showingFullScreenImage = false

    private var rarityColor: Color {
        Color.rarityColor(for: sighting.rarityScore)
    }

    var body: some View {
        Group {
            if isLoadingImage {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .frame(height: 300)
                    .overlay { ProgressView() }
            } else if let image = fullImage {
                ZStack(alignment: .bottomTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .overlay {
                            if showHighlights && !detectedRects.isEmpty {
                                ImageHighlightOverlay(rects: detectedRects, imageSize: image.size)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture { showingFullScreenImage = true }

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showHighlights.toggle()
                        }
                    } label: {
                        Group {
                            if isDetecting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: showHighlights ? "eye" : "eye.slash")
                            }
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.5), in: Circle())
                    }
                    .padding(10)
                }
                .fullScreenCover(isPresented: $showingFullScreenImage) {
                    FullScreenImageView(
                        image: image,
                        detectedRects: detectedRects,
                        showHighlights: $showHighlights
                    )
                }
            } else if imageUnavailable, let thumb = sighting.loadBestImage() {
                ZStack {
                    Image(uiImage: thumb)
                        .resizable()
                        .scaledToFit()
                        .blur(radius: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Text("Photo no longer available")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.6), in: Capsule())
                }
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(rarityColor.opacity(0.15))
                    .frame(height: 300)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("\(TrackedNumberService.shared.primaryNumber)")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundStyle(rarityColor)
                            Text("No image available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
        .task {
            await loadFullImage()
        }
        .onChange(of: fullImage) { _, newImage in
            guard let newImage else { return }
            Task { await loadDetection(for: newImage) }
        }
        .onChange(of: rescanID) {
            if let image = fullImage {
                Task { await loadDetection(for: image) }
            }
        }
    }

    private func loadFullImage() async {
        if sighting.hasLocalFullImage {
            fullImage = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName)
            if fullImage == nil {
                imageUnavailable = true
            }
        } else if let identifier = sighting.sourceIdentifier {
            fullImage = await PhotoLibraryImageService.shared.loadFullImage(identifier: identifier)
            if fullImage == nil {
                imageUnavailable = true
            }
        } else {
            imageUnavailable = true
        }
        isLoadingImage = false
        onImageLoaded?(fullImage)
    }

    private func loadDetection(for image: UIImage) async {
        if let cached = OCRService.shared.loadDetection(for: sighting.imageFileName) {
            detectedRects = cached.locationRects
        } else {
            let detection = await OCRService.shared.detect(in: image)
            OCRService.shared.saveDetection(detection, for: sighting.imageFileName)
            detectedRects = detection.locationRects
        }
        isDetecting = false
    }
}
