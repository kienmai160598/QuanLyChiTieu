// MARK: - Purpose: Apple HIG-aligned spacing scale (8pt grid) with Dynamic Type support
import SwiftUI

internal enum Spacing {
    // MARK: - Base Scale (8pt grid)

    /// 4pt — tight pairs (icon + badge, label + value)
    internal static let xs: CGFloat = 4
    /// 8pt — compact groups (related items)
    internal static let sm: CGFloat = 8
    /// 12pt — inner element spacing
    internal static let md: CGFloat = 12
    /// 16pt — standard content padding (Apple HIG compact margin)
    internal static let lg: CGFloat = 16
    /// 20pt — Apple HIG standard margin (regular width)
    internal static let contentMargin: CGFloat = 20
    /// 24pt — section-to-element spacing
    internal static let xl: CGFloat = 24
    /// 32pt — section-to-section spacing
    internal static let sectionGap: CGFloat = 32
    /// 48pt — large separation

    // MARK: - Legacy Aliases

    internal static let xxs: CGFloat = 2
    internal static let xxl: CGFloat = 32
    internal static let xxxl: CGFloat = 48

    // MARK: - Corner Radii (Apple system-aligned)

    /// 4pt — badges, small indicators
    internal static let cornerExtraSmall: CGFloat = 4
    /// 8pt — chips, small controls
    internal static let cornerSmall: CGFloat = 8
    /// 12pt — icon badges, buttons
    internal static let cornerMedium: CGFloat = 12
    /// 16pt — cards, inputs
    internal static let cornerLarge: CGFloat = 16
    /// 20pt — prominent cards (matches system sheet)
    internal static let cornerExtraLarge: CGFloat = 20
    /// 28pt — hero cards
    internal static let cornerHero: CGFloat = 28
    /// 48pt — modal sheets
    internal static let cornerExtraExtraLarge: CGFloat = 48
    /// Full capsule
    internal static let cornerFull: CGFloat = 9999

    // MARK: - Touch Targets (Apple HIG minimum)

    /// 44pt — minimum tappable area
    internal static let minTouchTarget: CGFloat = 44
}

// MARK: - Dynamic Type Scaled Spacing

/// Use in views to get spacing that scales with Dynamic Type.
/// Example: `@ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = Spacing.lg`
internal struct ScaledSpacing {
    @ScaledMetric(relativeTo: .body)
    internal var xs: CGFloat = Spacing.xs

    @ScaledMetric(relativeTo: .body)
    internal var sm: CGFloat = Spacing.sm

    @ScaledMetric(relativeTo: .body)
    internal var md: CGFloat = Spacing.md

    @ScaledMetric(relativeTo: .body)
    internal var lg: CGFloat = Spacing.lg

    @ScaledMetric(relativeTo: .body)
    internal var xl: CGFloat = Spacing.xl

    @ScaledMetric(relativeTo: .body)
    internal var contentMargin: CGFloat = Spacing.contentMargin
}
