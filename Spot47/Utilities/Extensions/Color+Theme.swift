import SwiftUI

extension Color {
    static let spot47Accent = Color.accentColor

    static func rarityColor(for score: Int) -> Color {
        switch score {
        case 1: .gray
        case 2: .green
        case 3: .blue
        case 4: .purple
        case 5: .orange
        default: .gray
        }
    }
}
