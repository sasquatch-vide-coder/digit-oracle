import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    var onZoomChange: ((CGFloat) -> Void)?
    /// Returns (devicePoint in 0...1 space, viewPoint in UIView coordinates)
    var onFocusTap: ((CGPoint, CGPoint) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onZoomChange: onZoomChange, onFocusTap: onFocusTap)
    }

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspect

        // Pinch-to-zoom
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        // Tap-to-focus
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tap)

        context.coordinator.previewView = view
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.previewLayer.session = session
        context.coordinator.onZoomChange = onZoomChange
        context.coordinator.onFocusTap = onFocusTap
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var onZoomChange: ((CGFloat) -> Void)?
        var onFocusTap: ((CGPoint, CGPoint) -> Void)?
        weak var previewView: CameraPreviewUIView?
        private var startZoomFactor: CGFloat = 1.0

        init(onZoomChange: ((CGFloat) -> Void)?, onFocusTap: ((CGPoint, CGPoint) -> Void)?) {
            self.onZoomChange = onZoomChange
            self.onFocusTap = onFocusTap
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let onZoomChange else { return }

            switch gesture.state {
            case .began:
                // startZoomFactor is set externally via the closure — we use gesture.scale relative to current
                startZoomFactor = 1.0 // Will be multiplied by current zoom in the closure
                onZoomChange(gesture.scale)
            case .changed:
                onZoomChange(gesture.scale)
            default:
                break
            }
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let onFocusTap, let previewView else { return }

            let viewPoint = gesture.location(in: previewView)
            let devicePoint = previewView.previewLayer.captureDevicePointConverted(fromLayerPoint: viewPoint)
            onFocusTap(devicePoint, viewPoint)
        }
    }
}

class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
