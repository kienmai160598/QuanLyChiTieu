import SwiftUI

// MARK: - Screen 2: Smart Budgets

internal struct BudgetPage: View {
    internal let viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var showCard = false
    @State private var showPills = false
    @State private var ringProgress: CGFloat = 0
    @State private var barProgress1: CGFloat = 0
    @State private var barProgress2: CGFloat = 0
    @State private var hasAnimated = false

    internal var body: some View {
        GeometryReader { geo in
            ZStack {
                onboardingGradient
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: geo.safeAreaInsets.top + OnboardingLayout.topOffset)
                    featureHeader
                    Spacer().frame(height: Spacing.md)
                    featurePills
                    Spacer().frame(height: Spacing.xl)
                    mockBudgetCard
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, OnboardingLayout.bottomBarOffset) // Bottom safe area offset for persistent bar
            }
            .ignoresSafeArea()
        }
        .task(id: viewModel.currentPage) {
            guard viewModel.currentPage == 3, !hasAnimated else { return }
            hasAnimated = true
            animateEntry()
        }
    }
}

// MARK: - Background

private extension BudgetPage {
    var onboardingGradient: some View {
        ZStack {
            Color.appSurface
            Ellipse()
                .fill(Color.blobPink.opacity(0.55))
                .frame(width: 420, height: 420)
                .blur(radius: 85)
                .offset(x: 110, y: -180)
            Ellipse()
                .fill(Color.blobPurple.opacity(0.45))
                .frame(width: 380, height: 380)
                .blur(radius: 80)
                .offset(x: -120, y: 60)
            Ellipse()
                .fill(Color.blobYellow.opacity(0.35))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: 60, y: 360)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Feature Header

private extension BudgetPage {
    var featureHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "chart.pie.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.onPrimary)
                .frame(width: 52, height: 52)
                .background(Color.accentPink)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))


            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(viewModel.t("Ngân sách thông minh", "Smart Budgets"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.onSurface)
                    .tracking(-0.3)

                Text(viewModel.t(
                    "Đặt hạn mức chi tiêu và nhận cảnh báo khi gần vượt ngân sách",
                    "Set spending limits and get alerts when nearing your budget"
                ))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurfaceVariant)
                .lineSpacing(2)
            }
        }
        .opacity(showContent ? 1 : 0)
        .offset(y: showContent ? 0 : 20)
    }
}

// MARK: - Feature Pills

private extension BudgetPage {
    var featurePills: some View {
        HStack(spacing: Spacing.sm) {
            pill(icon: "chart.bar.fill", text: viewModel.t("Theo dõi", "Track"),
                 tint: Color.accentPink)
            pill(icon: "exclamationmark.triangle.fill", text: viewModel.t("Cảnh báo", "Alerts"),
                 tint: Color.accentOrange)
            pill(icon: "arrow.triangle.2.circlepath", text: viewModel.t("Tự động", "Auto"),
                 tint: Color.accentPurple)
        }
        .opacity(showPills ? 1 : 0)
        .offset(y: showPills ? 0 : 12)
    }

    func pill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(Typography.labelSmall)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onPrimary)
                .frame(width: 22, height: 22)
                .background(tint)
                .clipShape(Circle())
            Text(text)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(Color.onSurface)
        }
        .padding(.leading, Spacing.xs)
        .padding(.trailing, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color.surfaceContainerLow)
        .clipShape(Capsule())
    }
}

// MARK: - Mock Budget Card

private extension BudgetPage {
    var mockBudgetCard: some View {
        VStack(spacing: Spacing.xl) {
            budgetRing
            budgetBars
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.xl)
        .scaleEffect(showCard ? 1 : 0.96)
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 24)
    }

    var budgetRing: some View {
        HStack(spacing: Spacing.xl) {
            ZStack {
                Circle()
                    .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 1) {
                    Text("65%")
                        .font(Typography.headlineSmall)
                        .fontWeight(.heavy)
                        .foregroundStyle(Color.onSurface)
                    Text(viewModel.t("đã dùng", "used"))
                        .font(Typography.labelSmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(viewModel.t("Tháng 3", "March"))
                    .font(Typography.labelMedium)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.onSurfaceVariant)
                Text("7.150.000 ₫")
                    .font(Typography.headlineSmall)
                    .fontWeight(.heavy)
                    .foregroundStyle(Color.onSurface)
                Text(viewModel.t("còn 3.850.000 ₫", "3,850,000 ₫ left"))
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.appPrimary)
            }
        }
    }

    var budgetBars: some View {
        VStack(spacing: Spacing.sm) {
            budgetBar(name: viewModel.t("Ăn uống", "Food"),
                      spent: viewModel.t("3,6tr", "3.6M"),
                      limit: viewModel.t("5,0tr", "5.0M"),
                      progress: barProgress1, color: Color.categoryFood)
            budgetBar(name: viewModel.t("Di chuyển", "Transport"),
                      spent: "900K",
                      limit: viewModel.t("2,0tr", "2.0M"),
                      progress: barProgress2, color: Color.categoryTransport)
        }
    }

    func budgetBar(
        name: String, spent: String, limit: String,
        progress: CGFloat, color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: OnboardingLayout.progressBarHeight) { // ~6pt: tight label-bar gap
            HStack {
                Circle().fill(color).frame(width: Spacing.sm, height: Spacing.sm)
                Text(name)
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.onSurface)
                Spacer()
                Text("\(spent) / \(limit)")
                    .font(Typography.labelMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.outlineVariant.opacity(0.3))
                    Capsule().fill(color)
                        .frame(width: barGeo.size.width * progress)
                }
            }
            .frame(height: OnboardingLayout.progressBarHeight) // ~6pt: bar height
        }
    }
}

// MARK: - Animations

private extension BudgetPage {
    func animateEntry() {
        guard !reduceMotion else {
            showContent = true; showPills = true; showCard = true
            ringProgress = 0.65; barProgress1 = 0.72; barProgress2 = 0.45
            return
        }
        let spring = Motion.spatialDefault
        withAnimation(spring.delay(0.1)) { showContent = true }
        withAnimation(spring.delay(0.2)) { showPills = true }
        withAnimation(spring.delay(0.35)) { showCard = true }
        withAnimation(Motion.effectDefault.delay(0.5)) { ringProgress = 0.65 }
        withAnimation(Motion.effectDefault.delay(0.6)) { barProgress1 = 0.72 }
        withAnimation(Motion.effectDefault.delay(0.75)) { barProgress2 = 0.45 }
    }
}

#Preview {
    BudgetPage(viewModel: OnboardingViewModel())
}
