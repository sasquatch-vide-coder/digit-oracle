import SwiftUI
import SwiftData

struct SightingFilter {
    var category: SightingCategory?
    var minRarity: Int?
    var verifiedOnly: Bool = false
    var favoritesOnly: Bool = false
    var albumID: UUID?
    var sortOption: SortOption = .mostMatches

    var isActive: Bool {
        category != nil || minRarity != nil || verifiedOnly || favoritesOnly || albumID != nil
    }

    mutating func reset() {
        category = nil
        minRarity = nil
        verifiedOnly = false
        favoritesOnly = false
        albumID = nil
    }

    enum SortOption: String, CaseIterable {
        case mostMatches = "Most Matches"
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case rarityHighest = "Rarest First"
        case rarityLowest = "Most Common First"
    }
}

struct FilterSheetView: View {
    @Binding var filter: SightingFilter
    @Query(sort: \Album.name) private var albums: [Album]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    Picker("Sort", selection: $filter.sortOption) {
                        ForEach(SightingFilter.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Category") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", icon: "line.3.horizontal.decrease", isSelected: filter.category == nil) {
                                filter.category = nil
                            }
                            ForEach(SightingCategory.allCases) { category in
                                FilterChip(label: category.displayName, icon: category.iconName, isSelected: filter.category == category) {
                                    filter.category = (filter.category == category) ? nil : category
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .padding(.horizontal)
                }

                Section("Minimum Rarity") {
                    Picker("Rarity", selection: Binding(
                        get: { filter.minRarity ?? 0 },
                        set: { filter.minRarity = $0 == 0 ? nil : $0 }
                    )) {
                        Text("Any").tag(0)
                        Text("Uncommon+").tag(2)
                        Text("Rare+").tag(3)
                        Text("Epic+").tag(4)
                        Text("Legendary").tag(5)
                    }
                    .pickerStyle(.menu)
                }

                Section("Filters") {
                    Toggle("Verified (OCR) Only", isOn: $filter.verifiedOnly)
                    Toggle("Favorites Only", isOn: $filter.favoritesOnly)
                }

                if !albums.isEmpty {
                    Section("Album") {
                        Picker("Album", selection: Binding(
                            get: { filter.albumID },
                            set: { filter.albumID = $0 }
                        )) {
                            Text("All Albums").tag(UUID?.none)
                            ForEach(albums) { album in
                                Text(album.name).tag(UUID?.some(album.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section {
                    Button("Reset All Filters", role: .destructive) {
                        filter.reset()
                    }
                    .disabled(!filter.isActive)
                }
            }
            .navigationTitle("Filter & Sort")
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

struct FilterChip: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(label, systemImage: icon)
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
