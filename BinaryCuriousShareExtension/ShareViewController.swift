import UIKit
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        extractImage()
    }

    private func extractImage() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else {
            cancel()
            return
        }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.image.identifier) { [weak self] data, _ in
                        DispatchQueue.main.async {
                            self?.handleLoadedItem(data)
                        }
                    }
                    return
                }
            }
        }

        cancel()
    }

    private func handleLoadedItem(_ data: NSSecureCoding?) {
        var image: UIImage?

        if let url = data as? URL, let loaded = UIImage(contentsOfFile: url.path) {
            image = loaded
        } else if let imageData = data as? Data, let loaded = UIImage(data: imageData) {
            image = loaded
        } else if let uiImage = data as? UIImage {
            image = uiImage
        }

        guard let finalImage = image else {
            cancel()
            return
        }

        // Downsample if needed to stay within extension memory limits
        let processed = downsampleIfNeeded(finalImage, maxDimension: 2048)
        showShareUI(image: processed)
    }

    private func showShareUI(image: UIImage) {
        let shareView = ShareExtensionView(
            image: image,
            onSave: { [weak self] notes in
                self?.saveAndDismiss(image: image, notes: notes)
            },
            onCancel: { [weak self] in
                self?.cancel()
            }
        )

        let hostingController = UIHostingController(rootView: shareView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    private func saveAndDismiss(image: UIImage, notes: String) {
        do {
            try PendingSightingService.savePending(id: UUID(), image: image, notes: notes)
        } catch {
            print("Failed to save pending sighting: \(error)")
        }
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func cancel() {
        extensionContext?.cancelRequest(withError: NSError(domain: "com.binarycurious.share", code: 0))
    }

    private func downsampleIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
