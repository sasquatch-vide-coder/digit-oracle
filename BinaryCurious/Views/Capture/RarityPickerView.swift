import SwiftUI

struct RarityPickerView: View {
    @Binding var rarityScore: Int

    private let rarityLevels: [(score: Int, label: String, color: Color)] = [
        (1, "Common", .gray),
        (2, "Uncommon", .green),
        (3, "Rare", .blue),
        (4, "Epic", .purple),
        (5, "Legendary", .orange)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rarity")
                .font(.headline)

            HStack(spacing: 6) {
                ForEach(rarityLevels, id: \.score) { level in
                    Button {
                        rarityScore = level.score
                    } label: {
                        VStack(spacing: 4) {
                            HStack(spacing: 2) {
                                ForEach(0..<level.score, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                }
                            }
                            Text(level.label)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            rarityScore == level.score
                                ? level.color.opacity(0.2)
                                : Color.secondary.opacity(0.08),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .foregroundStyle(rarityScore == level.score ? level.color : .secondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    rarityScore == level.score ? level.color : .clear,
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    RarityPickerView(rarityScore: .constant(3))
        .padding()
}
