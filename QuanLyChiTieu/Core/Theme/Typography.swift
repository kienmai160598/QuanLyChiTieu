// MARK: - Purpose: Design token constants for typography scale (SF Rounded)
// M3 Expressive: 30 styles = 15 baseline + 15 emphasized
import SwiftUI

// SF Pro Rounded — modern, Gen-Z friendly, full Vietnamese support
// Uses text styles for Dynamic Type accessibility support
internal enum Typography {
    // MARK: - Hero (primary financial amounts)

    internal static let heroLarge = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    internal static let heroMedium = Font.system(.largeTitle, design: .rounded, weight: .bold)

    // MARK: - Display

    internal static let displayLarge = Font.system(.largeTitle, design: .rounded, weight: .regular)
    internal static let displayMedium = Font.system(.largeTitle, design: .rounded, weight: .regular)
    internal static let displaySmall = Font.system(.title, design: .rounded, weight: .bold)

    internal static let displayLargeEmphasized = Font.system(.largeTitle, design: .rounded, weight: .bold)
    internal static let displayMediumEmphasized = Font.system(.largeTitle, design: .rounded, weight: .bold)
    internal static let displaySmallEmphasized = Font.system(.title, design: .rounded, weight: .heavy)

    // MARK: - Headline

    internal static let headlineLarge = Font.system(.title, design: .rounded, weight: .bold)
    internal static let headlineMedium = Font.system(.title2, design: .rounded, weight: .heavy)
    internal static let headlineSmall = Font.system(.title3, design: .rounded, weight: .bold)

    internal static let headlineLargeEmphasized = Font.system(.title, design: .rounded, weight: .heavy)
    internal static let headlineMediumEmphasized = Font.system(.title2, design: .rounded, weight: .heavy)
    internal static let headlineSmallEmphasized = Font.system(.title3, design: .rounded, weight: .heavy)

    // MARK: - Title

    internal static let titleLarge = Font.system(.title3, design: .rounded, weight: .bold)
    internal static let titleMedium = Font.system(.body, design: .rounded, weight: .medium)
    internal static let titleSmall = Font.system(.subheadline, design: .rounded, weight: .medium)

    internal static let titleLargeEmphasized = Font.system(.title3, design: .rounded, weight: .heavy)
    internal static let titleMediumEmphasized = Font.system(.body, design: .rounded, weight: .bold)
    internal static let titleSmallEmphasized = Font.system(.subheadline, design: .rounded, weight: .bold)

    // Section header (reusable for section titles)
    internal static let sectionHeader = Font.system(.headline, design: .rounded, weight: .bold)

    // MARK: - Body

    internal static let bodyLarge = Font.system(.body, design: .rounded, weight: .regular)
    internal static let bodyMedium = Font.system(.subheadline, design: .rounded, weight: .regular)
    internal static let bodySmall = Font.system(.callout, design: .rounded, weight: .regular)

    internal static let bodyLargeEmphasized = Font.system(.body, design: .rounded, weight: .bold)
    internal static let bodyMediumEmphasized = Font.system(.subheadline, design: .rounded, weight: .bold)
    internal static let bodySmallEmphasized = Font.system(.callout, design: .rounded, weight: .bold)

    // MARK: - Label

    internal static let labelLarge = Font.system(.subheadline, design: .rounded, weight: .medium)
    internal static let labelMedium = Font.system(.caption, design: .rounded, weight: .medium)
    internal static let labelSmall = Font.system(.caption2, design: .rounded, weight: .medium)

    internal static let labelLargeEmphasized = Font.system(.subheadline, design: .rounded, weight: .bold)
    internal static let labelMediumEmphasized = Font.system(.caption, design: .rounded, weight: .bold)
    internal static let labelSmallEmphasized = Font.system(.caption2, design: .rounded, weight: .bold)
}
