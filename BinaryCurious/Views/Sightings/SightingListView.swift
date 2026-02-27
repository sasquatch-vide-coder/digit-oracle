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
        .navigationTitle("Sightings")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search sightings")
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text("Sightings")
                        .font(.headline)
                    if !sightings.isEmpty {
                        HStack(spacing: 4) {
                            Text("\(filteredSightings.count) sighting\(filteredSightings.count == 1 ? "" : "s")")
                            Text("·")
                            Text("\(totalMatches) match\(totalMatches == 1 ? "" : "es")")
                                .foregroundColor(.green)
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
                        .disabled(selectedSightingIDs.isEmpty)
                        .tint(.red)

                        Button {
                            showingAlbumPickerForSelected = true
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "rectangle.stack.badge.plus")
                                    .font(.title3)
                                Text("Add to Album")
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .disabled(selectedSightingIDs.isEmpty)

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
            "Delete Sighting",
            isPresented: Binding(
                get: { sightingToDelete != nil },
                set: { if !$0 { sightingToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let sighting = sightingToDelete {
                    try? ImageStorageService.shared.deleteImages(for: sighting.id)
                    modelContext.delete(sighting)
                    sightingToDelete = nil
                }
            }
        } message: {
            Text("This sighting will be permanently deleted.")
        }
        .confirmationDialog(
            "Delete \(selectedSightingIDs.count) Sighting\(selectedSightingIDs.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteSelected,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteSelectedSightings()
            }
        } message: {
            Text("The selected sighting\(selectedSightingIDs.count == 1 ? "" : "s") will be permanently deleted.")
        }
        .confirmationDialog(
            "Delete All \(filteredSightings.count) Sighting\(filteredSightings.count == 1 ? "" : "s")?",
            isPresented: $showingDeleteAll,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                deleteAllSightings()
            }
        } message: {
            Text("All sightings will be permanently deleted. This cannot be undone.")
        }
        .environment(\.editMode, $editMode)
    }

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Sightings Yet", systemImage: "eye.slash")
        } description: {
            Text("Start spotting numbers in the wild! Use the Capture tab to log your first sighting.")
        }
    }

    private var sightingsList: some View {
        List(selection: editMode == .active ? $selectedSightingIDs : nil) {
            if filteredSightings.isEmpty {
                ContentUnavailableView(
                    "No Matches",
                    systemImage: "magnifyingglass",
                    description: Text("Try adjusting your filters or search terms.")
                )
            }

            ForEach(filteredSightings) { sighting in
                NavigationLink(value: sighting.id) {
                    SightingRowView(sighting: sighting)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        sightingToDelete = sighting
                    } label: {
                        Label("Delete", systemImage: "trash")
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

    private func deleteSighting(_ sighting: Sighting) {
        try? ImageStorageService.shared.deleteImages(for: sighting.id)
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
                        "No Albums",
                        systemImage: "rectangle.stack",
                        description: Text("Create an album first from the Albums tab.")
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
            .navigationTitle("Add to Album")
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
