import SwiftUI

struct ScanResultCard: View {
    let result: LibraryScanResult

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: result.thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(minHeight: 120)
                    .clipped()

                Label("\(result.detection.ocr.matchCount)× revelation\(result.detection.ocr.matchCount.pluralSuffix)", systemImage: "sparkles")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.textPrimary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.goldDark, in: Capsule())
                    .padding(6)
            }

            if let date = result.creationDate {
                HStack {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
