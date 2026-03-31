import SwiftUI

// MARK: - Reusable capsule-shaped progress bar (M3 Expressive)

/// M3E: thicker default (8pt), animated fill with spatial spring.
internal struct CapsuleProgressBar: View {
    internal let progress: Double
    internal let tint: Color
    internal var height: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.outlineVariant.opacity(0.3))
                Capsule()
                    .fill(tint)
                    .frame(width: geo.size.width * clampedProgress)
                    .animation(
                        reduceMotion ? .none : Motion.spatialDefault,
                        value: progress
                    )
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private var clampedProgress: CGFloat {
        min(max(progress, 0), 1)
    }
}
