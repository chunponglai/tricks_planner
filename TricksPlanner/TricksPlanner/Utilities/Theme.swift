import SwiftUI

enum Theme {
    static let background = LinearGradient(
        colors: [
            Color(.systemBackground),
            Color(.secondarySystemBackground)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = Color(.secondarySystemBackground)
    static let cardBorder = Color(.separator).opacity(0.4)
    static let accent = Color(red: 0.18, green: 0.47, blue: 0.96)
    static let accentSecondary = Color(red: 0.12, green: 0.64, blue: 0.58)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static func titleFont(size: CGFloat) -> Font {
        .custom("AvenirNext-DemiBold", size: size)
    }

    static func bodyFont(size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size)
    }
}
