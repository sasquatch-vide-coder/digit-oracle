import SwiftUI

struct SightingCollectionCard: View {
    let title: String
    let sightings: [Sighting]
    var placeholderIcon: String = "rectangle.stack"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover image or placeholder
            ZStack {
                if let coverImage = loadCoverImage() {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: placeholderIcon)
                                .font(.system(size: 28))
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(height: 130)
            .clipped()

            // Info bar
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(sightings.count.pluralized("vision"))
                        .foregroundStyle(.secondary)
                    if totalMatchCount > 0 {
                        Label("\(totalMatchCount)×", systemImage: "sparkles")
                            .foregroundStyle(Color.goldPrimary)
                    }
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }

    private func loadCoverImage() -> UIImage? {
        sightings.sorted(by: { $0.captureDate > $1.captureDate }).first?.loadBestImage()
    }

    private var totalMatchCount: Int {
        sightings.reduce(0) { $0 + $1.totalMatchCount }
    }
}
