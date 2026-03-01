import SwiftUI

extension Color {
    static let digitOracleAccent = Color.accentColor

    // MARK: - Backgrounds
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")

    // MARK: - Gold
    static let goldPrimary = Color("GoldPrimary")
    static let goldLight = Color("GoldLight")
    static let goldDark = Color("GoldDark")

    // MARK: - Purple
    static let purpleAccent = Color("PurpleAccent")
    static let purpleLight = Color("PurpleLight")

    // MARK: - Text
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textDimmed = Color("TextDimmed")

    // MARK: - Status
    static let successGreen = Color("SuccessGreen")
    static let errorRuby = Color("ErrorRuby")

    // MARK: - Rarity Colors
    static func rarityColor(for score: Int) -> Color {
        switch score {
        case 1: .goldDark
        case 2: .goldPrimary
        case 3: .goldLight
        case 4: .goldLight
        case 5: .goldPrimary
        default: .goldDark
        }
    }

    static func raritySecondaryColor(for score: Int) -> Color {
        switch score {
        case 4: .purpleAccent
        case 5: .purpleAccent
        default: .clear
        }
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    static let oracleGlow = LinearGradient(
        colors: [.backgroundSecondary, .backgroundTertiary],
        startPoint: .top,
        endPoint: .bottom
    )

    static let goldShimmer = LinearGradient(
        colors: [.goldDark, .goldPrimary, .goldLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let voidFade = LinearGradient(
        colors: [.backgroundPrimary, .backgroundPrimary.opacity(0)],
        startPoint: .top,
        endPoint: .bottom
    )
}
