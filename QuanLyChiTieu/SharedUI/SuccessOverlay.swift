import SwiftUI

// MARK: - SuccessOverlay (M3 Expressive)

/// Celebratory success badge with checkmark animation and confetti burst.
/// M3E: cornerExtraExtraLarge card, spatial spring entrance, M3 surface background.
internal struct SuccessOverlay: View {
    internal let message: String
    internal let accessibilityMessage: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var confettiTriggered = false

    internal var body: some View {
        ZStack {
            Color.onSurface.opacity(showContent ? 0.3 : 0).ignoresSafeArea()
                .animation(reduceMotion ? .none : Motion.effectDefault, value: showContent)
            ZStack {
                if !reduceMotion { confettiLayer }
                cardContent
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1 : 0)
            .animation(
                reduceMotion ? .none : Motion.spatialSlow,
                value: showContent
            )
        }
        .transition(.opacity)
        .accessibilityLabel(accessibilityMessage)
        .onAppear { showContent = true; confettiTriggered = true }
    }
}

// MARK: - Subviews

private extension SuccessOverlay {
    private var cardContent: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: IconSize.containerHero, weight: .medium))
                .foregroundStyle(Color.accentGreen)
                .symbolEffect(.appear, isActive: showContent)
            Text(message)
                .font(Typography.headlineSmallEmphasized)
                .foregroundStyle(Color.onSurface)
        }
        .padding(Spacing.xxl)
        .m3HeroCard()
    }

    private var confettiLayer: some View {
        let colors: [Color] = [
            .accentGreen, .appPrimary, .accentGreen.opacity(0.7),
            .appIncome, .accentGreen.opacity(0.5), .appPrimary.opacity(0.6),
        ]
        let sizes: [CGFloat] = [6, 5, 7, 5, 6, 4]
        return ForEach(0..<6, id: \.self) { i in
            Circle().fill(colors[i])
                .frame(width: sizes[i], height: sizes[i])
                .offset(confettiOffset(i))
                .opacity(confettiTriggered ? 0 : 0.8)
                .animation(
                    Motion.spatialDefault.delay(Double(i) * 0.04),
                    value: confettiTriggered
                )
        }
    }

    private func confettiOffset(_ index: Int) -> CGSize {
        guard confettiTriggered else { return .zero }
        let rad = CGFloat(index) * 60 * .pi / 180
        return CGSize(width: cos(rad) * 60, height: sin(rad) * 60)
    }
}
