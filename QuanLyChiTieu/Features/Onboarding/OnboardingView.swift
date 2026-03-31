import SwiftUI

internal struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    internal var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                TabView(selection: $viewModel.currentPage) {
                    LanguagePage(viewModel: viewModel)
                        .tag(0)
                    WelcomePage(viewModel: viewModel)
                        .tag(1)
                    NamePage(viewModel: viewModel)
                        .tag(2)
                    BudgetPage(viewModel: viewModel)
                        .tag(3)
                    AllSetPage(viewModel: viewModel)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar(geo)
            }
            .overlay(alignment: .topTrailing) {
                skipButton(topInset: geo.safeAreaInsets.top)
            }
            .ignoresSafeArea()
        }
    }
}

// MARK: - Skip Button

private extension OnboardingView {
    @ViewBuilder
    func skipButton(topInset: CGFloat) -> some View {
        if viewModel.currentPage > 0, viewModel.currentPage < viewModel.totalPages - 1 {
            Button { viewModel.completeOnboarding() } label: {
                Text(viewModel.t("Bỏ qua", "Skip"))
                    .font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.sm)
            }
            .background(Color.surfaceContainerHigh, in: .capsule)
            .padding(.top, topInset + Spacing.sm)
            .padding(.trailing, Spacing.lg)
            .transition(.opacity)
            .accessibilityLabel(viewModel.t("Bỏ qua hướng dẫn", "Skip onboarding"))
        }
    }
}

// MARK: - Persistent Bottom Bar

private extension OnboardingView {
    func bottomBar(_ geo: GeometryProxy) -> some View {
        VStack(spacing: Spacing.lg) {
            pageDots
            ctaButton
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, bottomPadding(geo))
    }
}

// MARK: - Page Dots

private extension OnboardingView {
    var pageDots: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.currentPage ? Color.appPrimary : Color.outlineVariant.opacity(0.5))
                    .frame(width: index == viewModel.currentPage ? Spacing.xl : Spacing.sm, height: Spacing.sm)
                    .animation(reduceMotion ? nil : Motion.spatialDefault, value: viewModel.currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.t(
            "Trang \(viewModel.currentPage + 1) trên \(viewModel.totalPages)",
            "Page \(viewModel.currentPage + 1) of \(viewModel.totalPages)"
        ))
    }
}

// MARK: - CTA Button

private extension OnboardingView {
    var ctaButton: some View {
        Button { ctaAction() } label: {
            HStack(spacing: Spacing.sm) {
                Text(ctaLabel)
                    .font(Typography.titleSmall)
                    .fontWeight(.semibold)
                Image(systemName: ctaIcon)
                    .font(Typography.titleSmall)
            }
            .foregroundStyle(Color.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentTransition(.interpolate)
        }
        .buttonStyle(ExpressivePressStyle())
        .background(Color.appPrimary, in: .capsule)
        .animation(reduceMotion ? nil : Motion.spatialDefault, value: viewModel.currentPage)
        .accessibilityLabel(ctaLabel)
    }

    var ctaLabel: String {
        let isLast = viewModel.currentPage == viewModel.totalPages - 1
        return isLast ? viewModel.t("Bắt đầu ngay", "Get Started") : viewModel.t("Tiếp theo", "Next")
    }

    var ctaIcon: String {
        viewModel.currentPage == viewModel.totalPages - 1 ? "paperplane.fill" : "arrow.right"
    }

    func ctaAction() {
        if viewModel.currentPage == viewModel.totalPages - 1 {
            viewModel.completeOnboarding()
        } else if reduceMotion {
            viewModel.advance()
        } else {
            withAnimation(Motion.spatialDefault) {
                viewModel.advance()
            }
        }
    }

    func bottomPadding(_ geo: GeometryProxy) -> CGFloat {
        geo.safeAreaInsets.bottom > 0 ? geo.safeAreaInsets.bottom + Spacing.sm : Spacing.xxxl
    }
}

#Preview {
    OnboardingView()
}
