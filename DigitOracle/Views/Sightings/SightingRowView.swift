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
                    Label(category.capitalized, systemImage: SightingCategory(rawValue: category)?.iconName ?? "tag.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

            }

            Spacer()

            VStack(spacing: 4) {
                rarityBadge
                Text(sighting.totalMatchCount.pluralized("revelation"))
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
        RarityBadge(score: sighting.rarityScore)
    }

}
