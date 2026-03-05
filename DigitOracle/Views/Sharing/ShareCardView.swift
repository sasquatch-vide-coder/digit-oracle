import SwiftUI

// MARK: - Hardcoded colors for ImageRenderer (asset catalog colors can fail in offscreen render)

private enum CardColor {
    static let bgPrimary = Color(red: 0.051, green: 0.043, blue: 0.078)
    static let bgSecondary = Color(red: 0.102, green: 0.082, blue: 0.145)
    static let gold = Color(red: 0.788, green: 0.659, blue: 0.298)
    static let goldDark = Color(red: 0.545, green: 0.451, blue: 0.196)
    static let goldLight = Color(red: 0.910, green: 0.831, blue: 0.545)
    static let textPrimary = Color(red: 0.910, green: 0.878, blue: 0.816)
    static let textSecondary = Color(red: 0.620, green: 0.584, blue: 0.537)

    static func rarity(for score: Int) -> Color {
        switch score {
        case 1: goldDark
        case 2: gold
        case 3: goldLight
        case 4: goldLight
        case 5: gold
        default: goldDark
        }
    }

    static let shimmer = LinearGradient(
        colors: [goldDark, gold, goldLight],
        startPoint: .leading,
        endPoint: .trailing
    )
}

struct ShareCardView: View {
    let sighting: Sighting
    let image: UIImage

    private let cardWidth: CGFloat = 440
    private let cardCorner: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            // Clean photo — full image, no cropping
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: cardWidth)

            // Bottom panel with all info
            VStack(alignment: .leading, spacing: 12) {
                // Number + Rarity on same line
                HStack(alignment: .firstTextBaseline) {
                    Text("\(TrackedNumberService.shared.primaryNumber)")
                        .font(.custom("Didot", size: 52).bold())
                        .foregroundStyle(CardColor.gold)
                        .shadow(color: CardColor.gold.opacity(0.5), radius: 8)

                    Spacer()

                    Text(OracleTextService.tierLabel(for: sighting.rarityScore))
                        .font(.custom("Georgia", size: 18).bold())
                        .foregroundStyle(CardColor.rarity(for: sighting.rarityScore))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(CardColor.bgSecondary, in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(CardColor.rarity(for: sighting.rarityScore).opacity(0.5), lineWidth: 1.5)
                        )
                }

                // Notes
                if !sighting.notes.isEmpty {
                    Text(sighting.notes)
                        .font(.custom("Georgia", size: 18))
                        .foregroundStyle(CardColor.textPrimary)
                        .lineLimit(2)
                }

                // Gold divider
                Rectangle()
                    .fill(CardColor.shimmer)
                    .frame(height: 1)
                    .opacity(0.4)

                // Category + Location
                VStack(alignment: .leading, spacing: 6) {
                    if let category = sighting.category {
                        Label(category.capitalized, systemImage: SightingCategory(rawValue: category)?.iconName ?? "tag.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CardColor.textSecondary)
                    }

                    if let location = sighting.locationName {
                        Label(location, systemImage: "mappin")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(CardColor.textSecondary)
                            .lineLimit(1)
                    }
                }

                // Date + Branding
                HStack {
                    Text(sighting.captureDate.formatted(date: .long, time: .omitted))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(CardColor.textSecondary.opacity(0.7))

                    Spacer()

                    Image(systemName: "eye")
                        .font(.system(size: 12))
                        .foregroundStyle(CardColor.goldDark)
                    Text("Digit Oracle")
                        .font(.custom("Cinzel", size: 13).weight(.semibold))
                        .foregroundStyle(CardColor.shimmer)
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .frame(width: cardWidth, alignment: .leading)
            .background(CardColor.bgPrimary)
        }
        .frame(width: cardWidth)
        .clipShape(RoundedRectangle(cornerRadius: cardCorner))
        .overlay(
            RoundedRectangle(cornerRadius: cardCorner)
                .stroke(CardColor.goldDark.opacity(0.4), lineWidth: 1.5)
        )
        .background(CardColor.bgPrimary)
    }

}
