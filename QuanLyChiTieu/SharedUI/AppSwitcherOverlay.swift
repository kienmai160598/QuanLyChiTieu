import SwiftUI

// MARK: - App Switcher Overlay

internal struct AppSwitcherOverlay: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    internal var isAppLocked: Bool = false

    private var isDark: Bool { colorScheme == .dark }
    private var shouldShow: Bool { scenePhase != .active && !isAppLocked }

    internal var body: some View {
        ZStack {
            if shouldShow {
                overlayContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: shouldShow)
    }

    private var overlayContent: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                appIconView
                appTitleText
            }
        }
    }

    private var backgroundColor: Color {
        isDark ? .black : .white
    }

    private var appIconView: some View {
        Group {
            if let uiImage = UIImage(named: "AppIcon") {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(foregroundColor)
            }
        }
    }

    private var appTitleText: some View {
        Text(String(localized: "Quản Lý Chi Tiêu"))
            .font(.title2.weight(.semibold))
            .foregroundStyle(foregroundColor)
    }

    private var foregroundColor: Color { .appPrimary }
}

// MARK: - View Modifier

internal struct AppSwitcherProtectionModifier: ViewModifier {
    internal var isAppLocked: Bool = false

    internal func body(content: Content) -> some View {
        content
            .overlay { AppSwitcherOverlay(isAppLocked: isAppLocked) }
    }
}

internal extension View {
    func appSwitcherProtection(isAppLocked: Bool = false) -> some View {
        modifier(AppSwitcherProtectionModifier(isAppLocked: isAppLocked))
    }
}

#Preview("Active") {
    Text("App Content")
        .appSwitcherProtection()
}
