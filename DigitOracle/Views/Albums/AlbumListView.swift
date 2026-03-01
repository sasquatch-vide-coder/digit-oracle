import SwiftUI
import SwiftData

struct AlbumListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Album.updatedAt, order: .reverse) private var albums: [Album]
    @Query(sort: \Sighting.captureDate, order: .reverse) private var allSightings: [Sighting]
    @State private var showingNewAlbum = false
    @State private var albumToDelete: Album?
    @State private var isSelecting = false
    @State private var selectedAlbumIDs = Set<UUID>()
    @State private var showingDeleteSelected = false
    @State private var showingDeleteAll = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        albumGrid
        .navigationTitle("Scrolls")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isSelecting {
                    Button {
                        if selectedAlbumIDs.count == albums.count {
                            selectedAlbumIDs.removeAll()
                        } else {
                            selectedAlbumIDs = Set(albums.map(\.id))
                        }
                    } label: {
                        Text(selectedAlbumIDs.count == albums.count ? "Deselect All" : "Select All")
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 16) {
                    if !albums.isEmpty {
                        Button {
                            withAnimation {
                                isSelecting.toggle()
                                if !isSelecting {
                                    selectedAlbumIDs.removeAll()
                                }
                            }
                        } label: {
                            Text(isSelecting ? "Done" : "Select")
                        }
                    }
                    if !isSelecting {
                        Button {
                            showingNewAlbum = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Button {
                            showingDeleteSelected = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.title3)
                                Text("Delete")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(selectedAlbumIDs.isEmpty)
                        .tint(.red)

                        Button {
                            showingDeleteAll = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "trash.slash")
                                    .font(.title3)
                                Text("Delete All")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal)
                }
                .background(.bar)
            }
        }
        .confirmationDialog(
            "Delete \(selectedAlbumIDs.count) Album\(selectedAlbumIDs.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteSelected,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedAlbums()
            }
        } message: {
            Text("The selected album\(selectedAlbumIDs.count == 1 ? "" : "s") will be permanently deleted. Visions shall remain.")
        }
        .confirmationDialog(
            "Delete All \(albums.count) Album\(albums.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                deleteAllAlbums()
            }
        } message: {
            Text("All albums will be permanently deleted. Visions shall remain.")
        }
        .sheet(isPresented: $showingNewAlbum) {
            AlbumFormView()
        }
    }

    private var albumGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                // "All Visions" virtual album — always first, never selectable
                if !isSelecting {
                    NavigationLink(value: "all_sightings") {
                        AllSightingsCardView(sightings: allSightings)
                    }
                    .buttonStyle(.plain)
                }

                ForEach(albums) { album in
                    if isSelecting {
                        Button {
                            if selectedAlbumIDs.contains(album.id) {
                                selectedAlbumIDs.remove(album.id)
                            } else {
                                selectedAlbumIDs.insert(album.id)
                            }
                        } label: {
                            AlbumCardView(album: album)
                                .overlay(alignment: .topLeading) {
                                    Image(systemName: selectedAlbumIDs.contains(album.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(selectedAlbumIDs.contains(album.id) ? Color.accentColor : Color.secondary)
                                        .background(Circle().fill(.ultraThinMaterial).padding(2))
                                        .padding(8)
                                }
                        }
                        .buttonStyle(.plain)
                    } else {
                        NavigationLink(value: album.id) {
                            AlbumCardView(album: album)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                albumToDelete = album
                            } label: {
                                Label("Delete Album", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationDestination(for: String.self) { value in
            if value == "all_sightings" {
                AllSightingsAlbumView()
            }
        }
        .navigationDestination(for: UUID.self) { albumID in
            if let album = albums.first(where: { $0.id == albumID }) {
                AlbumDetailView(album: album)
            }
        }
        .confirmationDialog(
            "Delete Album",
            isPresented: Binding(
                get: { albumToDelete != nil },
                set: { if !$0 { albumToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let album = albumToDelete {
                    modelContext.delete(album)
                    albumToDelete = nil
                }
            }
        } message: {
            Text("This album will be permanently deleted. Visions in the scroll shall remain.")
        }
    }

    private func deleteSelectedAlbums() {
        for id in selectedAlbumIDs {
            if let album = albums.first(where: { $0.id == id }) {
                modelContext.delete(album)
            }
        }
        selectedAlbumIDs.removeAll()
        isSelecting = false
    }

    private func deleteAllAlbums() {
        for album in albums {
            modelContext.delete(album)
        }
        selectedAlbumIDs.removeAll()
        isSelecting = false
    }
}

// MARK: - Album Card

struct AlbumCardView: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image or placeholder
            ZStack {
                if let coverImage = loadCoverImage() {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "rectangle.stack")
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(height: 130)
            .clipped()

            // Info bar
            VStack(alignment: .leading, spacing: 3) {
                Text(album.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(album.sightings.count) vision\(album.sightings.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                    if totalMatchCount > 0 {
                        Label("\(totalMatchCount)× revealed", systemImage: "sparkles")
                            .foregroundStyle(Color.goldPrimary)
                    }
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    private func loadCoverImage() -> UIImage? {
        guard let firstSighting = album.sightings.sorted(by: { $0.captureDate > $1.captureDate }).first else { return nil }
        if let thumbName = firstSighting.thumbnailFileName,
           let image = ImageStorageService.shared.loadImage(fileName: thumbName) {
            return image
        }
        guard firstSighting.hasLocalFullImage else { return nil }
        return ImageStorageService.shared.loadImage(fileName: firstSighting.imageFileName)
    }

    private var totalMatchCount: Int {
        album.sightings.reduce(0) { $0 + $1.totalMatchCount }
    }
}

// MARK: - All Sightings Card

struct AllSightingsCardView: View {
    let sightings: [Sighting]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                if let coverImage = loadCoverImage() {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(height: 130)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text("All Visions")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text("\(sightings.count) vision\(sightings.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                    if totalMatchCount > 0 {
                        Label("\(totalMatchCount)× revealed", systemImage: "sparkles")
                            .foregroundStyle(Color.goldPrimary)
                    }
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    private func loadCoverImage() -> UIImage? {
        guard let first = sightings.first else { return nil }
        if let thumbName = first.thumbnailFileName,
           let image = ImageStorageService.shared.loadImage(fileName: thumbName) {
            return image
        }
        guard first.hasLocalFullImage else { return nil }
        return ImageStorageService.shared.loadImage(fileName: first.imageFileName)
    }

    private var totalMatchCount: Int {
        sightings.reduce(0) { $0 + $1.totalMatchCount }
    }
}

// MARK: - All Sightings Album View

struct AllSightingsAlbumView: View {
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ScrollView {
            if sightings.isEmpty {
                ContentUnavailableView(
                    "No Visions",
                    systemImage: "eye.slash",
                    description: Text("Thy first vision shall appear here.")
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(sightings) { sighting in
                        NavigationLink(value: SightingNavigationID(id: sighting.id)) {
                            SightingThumbnailView(sighting: sighting, size: 120)
                                .frame(height: 120)
                                .clipped()
                        }
                    }
                }
                .padding(4)
            }
        }
        .navigationTitle("All Visions")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SightingNavigationID.self) { nav in
            if let sighting = sightings.first(where: { $0.id == nav.id }) {
                SightingDetailView(sighting: sighting)
            }
        }
    }
}
