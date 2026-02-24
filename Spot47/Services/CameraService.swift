import AVFoundation
import UIKit

@Observable
final class CameraService: NSObject {
    var capturedImage: UIImage?
    var isSessionRunning = false
    var permissionStatus: AVAuthorizationStatus = .notDetermined
    var error: CameraError?

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.spot47.camera-session")
    private var continuation: CheckedContinuation<UIImage?, Never>?

    // MARK: - Permission

    func checkPermission() {
        permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        permissionStatus = granted ? .authorized : .denied
        return granted
    }

    // MARK: - Session Configuration

    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard session.inputs.isEmpty else { return } // Already configured

            session.beginConfiguration()
            session.sessionPreset = .photo

            // Add camera input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
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
