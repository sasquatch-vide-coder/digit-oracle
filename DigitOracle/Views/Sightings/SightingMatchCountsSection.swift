import SwiftUI

struct SightingMatchCountsSection: View {
    @Bindable var sighting: Sighting
    var onRescanComplete: (() -> Void)?
    @State private var isRescanning = false

    var body: some View {
        let counts = sighting.matchCounts
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Revelations")
                    .font(.headline)
                Spacer()
                Button {
                    Task { await rescanSighting() }
                } label: {
                    if isRescanning {
                        ProgressView()
                    } else {
                        Label("Re-divine", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                }
                .disabled(isRescanning)
            }

            if !counts.isEmpty {
                FlowLayout(spacing: 10) {
                    ForEach(counts.sorted(by: { $0.key < $1.key }), id: \.key) { number, count in
                        HStack(spacing: 6) {
                            Text(number)
                                .font(.caption.bold().monospacedDigit())
                            Text("×")
                                .font(.caption2)
                            Text("\(count)")
                                .font(.caption.bold().monospacedDigit())
                        }
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.goldDark, in: Capsule())
                    }
                }
            } else if !isRescanning {
                Text("No revelations found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func rescanSighting() async {
        let image: UIImage?
        if sighting.hasLocalFullImage {
            image = ImageStorageService.shared.loadImage(fileName: sighting.imageFileName)
        } else if let identifier = sighting.sourceIdentifier {
            image = await PhotoLibraryImageService.shared.loadFullImage(identifier: identifier)
        } else {
            image = nil
        }
        guard let image else { return }
        isRescanning = true
        let detection = await OCRService.shared.detect(in: image)
        OCRService.shared.saveDetection(detection, for: sighting.imageFileName)
        sighting.contains47 = detection.ocr.matchedNumbers.contains(47)
        sighting.matchedNumbers = detection.ocr.matchedNumbers
        sighting.matchCounts = detection.ocr.matchCounts
        sighting.rarityScore = min(max(sighting.totalMatchCount, 1), 5)
        isRescanning = false
        onRescanComplete?()
    }
}
