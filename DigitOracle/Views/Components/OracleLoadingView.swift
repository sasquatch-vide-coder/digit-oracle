import SwiftUI

struct OracleLoadingView: View {
    let text: String
    @State private var glowOpacity: Double = 0.3

    init(_ text: String = "The Oracle peers into the ether\u{2026}") {
        self.text = text
    }

    var body: some View {
        VStack(spacing: 16) {
            // Gold pulsing glow orb
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.goldPrimary.opacity(glowOpacity), .goldDark.opacity(glowOpacity * 0.3), .clear],
                        center: .center,
                        startRadius: 2,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.8
                    }
                }

            Text(text)
                .font(.oracleBody())
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .italic()
        }
    }
}
