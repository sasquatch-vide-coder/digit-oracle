import SwiftUI

struct IlluminatedText: ViewModifier {
    let tier: Int

    func body(content: Content) -> some View {
        switch tier {
        case 5:
            // Legendary: rich ambient glow — layered blurred gold behind sharp text
            content
                .foregroundColor(.goldPrimary)
                .shadow(color: .goldPrimary.opacity(0.8), radius: 12)
                .shadow(color: .goldLight.opacity(0.4), radius: 24)
        case 4:
            // Epic: soft gold glow behind text
            content
                .foregroundColor(.goldLight)
                .shadow(color: .goldPrimary.opacity(0.5), radius: 8)
        case 3:
            // Rare: very faint candlelight glow
            content
                .foregroundColor(.goldLight)
                .shadow(color: .goldDark.opacity(0.4), radius: 4)
        default:
            content
                .foregroundColor(.goldPrimary)
        }
    }
}

extension View {
    func illuminatedText(tier: Int) -> some View {
        modifier(IlluminatedText(tier: tier))
    }
}
