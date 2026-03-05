import SwiftUI

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
            .navigationTitle("Scrolls")
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
