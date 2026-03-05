import SwiftUI

struct FullScreenImageView: View {
    let image: UIImage
    let detectedRects: [CGRect]
    @Binding var showHighlights: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var committedScale: CGFloat = 1.0
    @State private var committedOffset: CGSize = .zero
    @GestureState private var zoomState = ZoomState()
    @GestureState private var dragTranslation: CGSize = .zero

    private struct ZoomState: Equatable {
        var scale: CGFloat = 1.0
        var anchorOffset: CGSize = .zero
    }

    private var currentScale: CGFloat {
        committedScale * zoomState.scale
    }

    private var currentOffset: CGSize {
        CGSize(
            width: committedOffset.width + dragTranslation.width + zoomState.anchorOffset.width,
            height: committedOffset.height + dragTranslation.height + zoomState.anchorOffset.height
        )
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geometry in
                let viewSize = geometry.size

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay {
                        if showHighlights && !detectedRects.isEmpty {
                            ImageHighlightOverlay(rects: detectedRects, imageSize: image.size)
                        }
                    }
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .frame(width: viewSize.width, height: viewSize.height)
                    .contentShape(Rectangle())
                    .gesture(
                        MagnifyGesture()
                            .updating($zoomState) { value, state, _ in
                                let mag = value.magnification
                                let anchor = value.startAnchor
                                let dx = (anchor.x - 0.5) * viewSize.width
                                let dy = (anchor.y - 0.5) * viewSize.height
                                state = ZoomState(
                                    scale: mag,
                                    anchorOffset: CGSize(
                                        width: dx * committedScale * (1 - mag),
                                        height: dy * committedScale * (1 - mag)
                                    )
                                )
                            }
                            .onEnded { value in
                                let mag = value.magnification
                                let anchor = value.startAnchor
                                let dx = (anchor.x - 0.5) * viewSize.width
                                let dy = (anchor.y - 0.5) * viewSize.height
                                committedOffset = CGSize(
                                    width: committedOffset.width + dx * committedScale * (1 - mag),
                                    height: committedOffset.height + dy * committedScale * (1 - mag)
                                )
                                committedScale *= mag
                                if committedScale < 1.0 {
                                    withAnimation(.spring(duration: 0.3)) {
                                        committedScale = 1.0
                                        committedOffset = .zero
                                    }
                                }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .updating($dragTranslation) { value, state, _ in
                                        state = value.translation
                                    }
                                    .onEnded { value in
                                        committedOffset = CGSize(
                                            width: committedOffset.width + value.translation.width,
                                            height: committedOffset.height + value.translation.height
                                        )
                                        if committedScale <= 1.0 {
                                            withAnimation(.spring(duration: 0.3)) {
                                                committedOffset = .zero
                                            }
                                        }
                                    }
                            )
                    )
                    .gesture(
                        SpatialTapGesture(count: 2)
                            .onEnded { value in
                                withAnimation(.spring(duration: 0.3)) {
                                    if committedScale > 1.0 {
                                        committedScale = 1.0
                                        committedOffset = .zero
                                    } else {
                                        let targetScale: CGFloat = 3.0
                                        let dx = value.location.x - viewSize.width / 2
                                        let dy = value.location.y - viewSize.height / 2
                                        let magnification = targetScale / committedScale
                                        committedOffset = CGSize(
                                            width: dx * committedScale * (1 - magnification),
                                            height: dy * committedScale * (1 - magnification)
                                        )
                                        committedScale = targetScale
                                    }
                                }
                            }
                    )
            }

            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showHighlights.toggle()
                        }
                    } label: {
                        Image(systemName: showHighlights ? "eye" : "eye.slash")
                            .font(.title2)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .white.opacity(0.3))
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
    }
}

// MARK: - Image Highlight Overlay

struct ImageHighlightOverlay: View {
    let rects: [CGRect]
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ForEach(Array(rects.enumerated()), id: \.offset) { _, rect in
                let center = rectCenter(rect, in: size)
                let diameter = circleDiameter(rect, in: size)
                Circle()
                    .stroke(Color.goldPrimary, lineWidth: 2.5)
                    .background(
                        Circle()
                            .fill(Color.goldPrimary.opacity(0.1))
                    )
                    .frame(width: diameter, height: diameter)
                    .position(x: center.x, y: center.y)
            }
        }
        .allowsHitTesting(false)
    }

    /// Returns the screen-space center point of a Vision normalized rect.
    private func rectCenter(_ rect: CGRect, in viewSize: CGSize) -> CGPoint {
        let centerX = (rect.origin.x + rect.width / 2) * viewSize.width
        let centerY = (1 - rect.origin.y - rect.height / 2) * viewSize.height
        return CGPoint(x: centerX, y: centerY)
    }

    /// Returns the circle diameter to comfortably surround the "47" text.
    private func circleDiameter(_ rect: CGRect, in viewSize: CGSize) -> CGFloat {
        let width = rect.width * viewSize.width
        let height = rect.height * viewSize.height
        return max(width, height) * 2.0
    }
}
