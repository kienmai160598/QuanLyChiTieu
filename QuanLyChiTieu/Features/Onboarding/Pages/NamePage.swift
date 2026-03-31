import SwiftUI

// MARK: - Screen 2: Name Collection

internal struct NamePage: View {
    @Bindable internal var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var showField = false
    @State private var hasAnimated = false
    @FocusState private var isNameFocused: Bool

    internal var body: some View {
        GeometryReader { geo in
            ZStack {
                onboardingGradient
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.safeAreaInsets.top + OnboardingLayout.topOffsetLarge)
                    header
                    Spacer().frame(height: OnboardingLayout.sectionGap)
                    nameField
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, OnboardingLayout.bottomBarOffset)
            }
            .ignoresSafeArea()
        }
        .task(id: viewModel.currentPage) {
            guard viewModel.currentPage == 2, !hasAnimated else { return }
            hasAnimated = true
            animateEntry()
        }
    }
}

// MARK: - Background

private extension NamePage {
    var onboardingGradient: some View {
        ZStack {
            Color.appSurface
            Ellipse()
                .fill(Color.blobPurple.opacity(0.5))
                .frame(width: 400, height: 400)
                .blur(radius: 85)
                .offset(x: 100, y: -200)
            Ellipse()
                .fill(Color.blobPink.opacity(0.45))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: -100, y: 150)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header

private extension NamePage {
    var header: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "person.fill")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.onPrimary)
                .frame(width: 56, height: 56)
                .background(Color.accentPurple)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))


            VStack(spacing: Spacing.xs) {
                Text(viewModel.t("B\u{1EA1}n t\u{00EA}n g\u{00EC}?", "What's your name?"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.onSurface)
                    .tracking(-0.3)

                Text(viewModel.t(
                    "\u{0110}\u{1EC3} ch\u{00FA}ng t\u{00F4}i c\u{00E1} nh\u{00E2}n ho\u{00E1} tr\u{1EA3}i nghi\u{1EC7}m cho b\u{1EA1}n",
                    "So we can personalize your experience"
                ))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }
}

// MARK: - Name Field

private extension NamePage {
    var nameField: some View {
        VStack(spacing: Spacing.md) {
            TextField(
                viewModel.t("Nh\u{1EAD}p t\u{00EA}n c\u{1EE7}a b\u{1EA1}n", "Enter your name"),
                text: $viewModel.userName
            )
            .font(Typography.bodyLarge)
            .foregroundStyle(Color.onSurface)
            .multilineTextAlignment(.center)
            .padding(Spacing.lg)
            .background(Color.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))
            .focused($isNameFocused)
            .textContentType(.name)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .accessibilityLabel(viewModel.t("T\u{00EA}n c\u{1EE7}a b\u{1EA1}n", "Your name"))
        }
        .opacity(showField ? 1 : 0)
        .offset(y: showField ? 0 : 20)
    }
}

// MARK: - Animations

private extension NamePage {
    func animateEntry() {
        guard !reduceMotion else {
            showContent = true
            showField = true
            isNameFocused = true
            return
        }
        let spring = Motion.spatialDefault
        withAnimation(spring.delay(0.1)) { showContent = true }
        withAnimation(spring.delay(0.3)) { showField = true }
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            isNameFocused = true
        }
    }
}

#Preview {
    NamePage(viewModel: OnboardingViewModel())
}
