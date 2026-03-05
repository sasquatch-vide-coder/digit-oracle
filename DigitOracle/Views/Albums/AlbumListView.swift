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
                BulkActionBar(actions: [
                    .init(icon: "trash", label: "Destroy", tint: .red, isDisabled: selectedAlbumIDs.isEmpty) {
                        showingDeleteSelected = true
                    },
                    .init(icon: "trash.slash", label: "Destroy All", tint: .red) {
                        showingDeleteAll = true
                    },
                ])
            }
        }
        .confirmationDialog(
            "Destroy \(selectedAlbumIDs.count.pluralized("Scroll"))?",
            isPresented: $showingDeleteSelected,
            titleVisibility: .visible
        ) {
            Button("Destroy", role: .destructive) {
                deleteSelectedAlbums()
            }
        } message: {
            Text("The chosen scroll\(selectedAlbumIDs.count.pluralSuffix) shall crumble to dust. Thy visions shall endure.")
        }
        .confirmationDialog(
            "Destroy All \(albums.count.pluralized("Scroll"))?",
            isPresented: $showingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Destroy All", role: .destructive) {
                deleteAllAlbums()
            }
        } message: {
            Text("All scrolls shall crumble to dust. Thy visions shall endure.")
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
                        SightingCollectionCard(title: "All Visions", sightings: allSightings, placeholderIcon: "photo.on.rectangle.angled")
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
                            SightingCollectionCard(title: album.name, sightings: album.sightings)
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
                            SightingCollectionCard(title: album.name, sightings: album.sightings)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                albumToDelete = album
                            } label: {
                                Label("Destroy Scroll", systemImage: "trash")
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
            "Destroy Scroll",
            isPresented: Binding(
                get: { albumToDelete != nil },
                set: { if !$0 { albumToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Destroy", role: .destructive) {
                if let album = albumToDelete {
                    modelContext.delete(album)
                    albumToDelete = nil
                }
            }
        } message: {
            Text("This scroll shall crumble to dust. Thy visions shall endure.")
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
