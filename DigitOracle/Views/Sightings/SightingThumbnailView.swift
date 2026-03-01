import SwiftUI

struct SightingThumbnailView: View {
    let sighting: Sighting
    var size: CGFloat = 60

    var body: some View {
        Group {
            if let thumbName = sighting.thumbnailFileName,
               let image = ImageStorageService.shared.loadImage(fileName: thumbName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if sighting.hasLocalFullImage,
                      let image = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName) {
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
