import SwiftUI
import SwiftData
import WidgetKit

struct SightingEditView: View {
    @Bindable var sighting: Sighting
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var notes: String = ""
    @State private var selectedCategory: SightingCategory?
    @State private var rarityScore: Int = 1
    @State private var newTagName: String = ""
    @State private var tagNames: [String] = []
    @State private var selectedAlbumIDs: Set<UUID> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                MetadataFormView(
                    notes: $notes,
                    selectedCategory: $selectedCategory,
                    rarityScore: $rarityScore,
                    newTagName: $newTagName,
                    tagNames: $tagNames,
                    selectedAlbumIDs: $selectedAlbumIDs
                )
                .padding()
            }
            .navigationTitle("Edit Sighting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { save() }
                        .bold()
                }
            }
            .onAppear { populateFromSighting() }
        }
    }

    private func populateFromSighting() {
        notes = sighting.notes
        selectedCategory = sighting.category.flatMap { SightingCategory(rawValue: $0) }
        rarityScore = sighting.rarityScore
        tagNames = sighting.tags.map(\.name)
        selectedAlbumIDs = Set(sighting.albums.map(\.id))
    }

    private func save() {
        sighting.notes = notes
        sighting.category = selectedCategory?.rawValue
        sighting.rarityScore = rarityScore
        sighting.updatedAt = .now

        // Sync tags: remove old, add new
        sighting.tags.removeAll()
        for tagName in tagNames {
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate { $0.name == tagName })
            if let existing = try? modelContext.fetch(descriptor).first {
                sighting.tags.append(existing)
            } else {
                let tag = Tag(name: tagName)
                modelContext.insert(tag)
                sighting.tags.append(tag)
            }
        }

        // Sync albums
        sighting.albums.removeAll()
        if !selectedAlbumIDs.isEmpty {
            let descriptor = FetchDescriptor<Album>()
            let allAlbums = (try? modelContext.fetch(descriptor)) ?? []
            for album in allAlbums where selectedAlbumIDs.contains(album.id) {
                sighting.albums.append(album)
            }
        }

        // Update widgets
        let allSightings = (try? modelContext.fetch(FetchDescriptor<Sighting>())) ?? []
        WidgetDataService.update(from: allSightings)
        WidgetCenter.shared.reloadAllTimelines()

        dismiss()
    }
}
