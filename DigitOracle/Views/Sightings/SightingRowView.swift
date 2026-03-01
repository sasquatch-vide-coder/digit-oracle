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
                Text("\(sighting.totalMatchCount) \(sighting.totalMatchCount == 1 ? "revelation" : "revelations")")
                    .font(.caption.bold())
                    .foregroundColor(.goldPrimary)
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
        Text(OracleTextService.tierLabel(for: sighting.rarityScore))
            .font(.oracleCaption)
            .foregroundStyle(Color.rarityColor(for: sighting.rarityScore))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.backgroundSecondary, in: Capsule())
            .overlay(
                Capsule().stroke(Color.rarityColor(for: sighting.rarityScore).opacity(0.5), lineWidth: 0.5)
            )
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
