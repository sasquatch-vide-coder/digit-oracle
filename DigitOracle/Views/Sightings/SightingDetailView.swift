import SwiftUI
import SwiftData
import MapKit

struct SightingDetailView: View {
    @Bindable var sighting: Sighting
    @Query(sort: \Album.name) private var allAlbums: [Album]
    @State private var showingAlbumPicker = false
    @State private var showingEditor = false
    @State private var showingFullScreenImage = false
    @State private var showHighlights = true
    @State private var detectedRects: [CGRect] = []
    @State private var isDetecting = true
    @State private var isRescanning = false
    @State private var fullImage: UIImage?
    @State private var isLoadingImage = true
    @State private var imageUnavailable = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                metadataSection
                matchCountsSection
                albumsSection
                locationSection
                tagsSection
            }
            .padding()
        }
        .background(Color.backgroundPrimary)
        .navigationTitle("Vision")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    Button {
                        showingAlbumPicker = true
                    } label: {
                        Image(systemName: "rectangle.stack.badge.plus")
                    }
                    Button {
                        sighting.isFavorite.toggle()
                    } label: {
                        Image(systemName: sighting.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(sighting.isFavorite ? .red : .secondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .sensoryFeedback(.selection, trigger: sighting.isFavorite)
                }
            }
        }
        .sheet(isPresented: $showingAlbumPicker) {
            AlbumPickerView(sighting: sighting, allAlbums: allAlbums)
        }
        .sheet(isPresented: $showingEditor) {
            SightingEditView(sighting: sighting)
        }
    }

    // MARK: - Image Section

    private var imageSection: some View {
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
            } else if imageUnavailable, let thumbName = sighting.thumbnailFileName,
                      let thumb = ImageStorageService.shared.loadImage(fileName: thumbName) {
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

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                rarityBadge

                if sighting.containsTrackedNumber {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption.bold())
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.successGreen, in: Capsule())
                }

                Spacer()

                Text(sighting.captureDate.formatted(date: .numeric, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !sighting.notes.isEmpty {
                Text(sighting.notes)
                    .font(.body)
            }

            if let category = sighting.category {
                Label(category.capitalized, systemImage: categoryIcon(for: category))
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }

        }
    }

    // MARK: - Rescan

    private func rescanSighting() async {
        let image: UIImage?
        if sighting.hasLocalFullImage {
            image = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName)
        } else if let identifier = sighting.sourceIdentifier {
            image = await PhotoLibraryImageService.shared.loadFullImage(identifier: identifier)
        } else {
            image = nil
        }
        guard let image else { return }
        isRescanning = true
        let detection = await OCRService.shared.detect(in: image)
        OCRService.shared.saveDetection(detection, for: sighting.imageFileName)
        sighting.contains47 = detection.ocr.matchedNumbers.contains(47)
        sighting.matchedNumbers = detection.ocr.matchedNumbers
        sighting.matchCounts = detection.ocr.matchCounts
        sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)
        detectedRects = detection.locationRects
        isRescanning = false
    }

    // MARK: - Match Counts Section

    @ViewBuilder
    private var matchCountsSection: some View {
        let counts = sighting.matchCounts
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Matches")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await rescanSighting() }
                } label: {
                    if isRescanning {
                        ProgressView()
                    } else {
                        Label("Rescan", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                }
                .disabled(isRescanning)
            }

            if !counts.isEmpty {
                FlowLayout(spacing: 10) {
                    ForEach(counts.sorted(by: { $0.key < $1.key }), id: \.key) { number, count in
                        HStack(spacing: 6) {
                            Text(number)
                                .font(.subheadline.bold().monospacedDigit())
                            Text("×")
                                .font(.caption)
                            Text("\(count)")
                                .font(.subheadline.bold().monospacedDigit())
                        }
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.goldDark, in: Capsule())
                    }
                }
            } else if !isRescanning {
                Text("No matches found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Location Section

    @ViewBuilder
    private var locationSection: some View {
        if let coordinate = sighting.coordinate {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(.headline)

                if let name = sighting.locationName {
                    Label(name, systemImage: "mappin")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    HeatmapView(focusCoordinate: coordinate, focusSightingID: sighting.id)
                } label: {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker("Vision", coordinate: coordinate)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
                    .overlay(alignment: .bottomTrailing) {
                        Text("View Full Map")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.black.opacity(0.5), in: Capsule())
                            .padding(8)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private var tagsSection: some View {
        if !sighting.tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)

                FlowLayout(spacing: 8) {
                    ForEach(sighting.tags) { tag in
                        Text(tag.name)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Albums Section

    @ViewBuilder
    private var albumsSection: some View {
        if !sighting.albums.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Albums")
                    .font(.headline)
                FlowLayout(spacing: 8) {
                    ForEach(sighting.albums) { album in
                        Label(album.name, systemImage: "rectangle.stack.fill")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.thinMaterial, in: Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var rarityBadge: some View {
        Text(OracleTextService.tierLabel(for: sighting.rarityScore))
            .font(.oracleBody(size: 14))
            .illuminatedText(tier: sighting.rarityScore)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.backgroundSecondary)
            .rarityBorder(score: sighting.rarityScore)
    }

    private var rarityColor: Color {
        Color.rarityColor(for: sighting.rarityScore)
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "printed": "book.fill"
        case "digital": "desktopcomputer"
        case "natural": "leaf.fill"
        case "handwritten": "pencil"
        case "architectural": "building.2.fill"
        case "serendipitous": "sparkles"
        default: "tag.fill"
        }
    }
}

// MARK: - Full Screen Image Viewer

struct FullScreenImageView: View {
    let image: UIImage
    let detectedRects: [CGRect]
    @Binding var showHighlights: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var committedScale: CGFloat = 1.0
    @State private var committedOffset: CGSize = .zero
    @GestureState private var zoomState = ZoomState()
    @GestureState private var dragTranslation: CGSize = .zero

    private struct ZoomState: Equatable {
        var scale: CGFloat = 1.0
        var anchorOffset: CGSize = .zero
    }

    private var currentScale: CGFloat {
        committedScale * zoomState.scale
    }

    private var currentOffset: CGSize {
        CGSize(
            width: committedOffset.width + dragTranslation.width + zoomState.anchorOffset.width,
            height: committedOffset.height + dragTranslation.height + zoomState.anchorOffset.height
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let viewSize = geometry.size

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        if showHighlights && !detectedRects.isEmpty {
                            ImageHighlightOverlay(rects: detectedRects, imageSize: image.size)
                        }
                    }
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .frame(width: viewSize.width, height: viewSize.height)
                    .contentShape(Rectangle())
                    .gesture(
                        MagnifyGesture()
                            .updating($zoomState) { value, state, _ in
                                let mag = value.magnification
                                let anchor = value.startAnchor
                                let dx = (anchor.x - 0.5) * viewSize.width
                                let dy = (anchor.y - 0.5) * viewSize.height
                                state = ZoomState(
                                    scale: mag,
                                    anchorOffset: CGSize(
                                        width: dx * committedScale * (1 - mag),
                                        height: dy * committedScale * (1 - mag)
                                    )
                                )
                            }
                            .onEnded { value in
                                let mag = value.magnification
                                let anchor = value.startAnchor
                                let dx = (anchor.x - 0.5) * viewSize.width
                                let dy = (anchor.y - 0.5) * viewSize.height
                                committedOffset = CGSize(
                                    width: committedOffset.width + dx * committedScale * (1 - mag),
                                    height: committedOffset.height + dy * committedScale * (1 - mag)
                                )
                                committedScale *= mag
                                if committedScale < 1.0 {
                                    withAnimation(.spring(duration: 0.3)) {
                                        committedScale = 1.0
                                        committedOffset = .zero
                                    }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .updating($dragTranslation) { value, state, _ in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        committedOffset = CGSize(
                                            width: committedOffset.width + value.translation.width,
                                            height: committedOffset.height + value.translation.height
                                        )
                                        if committedScale <= 1.0 {
                                            withAnimation(.spring(duration: 0.3)) {
                                                committedOffset = .zero
                                            }
                                        }
                                    }
                            )
                    )
                    .gesture(
                        SpatialTapGesture(count: 2)
                            .onEnded { value in
                                withAnimation(.spring(duration: 0.3)) {
                                    if committedScale > 1.0 {
                                        committedScale = 1.0
                                        committedOffset = .zero
                                    } else {
                                        let targetScale: CGFloat = 3.0
                                        let dx = value.location.x - viewSize.width / 2
                                        let dy = value.location.y - viewSize.height / 2
                                        let magnification = targetScale / committedScale
                                        committedOffset = CGSize(
                                            width: dx * committedScale * (1 - magnification),
                                            height: dy * committedScale * (1 - magnification)
                                        )
                                        committedScale = targetScale
                                    }
                                }
                            }
                    )
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showHighlights.toggle()
                        }
                    } label: {
                        Image(systemName: showHighlights ? "eye" : "eye.slash")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Image Highlight Overlay

struct ImageHighlightOverlay: View {
    let rects: [CGRect]
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ForEach(Array(rects.enumerated()), id: \.offset) { _, rect in
                let center = rectCenter(rect, in: size)
                let diameter = circleDiameter(rect, in: size)
                Circle()
                    .stroke(Color.goldPrimary, lineWidth: 2.5)
                    .background(
                        Circle()
                            .fill(Color.goldPrimary.opacity(0.1))
                    )
                    .frame(width: diameter, height: diameter)
                    .position(x: center.x, y: center.y)
            }
        }
        .allowsHitTesting(false)
    }

    /// Returns the screen-space center point of a Vision normalized rect.
    private func rectCenter(_ rect: CGRect, in viewSize: CGSize) -> CGPoint {
        let centerX = (rect.origin.x + rect.width / 2) * viewSize.width
        let centerY = (1 - rect.origin.y - rect.height / 2) * viewSize.height
        return CGPoint(x: centerX, y: centerY)
    }

    /// Returns the circle diameter to comfortably surround the "47" text.
    private func circleDiameter(_ rect: CGRect, in viewSize: CGSize) -> CGFloat {
        let width = rect.width * viewSize.width
        let height = rect.height * viewSize.height
        return max(width, height) * 2.0
    }
}

// MARK: - Album Picker

struct AlbumPickerView: View {
    @Bindable var sighting: Sighting
    let allAlbums: [Album]
    @Environment(\.dismiss) private var dismiss

    private var sightingAlbumIDs: Set<UUID> {
        Set(sighting.albums.map(\.id))
    }

    var body: some View {
        NavigationStack {
            Group {
                if allAlbums.isEmpty {
                    ContentUnavailableView(
                        "No Albums",
                        systemImage: "rectangle.stack",
                        description: Text("Create an album first from the Albums tab.")
                    )
                } else {
                    List(allAlbums) { album in
                        let isMember = sightingAlbumIDs.contains(album.id)
                        Button {
                            if isMember {
                                sighting.albums.removeAll { $0.id == album.id }
                            } else {
                                sighting.albums.append(album)
                            }
                        } label: {
                            HStack {
                                Label(album.name, systemImage: "rectangle.stack.fill")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isMember {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .bold()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Albums")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }
}

// MARK: - Flow Layout (for tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions)
    }
}
