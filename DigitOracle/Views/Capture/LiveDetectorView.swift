import SwiftUI

struct LiveDetectorView: View {
    let cameraService: CameraService
    let detectorService: LiveDetectorService
    @Binding var pendingReview: PendingReview?

    @State private var showFlash = false
    @State private var isCapturing = false

    var body: some View {
        ZStack {
            // Detection bounding boxes
            DetectionOverlayView(detections: detectorService.currentDetections)
                .ignoresSafeArea()

            // Flash overlay
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // UI overlay
            VStack {
                statusPill
                    .padding(.top, 56)

                Spacer()

                controlBar
                    .padding(.bottom, 30)
            }
        }
        .sensoryFeedback(.success, trigger: detectorService.detectionTriggered)
        .onAppear {
            detectorService.updatePatterns()
            detectorService.isActive = true
        }
        .task {
            // Wait for camera to stabilize before enabling auto-capture
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            detectorService.onDetection = { [weak detectorService] in
                guard let detectorService else { return }
                detectorService.startCooldown()
                triggerAutoCapture()
            }
        }
        .onDisappear {
            detectorService.isActive = false
            detectorService.reset()
        }
        .onChange(of: pendingReview) { _, newValue in
            if newValue == nil {
                isCapturing = false
                detectorService.updatePatterns()
                detectorService.isActive = true
            }
        }
    }

    // MARK: - Status Pill

    private var statusPill: some View {
        Group {
            if detectorService.isInCooldown {
                let seconds = Int(ceil(detectorService.cooldownRemaining))
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                    Text("Resuming in \(seconds)s...")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            } else if detectorService.matchCount > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("The sacred digits emerge!")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.green.opacity(0.3), in: Capsule())
                .overlay(Capsule().stroke(.green, lineWidth: 1))
            } else {
                HStack(spacing: 6) {
                    scanningDot
                    Text("The Oracle peers...")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    private var scanningDot: some View {
        Circle()
            .fill(.green)
            .frame(width: 8, height: 8)
            .modifier(PulsingModifier())
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack {
            Color.clear
                .frame(width: 80, height: 40)

            Spacer()

            Button {
                Task { await manualCapture() }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 82, height: 82)
                    scanningRing
                }
            }
            .disabled(isCapturing)

            Spacer()

            Color.clear
                .frame(width: 80, height: 40)
        }
        .padding(.horizontal, 40)
    }

    private var scanningRing: some View {
        Circle()
            .trim(from: 0, to: 0.3)
            .stroke(.green, lineWidth: 3)
            .frame(width: 90, height: 90)
            .rotationEffect(.degrees(detectorService.isInCooldown ? 0 : 360))
            .animation(
                detectorService.isInCooldown
                    ? .default
                    : .linear(duration: 2).repeatForever(autoreverses: false),
                value: detectorService.isInCooldown
            )
    }

    // MARK: - Actions

    private func triggerAutoCapture() {
        guard !isCapturing else { return }
        isCapturing = true
        detectorService.isActive = false

        Task { @MainActor in
            withAnimation(.easeIn(duration: 0.1)) { showFlash = true }
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.2)) { showFlash = false }

            guard let image = await cameraService.capturePhoto() else {
                isCapturing = false
                detectorService.isActive = true
                return
            }
            pendingReview = PendingReview(image: image, sourceType: "camera")
        }
    }

    private func manualCapture() async {
        guard !isCapturing else { return }
        isCapturing = true
        detectorService.isActive = false

        guard let image = await cameraService.capturePhoto() else {
            isCapturing = false
            detectorService.isActive = true
            return
        }
        pendingReview = PendingReview(image: image, sourceType: "camera")
    }
}

// MARK: - Pulsing Animation

private struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}
