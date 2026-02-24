import SwiftUI
import SwiftData
import MapKit

struct SightingDetailView: View {
    @Bindable var sighting: Sighting
    @Query(sort: \Album.name) private var allAlbums: [Album]
    @State private var showingAlbumPicker = false
    @State private var showingEditor = false
    @State private var showingFullScreenImage = false
    @State private var showHighlights = false
    @State private var detectedRects: [CGRect] = []
    @State private var isDetecting = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                imageSection
                metadataSection
                albumsSection
                locationSection
                ocrSection
                tagsSection
            }
            .padding()
        }
        .navigationTitle("Sighting")
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
            if let image = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName) {
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
                        if detectedRects.isEmpty && !isDetecting {
                            isDetecting = true
                            Task {
                                let rects = await OCRService.shared.detectLocations(in: image)
                                detectedRects = rects
                                isDetecting = false
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showHighlights = true
                                }
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showHighlights.toggle()
                            }
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
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(rarityColor.opacity(0.15))
                    .frame(height: 300)
                    .overlay {
                        VStack(spacing: 8) {
                            Text("47")
                                .font(.system(size: 80, weight: .bold))
                                .foregroundStyle(rarityColor)
                            Text("No image available")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                rarityBadge
                Spacer()
                Text(sighting.captureDate.formatted(date: .long, time: .shortened))
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

            HStack(spacing: 16) {
                Label(sighting.sourceType.capitalized, systemImage: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if sighting.contains47 {
                    Label("OCR Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
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

                Map(initialPosition: .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))) {
                    Marker("47", coordinate: coordinate)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - OCR Section

    @ViewBuilder
    private var ocrSection: some View {
        if let detectedText = sighting.detectedText {
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Text")
                    .font(.headline)

                Text(detectedText)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
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
        HStack(spacing: 4) {
            ForEach(0..<sighting.rarityScore, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(rarityColor)
            }
            Text(rarityLabel)
                .font(.caption.bold())
                .foregroundStyle(rarityColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(rarityColor.opacity(0.15), in: Capsule())
    }

    private var rarityLabel: String {
        switch sighting.rarityScore {
        case 1: "Common"
        case 2: "Uncommon"
        case 3: "Rare"
        case 4: "Epic"
        case 5: "Legendary"
        default: "Unknown"
        }
    }

    private var rarityColor: Color {
        switch sighting.rarityScore {
        case 1: .gray
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
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
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .overlay {
                    if showHighlights && !detectedRects.isEmpty {
                        ImageHighlightOverlay(rects: detectedRects, imageSize: image.size)
                    }
                }
                .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnifyGesture()
                    .onChanged { value in
                        scale = lastScale * value.magnification
                    }
                    .onEnded { value in
                        lastScale = scale
                        if scale < 1.0 {
                            withAnimation(.spring(duration: 0.3)) {
                                scale = 1.0
                                lastScale = 1.0
                                offset = .zero
                                lastOffset = .zero
                            }
                        }
                    }
                    .simultaneously(with:
                        DragGesture()
                            .onChanged { value in
                                offset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                if scale <= 1.0 {
                                    withAnimation(.spring(duration: 0.3)) {
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }
                            }
                    )
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring(duration: 0.3)) {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 3.0
                        lastScale = 3.0
                    }
                }
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
                    .stroke(Color.green, lineWidth: 2.5)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.1))
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
