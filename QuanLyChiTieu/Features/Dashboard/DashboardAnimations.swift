// MARK: - Purpose: Reusable animation utilities for dashboard section views
import SwiftUI

// MARK: - Staggered Entrance Modifier

/// Applies a slide-up + fade-in entrance animation with a staggered delay based on index.
/// Uses `Motion.spatialDefault` spring physics. Respects reduce-motion preference.
internal struct StaggeredEntranceModifier: ViewModifier {
    private let index: Int
    private let staggerDelay: Double

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal init(index: Int, staggerDelay: Double = 0.06) {
        self.index = index
        self.staggerDelay = staggerDelay
    }

    internal func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 20)
            .opacity(appeared ? 1 : 0)
            .animation(
                reduceMotion
                    ? .none
                    : Motion.spatialDefault.delay(Double(index) * staggerDelay),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

// MARK: - Section Entrance Modifier

/// A lighter entrance for entire sections — subtle scale + fade.
/// Uses `Motion.effectDefault` (no bounce). Respects reduce-motion preference.
internal struct SectionEntranceModifier: ViewModifier {
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.97)
            .opacity(appeared ? 1 : 0)
            .animation(
                reduceMotion ? .none : Motion.effectDefault,
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

// MARK: - View Extensions

internal extension View {
    /// Staggered slide-up + fade entrance for list items.
    /// - Parameters:
    ///   - index: The item's position in the list (0-based).
    ///   - staggerDelay: Seconds between each item's entrance.
    func staggeredEntrance(index: Int, staggerDelay: Double = 0.06) -> some View {
        modifier(StaggeredEntranceModifier(index: index, staggerDelay: staggerDelay))
    }

    /// Subtle scale + fade entrance for entire sections.
    func sectionEntrance() -> some View {
        modifier(SectionEntranceModifier())
    }
}

// MARK: - Previews

#Preview("Staggered Entrance") {
    ScrollView {
        VStack(spacing: Spacing.md) {
            ForEach(0..<5, id: \.self) { index in
                Text("Item \(index)")
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurface)
                    .padding(Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .m3Card()
                    .staggeredEntrance(index: index)
            }
        }
        .padding(Spacing.lg)
    }
    .background(Color.appSurface)
}

#Preview("Section Entrance") {
    ScrollView {
        VStack(spacing: Spacing.lg) {
            Text("Dashboard Section")
                .font(Typography.headlineSmall)
                .foregroundStyle(Color.onSurface)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sectionEntrance()

            VStack(spacing: Spacing.sm) {
                ForEach(0..<3, id: \.self) { index in
                    Text("Row \(index)")
                        .font(Typography.bodyLarge)
                        .foregroundStyle(Color.onSurface)
                        .padding(Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .m3Card()
                        .staggeredEntrance(index: index)
                }
            }
            .sectionEntrance()
        }
        .padding(Spacing.lg)
    }
    .background(Color.appSurface)
}
