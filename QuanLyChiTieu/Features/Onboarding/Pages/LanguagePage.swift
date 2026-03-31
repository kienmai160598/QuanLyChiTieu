import SwiftUI

// MARK: - Screen 0: Language Selection

internal struct LanguagePage: View {
    internal let viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var showOptions = false
    @State private var hasAnimated = false

    internal var body: some View {
        GeometryReader { geo in
            ZStack {
                onboardingGradient
                VStack(spacing: 0) {
                    Spacer().frame(height: geo.safeAreaInsets.top + OnboardingLayout.topOffsetLarge)
                    header
                    Spacer().frame(height: OnboardingLayout.sectionGap)
                    languageOptions
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, OnboardingLayout.bottomBarOffset) // Bottom safe area offset for persistent bar
            }
            .ignoresSafeArea()
        }
        .task {
            guard !hasAnimated else { return }
            hasAnimated = true
            animateEntry()
        }
    }
}

// MARK: - Background

private extension LanguagePage {
    var onboardingGradient: some View {
        ZStack {
            Color.appSurface
            Ellipse()
                .fill(Color.blobBlue.opacity(0.5))
                .frame(width: 420, height: 420)
                .blur(radius: 90)
                .offset(x: -80, y: -220)
            Ellipse()
                .fill(Color.blobGreen.opacity(0.45))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 100, y: 200)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Header

private extension LanguagePage {
    var header: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "globe.americas.fill")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.onPrimary)
                .frame(width: 56, height: 56)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))


            VStack(spacing: Spacing.xs) {
                Text(viewModel.t("Chọn ngôn ngữ", "Choose Language"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.onSurface)
                    .tracking(-0.3)

                Text(viewModel.t("Chọn ngôn ngữ của bạn", "Choose your language"))
                    .font(Typography.bodyLarge)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity)
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }
}

// MARK: - Language Options

private extension LanguagePage {
    var languageOptions: some View {
        VStack(spacing: Spacing.md) {
            languageCard(code: "vi", flag: "🇻🇳",
                         nativeName: "Tiếng Việt", subtitle: "Vietnamese")
            languageCard(code: "en", flag: "🇬🇧",
                         nativeName: "English", subtitle: "Tiếng Anh")
        }
        .opacity(showOptions ? 1 : 0)
        .offset(y: showOptions ? 0 : 20)
    }

    func languageCard(
        code: String, flag: String,
        nativeName: String, subtitle: String
    ) -> some View {
        let isSelected = viewModel.selectedLanguage == code
        return Button { viewModel.selectLanguage(code) } label: {
            HStack(spacing: Spacing.lg) {
                Text(flag).font(Typography.headlineLarge)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(nativeName)
                        .font(Typography.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.onSurface)
                    Text(subtitle)
                        .font(Typography.labelMedium)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Typography.headlineSmall)
                    .foregroundStyle(isSelected ? Color.appSecondary : Color.outlineVariant)
            }
            .padding(Spacing.lg)
            .m3Card(cornerRadius: Spacing.cornerLarge)
            .animation(Motion.effectDefault, value: isSelected)
        }
        .accessibilityLabel("\(nativeName), \(subtitle)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Animations

private extension LanguagePage {
    func animateEntry() {
        guard !reduceMotion else {
            showContent = true; showOptions = true
            return
        }
        let spring = Motion.spatialDefault
        withAnimation(spring.delay(0.1)) { showContent = true }
        withAnimation(spring.delay(0.3)) { showOptions = true }
    }
}

#Preview {
    LanguagePage(viewModel: OnboardingViewModel())
}
