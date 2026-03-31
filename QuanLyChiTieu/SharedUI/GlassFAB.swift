import SwiftUI

// MARK: - M3 Expressive FAB Size

internal enum FABSize: Sendable {
    case regular   // 56pt
    case medium    // 80pt
    case large     // 96pt

    internal var containerSize: CGFloat {
        switch self {
        case .regular: IconSize.containerHero
        case .medium: IconSize.fabMedium
        case .large: IconSize.fabLarge
        }
    }

    internal var iconFont: Font {
        switch self {
        case .regular: .title2.weight(.semibold)
        case .medium: .title.weight(.semibold)
        case .large: .largeTitle.weight(.semibold)
        }
    }
}

// MARK: - Floating Action Button (M3 Expressive)

internal struct GlassFAB: View {
    internal let icon: String
    internal let size: FABSize
    internal let tint: Color
    internal let action: () -> Void

    internal init(
        icon: String,
        size: FABSize = .regular,
        tint: Color = .primaryContainer,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.tint = tint
        self.action = action
    }

    internal var body: some View {
        Button {
            triggerHaptic()
            action()
        } label: {
            Image(systemName: icon)
                .font(size.iconFont)
                .foregroundStyle(Color.onPrimaryContainer)
                .frame(width: size.containerSize, height: size.containerSize)
                .background(tint, in: .circle)
        }
        .buttonStyle(ExpressivePressStyle())
        .accessibilityLabel(String(localized: "Thêm giao dịch"))
    }

    private func triggerHaptic() {
        HapticService.mediumImpact()
    }
}

// MARK: - M3 Expressive Press Style

internal struct ExpressivePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.92 : 1.0))
            .animation(
                reduceMotion ? .none : Motion.spatialFast,
                value: configuration.isPressed
            )
    }
}

// MARK: - Positioned FAB Modifier

internal extension View {
    func glassFABOverlay(
        icon: String = "plus",
        size: FABSize = .regular,
        tint: Color = .primaryContainer,
        action: @escaping () -> Void
    ) -> some View {
        safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                GlassFAB(icon: icon, size: size, tint: tint, action: action)
                    .padding(.trailing, Spacing.xl)
            }
            .padding(.bottom, Spacing.sm)
        }
    }
}

#Preview {
    Color.appSurface
        .ignoresSafeArea()
        .glassFABOverlay { }
}
