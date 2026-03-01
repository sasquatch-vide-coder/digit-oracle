import SwiftUI

struct OraclePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.oracleUI())
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed ? Color.goldPrimary.opacity(0.15) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.goldPrimary, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct OracleSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.oracleUI())
            .foregroundColor(.textSecondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

struct OracleDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.oracleUI())
            .foregroundColor(.errorRuby)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                configuration.isPressed ? Color.errorRuby.opacity(0.15) : Color.clear
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.errorRuby, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
