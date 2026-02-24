import SwiftUI
import SwiftData

/// Wrapper to distinguish sighting navigation from album navigation (both use UUID).
struct SightingNavigationID: Hashable {
    let id: UUID
}

struct AlbumDetailView: View {
    @Bindable var album: Album
    @Query(sort: \Sighting.captureDate, order: .reverse) private var allSightings: [Sighting]
    @State private var showingAddSightings = false

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ScrollView {
            if album.sightings.isEmpty {
                ContentUnavailableView(
                    "No Sightings",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Tap + to add sightings to this album.")
                )
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(sortedSightings) { sighting in
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
        .navigationTitle(album.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSightings = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSightings) {
            AddSightingsToAlbumView(album: album, allSightings: allSightings)
        }
        .navigationDestination(for: SightingNavigationID.self) { nav in
            if let sighting = album.sightings.first(where: { $0.id == nav.id }) {
                SightingDetailView(sighting: sighting)
            }
        }
    }

    private var sortedSightings: [Sighting] {
        album.sightings.sorted { $0.captureDate > $1.captureDate }
    }
}

// MARK: - Add Sightings to Album

struct AddSightingsToAlbumView: View {
    @Bindable var album: Album
    let allSightings: [Sighting]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIDs: Set<UUID> = []

    private var availableSightings: [Sighting] {
        let albumIDs = Set(album.sightings.map(\.id))
        return allSightings.filter { !albumIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableSightings.isEmpty {
                    ContentUnavailableView(
                        "All Sightings Added",
                        systemImage: "checkmark.circle",
                        description: Text("Every sighting is already in this album.")
                    )
                } else {
                    List(availableSightings) { sighting in
                        Button {
                            if selectedIDs.contains(sighting.id) {
                                selectedIDs.remove(sighting.id)
                            } else {
                                selectedIDs.insert(sighting.id)
                            }
                        } label: {
                            HStack {
                                SightingThumbnailView(sighting: sighting, size: 50)
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sighting.notes.isEmpty ? "47 Sighting" : sighting.notes)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Text(sighting.captureDate.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: selectedIDs.contains(sighting.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedIDs.contains(sighting.id) ? .accentColor : .secondary)
                                    .font(.title3)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("Add to \(album.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Add (\(selectedIDs.count))") {
                        for sighting in allSightings where selectedIDs.contains(sighting.id) {
                            album.sightings.append(sighting)
                        }
                        dismiss()
                    }
                    .bold()
                    .disabled(selectedIDs.isEmpty)
                }
            }
        }
    }
}
