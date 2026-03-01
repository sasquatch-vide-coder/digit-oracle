import SwiftUI
import AVFoundation

// MARK: - Zoom Presets Row

struct ZoomPresetsRow: View {
    let presets: [(label: String, factor: CGFloat)]
    let currentZoom: CGFloat
    let onSelect: (CGFloat) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(presets.enumerated()), id: \.offset) { _, preset in
                let isActive = isPresetActive(preset.factor)
                Button {
                    onSelect(preset.factor)
                } label: {
                    Text("\(preset.label)×")
                        .font(.system(size: 13, weight: isActive ? .bold : .medium, design: .rounded))
                        .foregroundStyle(isActive ? .yellow : .white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(isActive ? Color.yellow.opacity(0.25) : Color.black.opacity(0.4))
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func isPresetActive(_ factor: CGFloat) -> Bool {
        abs(currentZoom - factor) < 0.05
    }
}

// MARK: - Focus + Exposure Widget

struct FocusExposureWidget: View {
    let viewPoint: CGPoint
    let exposureBias: Float
    let minBias: Float
    let maxBias: Float
    let onExposureChange: (Float) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var isVisible = true

    private let squareSize: CGFloat = 75
    private let sliderHeight: CGFloat = 120

    var body: some View {
        if isVisible {
            HStack(alignment: .center, spacing: 8) {
                // Focus square
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: squareSize, height: squareSize)

                // Exposure slider
                VStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.yellow)

                    GeometryReader { geo in
                        let range = maxBias - minBias
                        let normalized = range > 0 ? CGFloat((exposureBias - minBias) / range) : 0.5
                        let yPos = geo.size.height * (1.0 - normalized)

                        ZStack(alignment: .top) {
                            // Track
                            Capsule()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .frame(maxWidth: .infinity)

                            // Indicator
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 12, height: 12)
                                .offset(y: yPos - 6)
                        }
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let fraction = 1.0 - (value.location.y / geo.size.height)
                                    let clamped = max(0, min(1, fraction))
                                    let bias = minBias + Float(clamped) * (maxBias - minBias)
                                    onExposureChange(bias)
                                }
                        )
                    }
                    .frame(width: 20, height: sliderHeight)
                }
            }
            .position(x: viewPoint.x + 30, y: viewPoint.y)
            .transition(.opacity)
            .animation(.easeOut(duration: 0.2), value: isVisible)
        }
    }
}

// MARK: - Flash Button

struct FlashButton: View {
    let flashMode: AVCaptureDevice.FlashMode
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: flashIcon)
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }

    private var flashIcon: String {
        switch flashMode {
        case .off: return "bolt.slash"
        case .auto: return "bolt.badge.automatic"
        case .on: return "bolt.fill"
        @unknown default: return "bolt.slash"
        }
    }
}

// MARK: - Camera Flip Button

struct CameraFlipButton: View {
    let action: () -> Void
    @State private var rotationAngle: Double = 0

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                rotationAngle += 180
            }
            action()
        } label: {
            Image(systemName: "camera.rotate.fill")
                .font(.system(size: 20))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(rotationAngle))
                .contentShape(Rectangle())
        }
    }
}
