import SwiftUI

struct SightingRowView: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail with favorite overlay
            ZStack(alignment: .topTrailing) {
                SightingThumbnailView(sighting: sighting, size: 60)

                if sighting.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.red, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                // Primary label
                Text(primaryLabel)
                    .font(.body)
                    .lineLimit(1)

                // Category
                if let category = sighting.category {
                    Label(category.capitalized, systemImage: categoryIcon(for: category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            }

            Spacer()

            VStack(spacing: 4) {
                rarityBadge
                Text("\(sighting.totalMatchCount) \(sighting.totalMatchCount == 1 ? "match" : "matches")")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Primary Label

    private var primaryLabel: String {
        if !sighting.notes.isEmpty {
            return sighting.notes
        }
        return sighting.captureDate.formatted(date: .numeric, time: .omitted)
    }

    // MARK: - Rarity Badge

    private var rarityBadge: some View {
        Text(rarityLabel)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(rarityColor, in: Capsule())
    }

    private var rarityLabel: String {
        switch sighting.rarityScore {
        case 1: "Common"
        case 2: "Uncommon"
        case 3: "Rare"
        case 4: "Epic"
        case 5: "Legendary"
        default: "Common"
        }
    }

    private var rarityColor: Color {
        switch sighting.rarityScore {
        case 1: .gray
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
    }

    // MARK: - Helpers

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "printed": "book.fill"
        case "digital": "desktopcomputer"
        case "natural": "leaf.fill"
        case "handwritten": "pencil"
        case "architectural": "building.2.fill"
        case "serendipitous": "sparkles"
        default: "tag.fill"
        }
    }
}
