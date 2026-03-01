import SwiftUI

struct RarityBorderModifier: ViewModifier {
    let rarityScore: Int

    func body(content: Content) -> some View {
        switch rarityScore {
        case 5:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(LinearGradient.goldShimmer, lineWidth: 2.5)
                )
                .overlay(
                    CornerOrnaments(cornerRadius: 12)
                        .stroke(LinearGradient.goldShimmer, lineWidth: 1.5)
                )
        case 4:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.goldLight, lineWidth: 2)
                )
                .overlay(
                    CornerOrnaments(cornerRadius: 12)
                        .stroke(Color.purpleAccent.opacity(0.6), lineWidth: 1)
                )
        case 3:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldLight, lineWidth: 1.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldLight.opacity(0.3), lineWidth: 1)
                        .padding(-3)
                )
        case 2:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldPrimary, lineWidth: 1.5)
                )
        default:
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.goldDark, lineWidth: 1)
                )
        }
    }
}

/// Decorative corner ornaments for Epic and Legendary tiers
struct CornerOrnaments: Shape {
    let cornerRadius: CGFloat
    private let ornamentSize: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Top-left corner ornament
        addCornerOrnament(&path, at: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius), angle: 0)

        // Top-right corner ornament
        addCornerOrnament(&path, at: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius), angle: .pi / 2)

        // Bottom-right corner ornament
        addCornerOrnament(&path, at: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius), angle: .pi)

        // Bottom-left corner ornament
        addCornerOrnament(&path, at: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius), angle: .pi * 1.5)

        return path
    }

    private func addCornerOrnament(_ path: inout Path, at center: CGPoint, angle: CGFloat) {
        let s = ornamentSize
        let cos = Foundation.cos(angle)
        let sin = Foundation.sin(angle)

        func rotated(_ dx: CGFloat, _ dy: CGFloat) -> CGPoint {
            CGPoint(x: center.x + dx * cos - dy * sin, y: center.y + dx * sin + dy * cos)
        }

        // Diamond-shaped flourish
        path.move(to: rotated(-s, 0))
        path.addLine(to: rotated(-s * 0.4, -s * 0.4))
        path.addLine(to: rotated(0, -s))

        path.move(to: rotated(-s * 0.6, -s * 0.2))
        path.addLine(to: rotated(-s * 0.2, -s * 0.6))
    }
}

extension View {
    func rarityBorder(score: Int) -> some View {
        modifier(RarityBorderModifier(rarityScore: score))
    }
}
