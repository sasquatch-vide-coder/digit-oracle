import SwiftUI

struct RarityBadge: View {
    let score: Int
    var style: Style = .compact

    enum Style {
        case compact   // List rows — capsule with stroke
        case detailed  // Detail view — illuminated text with ornamental border
    }

    var body: some View {
        switch style {
        case .compact:
            Text(OracleTextService.tierLabel(for: score))
                .font(.oracleCaption)
                .foregroundStyle(Color.rarityColor(for: score))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.backgroundSecondary, in: Capsule())
                .overlay(
                    Capsule().stroke(Color.rarityColor(for: score).opacity(0.5), lineWidth: 0.5)
                )

        case .detailed:
            Text(OracleTextService.tierLabel(for: score))
                .font(.oracleBody(size: 14))
                .illuminatedText(tier: score)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.backgroundSecondary)
                .rarityBorder(score: score)
        }
    }
}
