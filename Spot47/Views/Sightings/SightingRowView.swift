import SwiftUI

struct SightingRowView: View {
    let sighting: Sighting

    var body: some View {
        HStack(spacing: 12) {
            SightingThumbnailView(sighting: sighting, size: 60)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sighting.notes.isEmpty ? "47 Sighting" : sighting.notes)
                        .font(.body)
                        .lineLimit(1)

                    Spacer()

                    if sighting.isFavorite {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    if let category = sighting.category {
                        Label(category.capitalized, systemImage: categoryIcon(for: category))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if sighting.contains47 {
                        let count = count47s(in: sighting.detectedText)
                        Label(count > 0 ? "\(count)× 47\(count > 1 ? "'s" : "")" : "Verified", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    Text(sighting.captureDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let locationName = sighting.locationName {
                        Text(locationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            rarityBadge
        }
        .padding(.vertical, 4)
    }

    private var rarityBadge: some View {
        Text("\(sighting.rarityScore)")
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(rarityColor, in: Circle())
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

    private func count47s(in text: String?) -> Int {
        guard let text else { return 0 }
        var count = 0
        var searchRange = text.startIndex..<text.endIndex
        while let range = text.range(of: "47", range: searchRange) {
            count += 1
            searchRange = range.upperBound..<text.endIndex
        }
        return count
    }

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
