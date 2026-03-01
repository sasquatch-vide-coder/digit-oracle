import SwiftUI

enum ShareCardRenderer {
    @MainActor
    static func render(sighting: Sighting, image: UIImage) -> UIImage? {
        let view = ShareCardView(sighting: sighting, image: image)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
