import SwiftUI
import PhotosUI

struct PendingReview: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
    let sourceType: String

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
    @State private var showingScanner = false
    @State private var isLiveDetectorMode = false

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
        .navigationTitle("Capture")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            cameraService.checkPermission()
        }
        .fullScreenCover(item: $pendingReview) { review in
            NavigationStack {
                PhotoReviewView(image: review.image, sourceType: review.sourceType)
            }
        }
        .sheet(isPresented: $showingScanner) {
            LibraryScannerView()
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        ZStack {
            // Camera preview — always present, shared between modes
            CameraPreviewView(session: cameraService.session)
                .ignoresSafeArea()

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

            // Mode toggle at top
            VStack {
                modeToggle
                    .padding(.top, 8)
                Spacer()
            }
        }
        .onAppear {
            cameraService.configureSession()
            cameraService.startSession()
            // Set video delegate once — stays set forever, gated by isActive flag
            cameraService.setVideoDelegate(detectorService, queue: detectorService.processingQueue)
        }
        .onDisappear {
            cameraService.stopSession()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "Photo", icon: "camera.fill", isSelected: !isLiveDetectorMode) {
                withAnimation(.easeInOut(duration: 0.2)) { isLiveDetectorMode = false }
            }
            modeButton(title: "Live Detect", icon: "viewfinder", isSelected: isLiveDetectorMode) {
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
        HStack(spacing: 40) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: 4) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                    Text("Pick Photo")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadFromLibrary(newItem) }
            }

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

            Button {
                showingScanner = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial, in: Circle())
                    Text("Scan Library")
                        .font(.caption2)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Permission Views

    private var permissionRequestView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Camera Access")
                .font(.title2.bold())
            Text("Spot47 needs camera access to capture your 47 sightings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Enable Camera") {
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
            Text("Camera Access Denied")
                .font(.title2.bold())
            Text("Enable camera access in Settings to capture photos directly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button("Open Settings") {
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
                Label("Pick Photo", systemImage: "photo.on.rectangle.angled")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadFromLibrary(newItem) }
            }

            Button {
                showingScanner = true
            } label: {
                Label("Scan Library", systemImage: "magnifyingglass")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
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

        pendingReview = PendingReview(image: image, sourceType: "library")
        selectedItem = nil
    }
}

#Preview {
    NavigationStack {
        CaptureView()
    }
    .modelContainer(PreviewSampleData.previewContainer)
}
