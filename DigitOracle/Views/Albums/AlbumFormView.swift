import SwiftUI

struct AlbumFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var existingAlbum: Album?

    @State private var name: String = ""
    @State private var description: String = ""

    var isEditing: Bool { existingAlbum != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scroll Name") {
                    TextField("Ancient Whispers", text: $name)
                }
                Section("Inscription") {
                    TextField("Inscribe a purpose for this scroll...", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(isEditing ? "Edit Scroll" : "New Scroll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Update" : "Create") {
                        save()
                    }
                    .bold()
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let album = existingAlbum {
                    name = album.name
                    description = album.albumDescription
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let album = existingAlbum {
            album.name = trimmedName
            album.albumDescription = description
            album.updatedAt = .now
        } else {
            let album = Album(
                ownerUserID: Constants.defaultOwnerID,
                name: trimmedName,
                albumDescription: description
            )
            modelContext.insert(album)
        }

        dismiss()
    }
}
