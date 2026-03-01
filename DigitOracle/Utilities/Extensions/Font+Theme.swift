import SwiftUI

extension Font {
    /// Oracle prophecy text — Cinzel Bold, 20-24pt
    static let oracleProphecy = Font.custom("Cinzel", size: 22).weight(.bold)
    static func oracleProphecy(size: CGFloat = 22) -> Font {
        .custom("Cinzel", size: size).weight(.bold)
    }

    /// Screen titles / headings — Cinzel SemiBold, 28-32pt
    static let oracleHeading = Font.custom("Cinzel", size: 28).weight(.semibold)
    static func oracleHeading(size: CGFloat = 28) -> Font {
        .custom("Cinzel", size: size).weight(.semibold)
    }

    /// Body text — Georgia, 16pt
    static let oracleBody = Font.custom("Georgia", size: 16)
    static func oracleBody(size: CGFloat = 16) -> Font {
        .custom("Georgia", size: size)
    }

    /// UI buttons/labels — SF Pro Medium, 15-17pt (system font)
    static let oracleUI = Font.system(size: 16, weight: .medium)
    static func oracleUI(size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium)
    }

    /// Large sacred number display — Didot Bold, 48-72pt
    static let sacredNumber = Font.custom("Didot", size: 64).weight(.bold)
    static func sacredNumber(size: CGFloat = 64) -> Font {
        .custom("Didot", size: size).weight(.bold)
    }

    /// Caption / metadata — System, 13pt
    static let oracleCaption = Font.system(size: 13)
}
