import AVFoundation
import UIKit

@Observable
final class CameraService: NSObject {
    var capturedImage: UIImage?
    var isSessionRunning = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined
    var error: CameraError?

    // MARK: - Camera Controls State

    var currentZoomFactor: CGFloat = 1.0
    var zoomPresets: [(label: String, factor: CGFloat)] = [(label: "1", factor: 1.0)]
    var flashMode: AVCaptureDevice.FlashMode = .off
    var isFlashAvailable: Bool = true
    var isFrontCamera: Bool = false
    var maxZoomFactor: CGFloat = 10.0
    var minZoomFactor: CGFloat = 1.0

    var exposureBias: Float = 0.0
    var minExposureBias: Float = -2.0
    var maxExposureBias: Float = 2.0

    var focusPoint: CGPoint?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.digitoracle.camera-session")
    private var continuation: CheckedContinuation<UIImage?, Never>?
    private var currentDevice: AVCaptureDevice?
    private var currentPosition: AVCaptureDevice.Position = .back
    private var focusRevertTask: Task<Void, Never>?
    /// The raw zoom factor that corresponds to the "1x" (wide) lens.
    /// For triple/dual-wide cameras this is the first switch-over factor; otherwise 1.0.
    private var wideReferenceFactor: CGFloat = 1.0

    // MARK: - Permission

    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        permissionStatus = granted ? .authorized : .denied
        return granted
    }

    // MARK: - Device Selection

    private func bestDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        if position == .back {
            // Walk the fallback chain of virtual multi-camera devices
            if let triple = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                return triple
            }
            if let dualWide = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                return dualWide
            }
            if let dual = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                return dual
            }
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        } else {
            return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        }
    }

    private func buildZoomPresets(for device: AVCaptureDevice) {
        var presets: [(label: String, factor: CGFloat)] = []
        let minFactor = device.minAvailableVideoZoomFactor
        let switchOvers = device.virtualDeviceSwitchOverVideoZoomFactors

        // For virtual devices with an ultra-wide constituent, the first switch-over
        // is where the wide ("1x") lens activates. Use that as the reference.
        let hasUltraWide = device.deviceType == .builtInTripleCamera
            || device.deviceType == .builtInDualWideCamera
        let refFactor: CGFloat = hasUltraWide && !switchOvers.isEmpty
            ? CGFloat(truncating: switchOvers[0])
            : 1.0
        self.wideReferenceFactor = refFactor

        // Ultra-wide preset (e.g. label "0.5")
        if hasUltraWide {
            let effectiveZoom = minFactor / refFactor
            presets.append((label: formatZoomLabel(effectiveZoom), factor: minFactor))
        }

        // "1x" preset — the wide/main lens
        presets.append((label: "1", factor: refFactor))

        // "2x" preset — center crop of the 48MP wide sensor
        let twoXFactor = refFactor * 2.0
        if hasUltraWide && twoXFactor < device.maxAvailableVideoZoomFactor {
            presets.append((label: "2", factor: twoXFactor))
        }

        // Additional switch-over presets (skip the first for ultra-wide devices)
        let startIdx = hasUltraWide ? 1 : 0
        for i in startIdx..<switchOvers.count {
            let f = CGFloat(truncating: switchOvers[i])
            let effectiveZoom = f / refFactor
            // Skip if it duplicates the 2x preset
            if hasUltraWide && abs(effectiveZoom - 2.0) < 0.1 { continue }
            presets.append((label: formatZoomLabel(effectiveZoom), factor: f))
        }

        if presets.isEmpty {
            presets.append((label: "1", factor: 1.0))
        }

        let maxZoom = Swift.min(device.maxAvailableVideoZoomFactor, 15.0 * refFactor)

        // Start at "1x" (the wide lens)
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = refFactor
            device.unlockForConfiguration()
        } catch {}

        Task { @MainActor in
            self.zoomPresets = presets
            self.minZoomFactor = minFactor
            self.maxZoomFactor = maxZoom
            self.currentZoomFactor = refFactor
        }
    }

    private func formatZoomLabel(_ zoom: CGFloat) -> String {
        if zoom == floor(zoom) {
            return String(format: "%.0f", zoom)
        }
        return String(format: "%g", zoom)
    }

    // MARK: - Session Configuration

    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard session.inputs.isEmpty else { return } // Already configured

            session.beginConfiguration()
            session.sessionPreset = .photo

            // Add camera input
            guard let camera = bestDevice(for: currentPosition) else {
                self.error = .cameraUnavailable
                session.commitConfiguration()
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                } else {
                    self.error = .cannotAddInput
                    session.commitConfiguration()
                    return
                }
            } catch {
                self.error = .cannotAddInput
                session.commitConfiguration()
                return
            }

            // Add photo output
            if session.canAddOutput(photoOutput) {
                session.addOutput(photoOutput)
                photoOutput.maxPhotoQualityPrioritization = .quality
            } else {
                self.error = .cannotAddOutput
                session.commitConfiguration()
                return
            }

            // Add video data output (always present; delegate toggled on demand for live detection)
            videoDataOutput.alwaysDiscardsLateVideoFrames = true
            if session.canAddOutput(videoDataOutput) {
                session.addOutput(videoDataOutput)
            }

            session.commitConfiguration()

            self.currentDevice = camera
            self.buildZoomPresets(for: camera)

            Task { @MainActor in
                self.isFrontCamera = self.currentPosition == .front
                self.isFlashAvailable = camera.hasFlash
                self.exposureBias = camera.exposureTargetBias
                self.minExposureBias = camera.minExposureTargetBias
                self.maxExposureBias = camera.maxExposureTargetBias
            }
        }
    }

    // MARK: - Start / Stop

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !session.isRunning else { return }
            session.startRunning()
            Task { @MainActor in
                self.isSessionRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, session.isRunning else { return }
            session.stopRunning()
            Task { @MainActor in
                self.isSessionRunning = false
            }
        }
    }

    // MARK: - Video Delegate Management

    func setVideoDelegate(_ delegate: AVCaptureVideoDataOutputSampleBufferDelegate?, queue: DispatchQueue?) {
        videoDataOutput.setSampleBufferDelegate(delegate, queue: queue)
    }

    // MARK: - Zoom

    func setZoom(_ factor: CGFloat, animated: Bool = false) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }
            let maxAllowed = Swift.min(device.maxAvailableVideoZoomFactor, 15.0 * self.wideReferenceFactor)
            let clamped = Swift.max(device.minAvailableVideoZoomFactor, Swift.min(factor, maxAllowed))

            do {
                try device.lockForConfiguration()
                if animated {
                    device.ramp(toVideoZoomFactor: clamped, withRate: 8.0)
                } else {
                    device.videoZoomFactor = clamped
                }
                device.unlockForConfiguration()
                Task { @MainActor in
                    self.currentZoomFactor = clamped
                }
            } catch {}
        }
    }

    // MARK: - Flash

    func cycleFlashMode() {
        switch flashMode {
        case .off: flashMode = .auto
        case .auto: flashMode = .on
        case .on: flashMode = .off
        @unknown default: flashMode = .off
        }
    }

    // MARK: - Camera Switching

    /// Callback to notify listeners that reconfiguration is about to start / has finished.
    /// Used to pause live detection during the switch.
    var onReconfiguring: ((Bool) -> Void)?

    func switchCamera() {
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back

        sessionQueue.async { [weak self] in
            guard let self else { return }

            Task { @MainActor in
                self.onReconfiguring?(true)
            }

            session.beginConfiguration()

            // Remove existing input
            for input in session.inputs {
                session.removeInput(input)
            }

            guard let camera = bestDevice(for: newPosition) else {
                session.commitConfiguration()
                Task { @MainActor in
                    self.onReconfiguring?(false)
                }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                session.commitConfiguration()
                Task { @MainActor in
                    self.onReconfiguring?(false)
                }
                return
            }

            session.commitConfiguration()

            self.currentDevice = camera
            self.currentPosition = newPosition
            self.buildZoomPresets(for: camera)

            Task { @MainActor in
                self.isFrontCamera = newPosition == .front
                self.isFlashAvailable = camera.hasFlash
                self.currentZoomFactor = self.wideReferenceFactor
                self.flashMode = .off
                self.exposureBias = 0.0
                self.minExposureBias = camera.minExposureTargetBias
                self.maxExposureBias = camera.maxExposureTargetBias
                self.focusPoint = nil
                self.onReconfiguring?(false)
            }
        }
    }

    // MARK: - Focus

    func focusAt(_ devicePoint: CGPoint) {
        focusRevertTask?.cancel()

        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }

            do {
                try device.lockForConfiguration()

                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }

                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .autoExpose
                }

                device.unlockForConfiguration()

                Task { @MainActor in
                    self.focusPoint = devicePoint
                }
            } catch {}
        }

        // Revert to continuous auto-focus after 2 seconds
        focusRevertTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self.revertToContinuousAutoFocus()
        }
    }

    private func revertToContinuousAutoFocus() {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {}

            Task { @MainActor in
                self.focusPoint = nil
            }
        }
    }

    // MARK: - Exposure

    func setExposureBias(_ bias: Float) {
        sessionQueue.async { [weak self] in
            guard let self, let device = self.currentDevice else { return }
            let clamped = max(device.minExposureTargetBias, min(bias, device.maxExposureTargetBias))

            do {
                try device.lockForConfiguration()
                device.setExposureTargetBias(clamped)
                device.unlockForConfiguration()
                Task { @MainActor in
                    self.exposureBias = clamped
                }
            } catch {}
        }
    }

    func resetExposure() {
        setExposureBias(0.0)
    }

    // MARK: - Capture

    func capturePhoto() async -> UIImage? {
        capturedImage = nil

        return await withCheckedContinuation { continuation in
            self.continuation = continuation

            sessionQueue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: nil)
                    return
                }

                // Set the video orientation to match the device so pixels
                // are delivered in the correct orientation (not rotated).
                if let connection = self.photoOutput.connection(with: .video) {
                    let deviceOrientation = UIDevice.current.orientation
                    switch deviceOrientation {
                    case .portrait:
                        connection.videoOrientation = .portrait
                    case .portraitUpsideDown:
                        connection.videoOrientation = .portraitUpsideDown
                    case .landscapeLeft:
                        connection.videoOrientation = .landscapeRight
                    case .landscapeRight:
                        connection.videoOrientation = .landscapeLeft
                    default:
                        connection.videoOrientation = .portrait
                    }
                }

                let settings = AVCapturePhotoSettings()

                // Apply flash mode if supported
                if self.photoOutput.supportedFlashModes.contains(self.flashMode) {
                    settings.flashMode = self.flashMode
                } else {
                    settings.flashMode = .off
                }

                photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            continuation?.resume(returning: nil)
            continuation = nil
            return
        }

        Task { @MainActor in
            self.capturedImage = image
            self.continuation?.resume(returning: image)
            self.continuation = nil
        }
    }
}

// MARK: - Errors

enum CameraError: LocalizedError {
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable: "Camera is not available on this device"
        case .cannotAddInput: "Unable to configure camera input"
        case .cannotAddOutput: "Unable to configure photo output"
        }
    }
}
