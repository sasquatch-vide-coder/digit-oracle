import SwiftUI
import SwiftData
import WidgetKit

struct SightingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Sighting.captureDate, order: .reverse) private var sightings: [Sighting]
    @Query(sort: \Album.name) private var albums: [Album]
    @State private var searchText = ""
    @State private var filter = SightingFilter()
    @State private var showingFilter = false
    @State private var sightingToDelete: Sighting?
    @State private var selectedSightingIDs = Set<UUID>()
    @State private var editMode: EditMode = .inactive
    @State private var showingDeleteSelected = false
    @State private var showingDeleteAll = false
    @State private var showingAlbumPickerForSelected = false

    private var totalMatches: Int {
        filteredSightings.reduce(0) { $0 + $1.totalMatchCount }
    }

    var filteredSightings: [Sighting] {
        var results = sightings

        if filter.verifiedOnly {
            results = results.filter { $0.containsTrackedNumber }
        }
        if filter.favoritesOnly {
            results = results.filter { $0.isFavorite }
        }
        if let category = filter.category {
            results = results.filter { $0.category == category.rawValue }
        }
        if let minRarity = filter.minRarity {
            results = results.filter { $0.rarityScore >= minRarity }
        }
        if let albumID = filter.albumID {
            results = results.filter { sighting in
                sighting.albums.contains { $0.id == albumID }
            }
        }

        if !searchText.isEmpty {
            results = results.filter { sighting in
                sighting.notes.localizedCaseInsensitiveContains(searchText) ||
                (sighting.locationName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (sighting.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Sort
        switch filter.sortOption {
        case .mostMatches:
            results.sort { $0.totalMatchCount > $1.totalMatchCount }
        case .dateNewest:
            results.sort { $0.captureDate > $1.captureDate }
        case .dateOldest:
            results.sort { $0.captureDate < $1.captureDate }
        case .rarityHighest:
            results.sort { $0.rarityScore > $1.rarityScore }
        case .rarityLowest:
            results.sort { $0.rarityScore < $1.rarityScore }
        }

        return results
    }

    var body: some View {
        Group {
            if sightings.isEmpty {
                emptyStateView
            } else {
                sightingsList
            }
        }
        .navigationTitle("Visions")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search visions")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Visions")
                        .font(.headline)
                    if !sightings.isEmpty {
                        HStack(spacing: 4) {
                            Text(filteredSightings.count.pluralized("vision"))
                            Text("\u{00B7}")
                            Text(totalMatches.pluralized("revelation"))
                                .foregroundColor(.goldPrimary)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    Button {
                        showingFilter = true
                    } label: {
                        Label("Filter", systemImage: filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(filter.isActive ? .accentColor : .secondary)
                    }
                    if editMode == .active {
                        Button {
                            if selectedSightingIDs.count == filteredSightings.count {
                                selectedSightingIDs.removeAll()
                            } else {
                                selectedSightingIDs = Set(filteredSightings.map(\.id))
                            }
                        } label: {
                            Text(selectedSightingIDs.count == filteredSightings.count ? "Deselect All" : "Select All")
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if !sightings.isEmpty {
                    Button {
                        withAnimation {
                            if editMode == .active {
                                editMode = .inactive
                                selectedSightingIDs.removeAll()
                            } else {
                                editMode = .active
                            }
                        }
                    } label: {
                        Text(editMode == .active ? "Done" : "Select")
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if editMode == .active {
                BulkActionBar(actions: [
                    .init(icon: "trash", label: "Banish", tint: .red, isDisabled: selectedSightingIDs.isEmpty) {
                        showingDeleteSelected = true
                    },
                    .init(icon: "rectangle.stack.badge.plus", label: "Add to Scroll", isDisabled: selectedSightingIDs.isEmpty) {
                        showingAlbumPickerForSelected = true
                    },
                    .init(icon: "trash.slash", label: "Banish All", tint: .red) {
                        showingDeleteAll = true
                    },
                ])
            }
        }
        .sheet(isPresented: $showingFilter) {
            FilterSheetView(filter: $filter)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingAlbumPickerForSelected) {
            BulkAlbumPickerView(albums: albums, selectedSightingIDs: selectedSightingIDs) {
                selectedSightingIDs.removeAll()
                editMode = .inactive
            }
        }
        .confirmationDialog(
            "Erase Vision",
            isPresented: Binding(
                get: { sightingToDelete != nil },
                set: { if !$0 { sightingToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Banish", role: .destructive) {
                if let sighting = sightingToDelete {
                    deleteSighting(sighting)
                    sightingToDelete = nil
                }
            }
        } message: {
            Text("This vision shall be cast into the void. Thy original shall remain untouched.")
        }
        .confirmationDialog(
            "Erase \(selectedSightingIDs.count.pluralized("Vision"))?",
            isPresented: $showingDeleteSelected,
            titleVisibility: .visible
        ) {
            Button("Banish", role: .destructive) {
                deleteSelectedSightings()
            }
        } message: {
            Text("The selected vision\(selectedSightingIDs.count.pluralSuffix) shall be cast into the void. Thy original photos shall endure.")
        }
        .confirmationDialog(
            "Erase All \(filteredSightings.count.pluralized("Vision"))?",
            isPresented: $showingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Banish All", role: .destructive) {
                deleteAllSightings()
            }
        } message: {
            Text("All visions shall be cast into the void. Thy original photos shall endure.")
        }
        .environment(\.editMode, $editMode)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("The Void", systemImage: "eye.slash")
        } description: {
            Text("The Oracle gazes into the void and sees\u{2026} nothing yet. Patience, seeker.")
        }
    }

    private var sightingsList: some View {
        List(selection: editMode == .active ? $selectedSightingIDs : nil) {
            if filteredSightings.isEmpty {
                ContentUnavailableView(
                    "No Visions Found",
                    systemImage: "magnifyingglass",
                    description: Text("The Oracle finds no visions matching thy criteria.")
                )
            }

            ForEach(filteredSightings) { sighting in
                NavigationLink(value: sighting.id) {
                    SightingRowView(sighting: sighting)
                }
                .contextMenu {
                    Button {
                        generateShareCard(for: sighting)
                    } label: {
                        Label("Share Vision", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        sighting.isFavorite.toggle()
                    } label: {
                        Label(
                            sighting.isFavorite ? "Unconsecrate" : "Consecrate",
                            systemImage: sighting.isFavorite ? "heart.slash" : "heart"
                        )
                    }
                    Button(role: .destructive) {
                        sightingToDelete = sighting
                    } label: {
                        Label("Banish", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        sightingToDelete = sighting
                    } label: {
                        Label("Banish", systemImage: "trash")
                    }
                }
            }
        }
        .navigationDestination(for: UUID.self) { sightingID in
            if let sighting = sightings.first(where: { $0.id == sightingID }) {
                SightingDetailView(sighting: sighting)
            }
        }
    }

    private func generateShareCard(for sighting: Sighting) {
        let image = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName)
            ?? ImageStorageService.shared.loadImage(fileName: sighting.thumbnailFileName ?? "")
        guard let image else { return }
        guard let cardImage = ShareCardRenderer.render(sighting: sighting, image: image) else { return }
        SharePresenter.present(items: [cardImage])
    }

    private func deleteSighting(_ sighting: Sighting) {
        if sighting.hasLocalFullImage {
            try? ImageStorageService.shared.deleteImages(for: sighting.id)
        } else if let thumbName = sighting.thumbnailFileName {
            try? ImageStorageService.shared.deleteImage(fileName: thumbName)
        }
        modelContext.delete(sighting)
    }

    private func deleteSelectedSightings() {
        for id in selectedSightingIDs {
            if let sighting = sightings.first(where: { $0.id == id }) {
                deleteSighting(sighting)
            }
        }
        selectedSightingIDs.removeAll()
        editMode = .inactive
        refreshWidgets()
    }

    private func deleteAllSightings() {
        for sighting in sightings {
            deleteSighting(sighting)
        }
        selectedSightingIDs.removeAll()
        editMode = .inactive
        refreshWidgets()
    }

    private func refreshWidgets() {
        let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        WidgetDataService.update(from: allSightings)
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Bulk Album Picker

private struct BulkAlbumPickerView: View {
    let albums: [Album]
    let selectedSightingIDs: Set<UUID>
    let onComplete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if albums.isEmpty {
                    ContentUnavailableView(
                        "No Scrolls",
                        systemImage: "rectangle.stack",
                        description: Text("Thou must first create a Scroll from the Scrolls tab.")
                    )
                } else {
                    List(albums) { album in
                        Button {
                            addSelectedToAlbum(album)
                        } label: {
                            Label(album.name, systemImage: "rectangle.stack.fill")
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add to Scroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func addSelectedToAlbum(_ album: Album) {
        let descriptor = FetchDescriptor<Sighting>()
        guard let allSightings = try? modelContext.fetch(descriptor) else { return }
        let existingIDs = Set(album.sightings.map(\.id))
        for sighting in allSightings where selectedSightingIDs.contains(sighting.id) {
            if !existingIDs.contains(sighting.id) {
                album.sightings.append(sighting)
            }
        }
        dismiss()
        onComplete()
    }
}

#Preview {
    NavigationStack {
        SightingListView()
    }
    .modelContainer(for: Sighting.self, inMemory: true)
}
