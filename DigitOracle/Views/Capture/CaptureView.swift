import SwiftUI
import SwiftData
import PhotosUI

struct PendingReview: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let sourceType: String
    let assetIdentifier: String?

    init(image: UIImage, sourceType: String, assetIdentifier: String? = nil) {
        self.image = image
        self.sourceType = sourceType
        self.assetIdentifier = assetIdentifier
    }

    static func == (lhs: PendingReview, rhs: PendingReview) -> Bool {
        lhs.id == rhs.id
    }
}

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var cameraService = CameraService()
    @State private var detectorService = LiveDetectorService()
    @State private var selectedItem: PhotosPickerItem?
    @State private var pendingReview: PendingReview?
    @State private var isLiveDetectorMode = false
    @State private var showDuplicateAlert = false

    // Focus/exposure widget state
    @State private var focusTapViewPoint: CGPoint?
    @State private var focusWidgetVisible = false
    @State private var focusHideTask: Task<Void, Never>?

    // Pinch-to-zoom tracking
    @State private var pinchStartZoom: CGFloat = 1.0

    var body: some View {
        Group {
            switch cameraService.permissionStatus {
            case .authorized:
                cameraView
            case .denied, .restricted:
                permissionDeniedView
            default:
                permissionRequestView
            }
        }
        .navigationTitle("Summon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cameraService.checkPermission()
        }
        .fullScreenCover(item: $pendingReview) { review in
            NavigationStack {
                PhotoReviewView(image: review.image, sourceType: review.sourceType, assetIdentifier: review.assetIdentifier)
            }
        }
        .alert("Already Witnessed", isPresented: $showDuplicateAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("This vision hath already been recorded.")
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera preview — always present, shared between modes
                CameraPreviewView(
                    session: cameraService.session,
                    onZoomChange: { scale in
                        if pinchStartZoom == 1.0 && scale != 1.0 {
                            pinchStartZoom = cameraService.currentZoomFactor
                        }
                        let newZoom = pinchStartZoom * scale
                        cameraService.setZoom(newZoom)
                        if scale == 1.0 {
                            pinchStartZoom = cameraService.currentZoomFactor
                        }
                    },
                    onFocusTap: { devicePoint, viewPoint in
                        cameraService.focusAt(devicePoint)
                        showFocusWidget(at: viewPoint)
                    }
                )
                .ignoresSafeArea()

                // Mode-specific overlays
                if isLiveDetectorMode {
                    LiveDetectorView(
                        cameraService: cameraService,
                        detectorService: detectorService,
                        pendingReview: $pendingReview
                    )
                } else {
                    VStack {
                        Spacer()
                        controlBar
                            .padding(.bottom, 30)
                    }
                }

                // Shared controls overlay (both modes)
                VStack(spacing: 0) {
                    // Top bar: flash / mode toggle / flip
                    topBar
                        .padding(.top, 8)

                    Spacer()

                    // Zoom presets row — above the bottom control bar
                    if cameraService.zoomPresets.count > 1 {
                        ZoomPresetsRow(
                            presets: cameraService.zoomPresets,
                            currentZoom: cameraService.currentZoomFactor,
                            onSelect: { factor in
                                cameraService.setZoom(factor, animated: true)
                            }
                        )
                        .padding(.bottom, isLiveDetectorMode ? 100 : 120)
                    }
                }

                // Focus + exposure widget overlay
                if focusWidgetVisible, let tapPoint = focusTapViewPoint {
                    FocusExposureWidget(
                        viewPoint: tapPoint,
                        exposureBias: cameraService.exposureBias,
                        minBias: cameraService.minExposureBias,
                        maxBias: cameraService.maxExposureBias,
                        onExposureChange: { bias in
                            cameraService.setExposureBias(bias)
                            resetFocusHideTimer()
                        }
                    )
                    .allowsHitTesting(true)
                }
            }
        }
        .onAppear {
            cameraService.configureSession()
            cameraService.startSession()
            // Set video delegate once — stays set forever, gated by isActive flag
            cameraService.setVideoDelegate(detectorService, queue: detectorService.processingQueue)
            // Wire up camera switch notification for live detector
            cameraService.onReconfiguring = { isReconfiguring in
                if isReconfiguring {
                    detectorService.isActive = false
                } else {
                    detectorService.cameraPosition = cameraService.isFrontCamera ? .front : .back
                    if isLiveDetectorMode {
                        detectorService.isActive = true
                    }
                }
            }
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Flash button (hidden for front camera)
            if cameraService.isFlashAvailable && !cameraService.isFrontCamera {
                FlashButton(flashMode: cameraService.flashMode) {
                    cameraService.cycleFlashMode()
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }

            Spacer()

            modeToggle

            Spacer()

            CameraFlipButton {
                cameraService.switchCamera()
            }
        }
        .padding(.horizontal, 16)
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "Vision", icon: "camera.fill", isSelected: !isLiveDetectorMode) {
                withAnimation(.easeInOut(duration: 0.2)) { isLiveDetectorMode = false }
            }
            modeButton(title: "Scrying", icon: "viewfinder", isSelected: isLiveDetectorMode) {
                withAnimation(.easeInOut(duration: 0.2)) { isLiveDetectorMode = true }
            }
        }
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.6))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color.clear, in: Capsule())
        }
    }

    private var controlBar: some View {
        HStack {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                    Text("Choose a Vision")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadFromLibrary(newItem) }
            }

            Spacer()

            Button {
                Task { await capturePhoto() }
            } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .frame(width: 82, height: 82)
                }
            }

            Spacer()

            // Invisible counterweight to center the capture button
            Color.clear
                .frame(width: 50, height: 50)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Focus Widget

    private func showFocusWidget(at point: CGPoint) {
        focusHideTask?.cancel()
        focusTapViewPoint = point
        withAnimation(.easeIn(duration: 0.15)) {
            focusWidgetVisible = true
        }
        resetFocusHideTimer()
    }

    private func resetFocusHideTimer() {
        focusHideTask?.cancel()
        focusHideTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                focusWidgetVisible = false
            }
        }
    }

    // MARK: - Permission Views

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("The Oracle's Sight")
                .font(.title2.bold())
            Text("Digit Oracle needs camera access to divine number visions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open the Eye") {
                Task {
                    let granted = await cameraService.requestPermission()
                    if granted {
                        cameraService.configureSession()
                        cameraService.startSession()
                        cameraService.setVideoDelegate(detectorService, queue: detectorService.processingQueue)
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            importAlternative
            Spacer()
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("The Eye Is Sealed")
                .font(.title2.bold())
            Text("Enable camera access in Settings to divine number visions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Unseal in Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            importAlternative
            Spacer()
        }
    }

    private var importAlternative: some View {
        VStack(spacing: 12) {
            Text("or")
                .foregroundStyle(.secondary)

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose a Vision", systemImage: "photo.on.rectangle.angled")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadFromLibrary(newItem) }
            }
        }
    }

    // MARK: - Actions

    private func capturePhoto() async {
        guard let image = await cameraService.capturePhoto() else { return }
        pendingReview = PendingReview(image: image, sourceType: "camera")
    }

    private func loadFromLibrary(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }

        // Check if this photo has already been imported (by asset ID or perceptual hash)
        let descriptor = FetchDescriptor<Sighting>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []

        let assetID = item.itemIdentifier
        if let assetID, existing.contains(where: { $0.sourceIdentifier == assetID }) {
            selectedItem = nil
            showDuplicateAlert = true
            return
        }

        if let hash = ImageStorageService.perceptualHash(of: image),
           existing.contains(where: { $0.imageHash == hash }) {
            selectedItem = nil
            showDuplicateAlert = true
            return
        }

        pendingReview = PendingReview(image: image, sourceType: "library", assetIdentifier: assetID)
        selectedItem = nil
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
    .modelContainer(PreviewSampleData.previewContainer)
}
