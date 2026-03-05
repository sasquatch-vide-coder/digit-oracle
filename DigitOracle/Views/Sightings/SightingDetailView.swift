import SwiftUI
import SwiftData
import MapKit

struct SightingDetailView: View {
    @Bindable var sighting: Sighting
    @Query(sort: \Album.name) private var allAlbums: [Album]
    @State private var showingAlbumPicker = false
    @State private var showingEditor = false
    @State private var showHighlights = true
    @State private var fullImage: UIImage?
    @State private var rescanID = UUID()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SightingImageSection(
                    sighting: sighting,
                    showHighlights: $showHighlights,
                    rescanID: rescanID,
                    onImageLoaded: { fullImage = $0 }
                )
                metadataSection
                SightingMatchCountsSection(
                    sighting: sighting,
                    onRescanComplete: { rescanID = UUID() }
                )
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
                        generateShareCard()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
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

    private func generateShareCard() {
        let image = fullImage ?? sighting.loadBestImage(preferThumbnail: false)
        guard let image else { return }
        guard let cardImage = ShareCardRenderer.render(sighting: sighting, image: image) else { return }
        SharePresenter.present(items: [cardImage])
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                RarityBadge(score: sighting.rarityScore, style: .detailed)

                if sighting.containsTrackedNumber {
                    Label("Revealed", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.goldDark, in: Capsule())
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
                Label(category.capitalized, systemImage: SightingCategory(rawValue: category)?.iconName ?? "tag.fill")
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
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
                        Text("See Full Map")
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
                Text("Scrolls")
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
}
