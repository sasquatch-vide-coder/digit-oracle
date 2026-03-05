import SwiftUI

struct OracleCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func oracleCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(OracleCardModifier(cornerRadius: cornerRadius))
    }
}
