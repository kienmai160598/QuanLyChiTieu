// MARK: - Purpose: Design token constants for icon sizes and icon container sizes
import SwiftUI

internal enum IconSize {
    // MARK: - Icon Font/Symbol Sizes

    /// 14pt — tiny icons (small badges, indicators)
    internal static let xs: CGFloat = 14

    /// 16pt — small icons (detail row secondary icons)
    internal static let sm: CGFloat = 16

    /// 20pt — medium icons (card header icons)
    internal static let md: CGFloat = 20

    /// 22pt — standard icons (form row leading icons)
    internal static let lg: CGFloat = 22

    /// 24pt — large icons (toolbar, navigation actions)
    internal static let xl: CGFloat = 24

    // MARK: - Icon Container Frame Sizes (width & height)

    /// 24pt — minimal icon frame
    internal static let containerXS: CGFloat = 24

    /// 28pt — small circle containers
    internal static let containerSM: CGFloat = 28

    /// 32pt — toolbar button containers
    internal static let containerMD: CGFloat = 32

    /// 40pt — icon badges (M3IconBadge default)
    internal static let containerLG: CGFloat = 40

    /// 44pt — interactive picker items, tap targets
    internal static let containerXL: CGFloat = 44

    /// 48pt — category circles, large badges
    internal static let containerXXL: CGFloat = 48

    /// 56pt — FAB regular, success overlay icons
    internal static let containerHero: CGFloat = 56

    /// 80pt — FAB medium (M3 Expressive)
    internal static let fabMedium: CGFloat = 80

    /// 96pt — FAB large (M3 Expressive)
    internal static let fabLarge: CGFloat = 96
}
