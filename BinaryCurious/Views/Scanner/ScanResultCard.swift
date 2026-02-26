import SwiftUI

struct ScanResultCard: View {
    let result: LibraryScanResult
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: result.thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(minHeight: 120)
                        .clipped()

                    // Match count badge
                    Label("\(result.ocrResult.matchCount)× match\(result.ocrResult.matchCount == 1 ? "" : "es")", systemImage: "checkmark.seal.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.green, in: Capsule())
                        .padding(6)
                }

                HStack {
                    if let date = result.creationDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.body)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
