import SwiftUI

/// Dynamic Type typography system that automatically scales with user's preferred accessibility font size.
public enum AppTypography {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    public static let title = Font.system(.title, design: .rounded).weight(.bold)
    public static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
    public static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let headline = Font.system(.headline, design: .default).weight(.semibold)
    public static let body = Font.system(.body, design: .default)
    public static let callout = Font.system(.callout, design: .default)
    public static let subheadline = Font.system(.subheadline, design: .default)
    public static let footnote = Font.system(.footnote, design: .default)
    public static let caption = Font.system(.caption, design: .default)
    public static let caption2 = Font.system(.caption2, design: .default)
    public static let monospaceStats = Font.system(.caption, design: .monospaced)
}
