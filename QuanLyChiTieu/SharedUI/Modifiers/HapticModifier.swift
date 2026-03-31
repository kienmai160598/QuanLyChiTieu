import SwiftUI

// MARK: - Haptic Feedback Modifier

/// Triggers haptic feedback when the observed trigger value changes.
/// UIKit: haptic feedback requires UIImpactFeedbackGenerator
internal struct HapticModifier: ViewModifier {
    internal let style: UIImpactFeedbackGenerator.FeedbackStyle
    internal let trigger: Bool

    internal func body(content: Content) -> some View {
        content
            .onChange(of: trigger) { _, _ in
                let generator = UIImpactFeedbackGenerator(style: style)
                generator.impactOccurred()
            }
    }
}

// MARK: - View Extension

internal extension View {
    /// Adds haptic feedback that fires each time `trigger` changes.
    ///
    /// - Parameters:
    ///   - style: The impact feedback intensity. Defaults to `.medium`.
    ///   - trigger: A boolean whose changes trigger the haptic.
    func hapticFeedback(
        _ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        trigger: Bool
    ) -> some View {
        modifier(HapticModifier(style: style, trigger: trigger))
    }
}

#Preview {
    @Previewable @State var tapped = false

    Button("Nhấn để rung") {
        tapped.toggle()
    }
    .hapticFeedback(.medium, trigger: tapped)
}
