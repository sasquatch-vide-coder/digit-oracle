import SwiftUI

struct SightingThumbnailView: View {
    let sighting: Sighting
    var size: CGFloat = 60

    var body: some View {
        Group {
            if let image = sighting.loadBestImage() {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                // Fallback for sightings without real images (e.g. samples)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.rarityColor(for: sighting.rarityScore).opacity(0.2))
                    .overlay {
                        Text("\(TrackedNumberService.shared.primaryNumber)")
                            .font(size > 80 ? .title.bold() : .title3.bold())
                            .foregroundStyle(Color.rarityColor(for: sighting.rarityScore))
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
