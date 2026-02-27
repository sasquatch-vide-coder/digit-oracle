import AVFoundation
import Vision
import CoreVideo

@Observable
final class LiveDetectorService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var currentDetections: [CGRect] = []
    var matchCount: Int = 0
    var detectionTriggered = false
    var isInCooldown = false
    var cooldownRemaining: TimeInterval = 0

    var onDetection: (() -> Void)?
    var isActive = false
    var cameraPosition: AVCaptureDevice.Position = .back

    let processingQueue = DispatchQueue(label: "com.binarycurious.live-detector")
    private var consecutiveDetections = 0
    private var isProcessingFrame = false
    private var lastProcessTime: Date = .distantPast
    private var cooldownUntil: Date = .distantPast
    private var cooldownTimer: Timer?
    private var cachedPatterns: [String] = []

    /// Snapshot the current tracked-number patterns so `captureOutput` can
    /// read them without touching `@Observable` state on a background queue.
    /// Call this on the **main thread** before starting (or resuming) detection.
    func updatePatterns() {
        cachedPatterns = TrackedNumberService.shared.patterns
    }

    override init() {
        super.init()
        warmUpVision()
    }

    /// Pre-loads the Vision text recognition model so the first real frame doesn't stall.
    private func warmUpVision() {
        processingQueue.async {
            let request = VNRecognizeTextRequest { _, _ in }
            request.recognitionLevel = UserDefaults.standard.bool(forKey: Constants.OCR.useFastModeKey) ? .fast : .accurate
            var pixelBuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, 1, 1, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
            guard let buffer = pixelBuffer else { return }
            let handler = VNImageRequestHandler(cvPixelBuffer: buffer)
            try? handler.perform([request])
        }
    }

    // MARK: - Cooldown

    func startCooldown() {
        let duration = UserDefaults.standard.object(forKey: Constants.LiveDetector.cooldownDurationKey) as? TimeInterval ?? Constants.LiveDetector.cooldownDuration
        let until = Date().addingTimeInterval(duration)
        cooldownUntil = until
        isInCooldown = true
        cooldownRemaining = duration

        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            let remaining = self.cooldownUntil.timeIntervalSinceNow
            if remaining <= 0 {
                self.isInCooldown = false
                self.cooldownRemaining = 0
                timer.invalidate()
            } else {
                self.cooldownRemaining = remaining
            }
        }
    }

    func reset() {
        onDetection = nil
        cooldownTimer?.invalidate()
        cooldownTimer = nil
        consecutiveDetections = 0
        currentDetections = []
        matchCount = 0
        isInCooldown = false
        cooldownRemaining = 0
        isProcessingFrame = false
        lastProcessTime = .distantPast
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isActive else { return }
        let now = Date()

        // Throttle to ~2 fps
        let throttle = UserDefaults.standard.object(forKey: Constants.LiveDetector.throttleIntervalKey) as? TimeInterval ?? Constants.LiveDetector.throttleInterval
        guard now.timeIntervalSince(lastProcessTime) >= throttle else { return }
        guard !isProcessingFrame else { return }

        isProcessingFrame = true
        lastProcessTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        let patterns = cachedPatterns
        guard !patterns.isEmpty else {
            isProcessingFrame = false
            return
        }

        let request = VNRecognizeTextRequest { [weak self] request, error in
            guard let self else { return }
            defer { self.isProcessingFrame = false }

            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                self.updateDetections([], count: 0)
                return
            }

            var detectedRects: [CGRect] = []
            var count = 0

            for observation in observations {
                guard let candidate = observation.topCandidates(1).first else { continue }
                let text = candidate.string

                for pattern in patterns {
                    var searchRange = text.startIndex..<text.endIndex
                    while let range = text.range(of: pattern, range: searchRange) {
                        count += 1
                        if let boundingBox = try? candidate.boundingBox(for: range) {
                            detectedRects.append(boundingBox.boundingBox)
                        } else {
                            detectedRects.append(observation.boundingBox)
                        }
                        searchRange = range.upperBound..<text.endIndex
                    }
                }
            }

            self.updateDetections(detectedRects, count: count)
        }

        request.recognitionLevel = UserDefaults.standard.bool(forKey: Constants.OCR.useFastModeKey) ? .fast : .accurate
        request.usesLanguageCorrection = UserDefaults.standard.bool(forKey: Constants.OCR.useLanguageCorrectionKey)

        let orientation: CGImagePropertyOrientation = cameraPosition == .front ? .leftMirrored : .right
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation)
        do {
            try handler.perform([request])
        } catch {
            isProcessingFrame = false
        }
    }

    private func updateDetections(_ rects: [CGRect], count: Int) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            if count > 0 {
                self.consecutiveDetections += 1
            } else {
                self.consecutiveDetections = 0
            }

            // Always update UI so bounding boxes show on first frame
            self.currentDetections = rects
            self.matchCount = count

            // Only auto-capture after consecutive confirmations
            let requiredFrames = UserDefaults.standard.object(forKey: Constants.LiveDetector.confirmationFramesKey) as? Int ?? Constants.LiveDetector.confirmationFrames
            if self.consecutiveDetections >= requiredFrames && !self.isInCooldown {
                self.consecutiveDetections = 0
                self.detectionTriggered.toggle()
                self.onDetection?()
            }
        }
    }
}
