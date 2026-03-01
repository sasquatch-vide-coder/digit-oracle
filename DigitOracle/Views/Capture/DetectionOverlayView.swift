import SwiftUI

struct DetectionOverlayView: View {
    let detections: [CGRect]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ForEach(Array(detections.enumerated()), id: \.offset) { _, rect in
                let converted = convertRect(rect, in: size)
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.goldPrimary, lineWidth: 2.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.goldPrimary.opacity(0.1))
                    )
                    .frame(width: converted.width, height: converted.height)
                    .position(x: converted.midX, y: converted.midY)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: detections.count)
    }

    /// Converts Vision normalized coordinates (bottom-left origin) to screen coordinates
    /// accounting for `.resizeAspectFill` crop behavior.
    private func convertRect(_ rect: CGRect, in viewSize: CGSize) -> CGRect {
        // Vision coordinates: origin at bottom-left, Y goes up
        // Screen coordinates: origin at top-left, Y goes down
        // Camera aspect ratio is typically 4:3 for photo preset
        let cameraAspect: CGFloat = 4.0 / 3.0
        let viewAspect = viewSize.width / viewSize.height

        let scaleX: CGFloat
        let scaleY: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if viewAspect > cameraAspect {
            // View is wider than camera — crop top/bottom
            scaleX = viewSize.width
            scaleY = viewSize.width / cameraAspect
            offsetX = 0
            offsetY = (viewSize.height - scaleY) / 2
        } else {
            // View is taller than camera — crop left/right
            scaleY = viewSize.height
            scaleX = viewSize.height * cameraAspect
            offsetX = (viewSize.width - scaleX) / 2
            offsetY = 0
        }

        let x = rect.origin.x * scaleX + offsetX
        let y = (1 - rect.origin.y - rect.height) * scaleY + offsetY
        let width = rect.width * scaleX
        let height = rect.height * scaleY

        return CGRect(x: x, y: y, width: width, height: height)
    }
}
