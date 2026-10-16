import SwiftUI

/// Semantic, adaptive color palette supporting both Dark and Light modes.
public enum AppColors {
    // Brand Gradients
    public static let brandPrimary = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.50, green: 0.55, blue: 0.97, alpha: 1.0) // Indigo 400
                : UIColor(red: 0.39, green: 0.40, blue: 0.95, alpha: 1.0) // Indigo 600
        }
    )

    public static let brandSecondary = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.75, green: 0.42, blue: 0.98, alpha: 1.0) // Purple 400
                : UIColor(red: 0.58, green: 0.20, blue: 0.92, alpha: 1.0) // Purple 600
        }
    )

    // Status Colors
    public static let statusConnected = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.20, green: 0.83, blue: 0.60, alpha: 1.0) // Emerald 400
                : UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0) // Emerald 500
        }
    )

    public static let statusConnecting = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0) // Amber 400
                : UIColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0) // Amber 500
        }
    )

    public static let statusDisconnected = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.97, green: 0.44, blue: 0.44, alpha: 1.0) // Red 400
                : UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0) // Red 500
        }
    )

    public static let hangupRed = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1.0)
                : UIColor(red: 0.88, green: 0.15, blue: 0.15, alpha: 1.0)
        }
    )

    // Adaptive Surfaces & Materials
    public static let surfaceBackground = Color(uiColor: .systemBackground)
    public static let surfaceSecondary = Color(uiColor: .secondarySystemBackground)
    public static let surfaceTertiary = Color(uiColor: .tertiarySystemBackground)
    public static let surfaceGlass = Color(uiColor: .systemBackground).opacity(0.80)

    // Text & Labels
    public static let textPrimary = Color(uiColor: .label)
    public static let textSecondary = Color(uiColor: .secondaryLabel)
    public static let textTertiary = Color(uiColor: .tertiaryLabel)
}
