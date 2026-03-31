// MARK: - Purpose: M3 Expressive motion tokens (spring-physics based)
import SwiftUI

internal enum Motion {
    // MARK: - Spatial Springs (position, size, shape — allows bounce)

    /// Default spatial: for standard layout animations, FAB morphing, chip selection
    internal static let spatialDefault = Animation.spring(response: 0.4, dampingFraction: 0.7)

    /// Fast spatial: for small interactive feedback (button press, toggle)
    internal static let spatialFast = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Slow spatial: for hero transitions, overlay entrance, page changes
    internal static let spatialSlow = Animation.spring(response: 0.6, dampingFraction: 0.7)

    // MARK: - Effect Springs (color, opacity, blur — no bounce)

    /// Default effect: for color/opacity changes that resolve immediately
    internal static let effectDefault = Animation.spring(response: 0.3, dampingFraction: 1.0)

    /// Fast effect: for instant state feedback (enabled/disabled, highlight)
    internal static let effectFast = Animation.spring(response: 0.15, dampingFraction: 1.0)

    // MARK: - Standard Springs (functional, no bounce)

    /// Standard: for non-expressive functional transitions
    internal static let standard = Animation.spring(response: 0.4, dampingFraction: 0.85)
}
