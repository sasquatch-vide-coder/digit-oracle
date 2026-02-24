import SwiftUI
import SwiftData

struct MetadataFormView: View {
    @Binding var notes: String
    @Binding var selectedCategory: SightingCategory?
    @Binding var rarityScore: Int
    @Binding var newTagName: String
    @Binding var tagNames: [String]
    @Binding var selectedAlbumIDs: Set<UUID>

    @Query(sort: \Album.name) private var albums: [Album]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes")
                    .font(.headline)
                TextField("What did you spot? Where was it?", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }

            // Category
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SightingCategory.allCases) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = (selectedCategory == category) ? nil : category
                            }
                        }
                    }
                }
            }

            // Rarity
            RarityPickerView(rarityScore: $rarityScore)

            // Albums
            if !albums.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Albums")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(albums) { album in
                                let isSelected = selectedAlbumIDs.contains(album.id)
                                Button {
                                    if isSelected {
                                        selectedAlbumIDs.remove(album.id)
                                    } else {
                                        selectedAlbumIDs.insert(album.id)
                                    }
                                } label: {
                                    Label(album.name, systemImage: isSelected ? "checkmark.rectangle.stack.fill" : "rectangle.stack")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1),
                                            in: Capsule()
                                        )
                                        .foregroundColor(isSelected ? .accentColor : .secondary)
                                        .overlay(
                                            Capsule().strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 1.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags")
                    .font(.headline)

                HStack {
                    TextField("Add a tag", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addTag() }
                    Button("Add") { addTag() }
                        .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !tagNames.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(tagNames, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text(tag)
                                    .font(.caption)
                                Button {
                                    tagNames.removeAll { $0 == tag }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.thinMaterial, in: Capsule())
                        }
                    }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !tagNames.contains(trimmed) else { return }
        tagNames.append(trimmed)
        newTagName = ""
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: SightingCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.displayName, systemImage: category.iconName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? category.color.opacity(0.2) : Color.secondary.opacity(0.1),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? category.color : .secondary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
