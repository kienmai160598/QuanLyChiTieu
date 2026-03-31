import SwiftUI

// MARK: - Screen 3: Smart Analytics

internal struct AllSetPage: View {
    internal let viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var showCard = false
    @State private var showPills = false
    @State private var showStats: [Bool] = [false, false, false]
    @State private var chartProgress: CGFloat = 0
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
                    mockAnalyticsCard
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, OnboardingLayout.bottomBarOffset) // Bottom safe area offset for persistent bar
            }
            .ignoresSafeArea()
        }
        .task(id: viewModel.currentPage) {
            guard viewModel.currentPage == 4, !hasAnimated else { return }
            hasAnimated = true
            animateEntry()
        }
    }
}

// MARK: - Background

private extension AllSetPage {
    var onboardingGradient: some View {
        ZStack {
            Color.appSurface
            Ellipse()
                .fill(Color.blobGreen.opacity(0.5))
                .frame(width: 440, height: 440)
                .blur(radius: 90)
                .offset(x: -90, y: -200)
            Ellipse()
                .fill(Color.blobPurple.opacity(0.4))
                .frame(width: 360, height: 360)
                .blur(radius: 80)
                .offset(x: 120, y: 100)
            Ellipse()
                .fill(Color.blobYellow.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -50, y: 350)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Feature Header

private extension AllSetPage {
    var featureHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.onPrimary)
                .frame(width: 52, height: 52)
                .background(Color.accentGreen)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))


            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(viewModel.t("Phân tích chi tiết", "Detailed Analytics"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.onSurface)
                    .tracking(-0.3)

                Text(viewModel.t(
                    "Biểu đồ trực quan giúp bạn hiểu rõ xu hướng chi tiêu",
                    "Visual charts help you understand your spending trends"
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

private extension AllSetPage {
    var featurePills: some View {
        HStack(spacing: Spacing.sm) {
            pill(icon: "chart.line.uptrend.xyaxis", text: viewModel.t("Xu hướng", "Trends"),
                 tint: Color.accentGreen)
            pill(icon: "target", text: viewModel.t("Mục tiêu", "Goals"),
                 tint: Color.accentBlue)
            pill(icon: "doc.fill", text: viewModel.t("Xuất PDF", "Export PDF"),
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

// MARK: - Mock Analytics Card

private extension AllSetPage {
    var mockAnalyticsCard: some View {
        VStack(spacing: Spacing.lg) {
            statsRow
            mockChart
        }
        .padding(Spacing.xl)
        .m3Card(cornerRadius: Spacing.xl)
        .scaleEffect(showCard ? 1 : 0.96)
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 24)
    }

    var statsRow: some View {
        HStack(spacing: 0) {
            statItem(index: 0,
                     label: viewModel.t("Thu nhập", "Income"),
                     amount: viewModel.t("15,2tr ₫", "15.2M ₫"),
                     trend: "+12%", trendColor: Color.appPrimary)
            Spacer()
            statItem(index: 1,
                     label: viewModel.t("Chi tiêu", "Expenses"),
                     amount: viewModel.t("8,4tr ₫", "8.4M ₫"),
                     trend: "+5%", trendColor: Color.appError)
            Spacer()
            statItem(index: 2,
                     label: viewModel.t("Tiết kiệm", "Savings"),
                     amount: viewModel.t("6,8tr ₫", "6.8M ₫"),
                     trend: "+18%", trendColor: Color.accentGreen)
        }
    }

    func statItem(
        index: Int, label: String, amount: String,
        trend: String, trendColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(Typography.labelMedium)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(amount)
                .font(Typography.titleSmall)
                .fontWeight(.bold)
                .foregroundStyle(Color.onSurface)
            Text(trend)
                .font(Typography.labelMedium)
                .fontWeight(.semibold)
                .foregroundStyle(trendColor)
        }
        .opacity(showStats[index] ? 1 : 0)
        .offset(y: showStats[index] ? 0 : 8)
    }

    var mockChart: some View {
        MockAreaChart()
            .fill(
                LinearGradient(
                    colors: [Color.appPrimary.opacity(0.2), Color.appPrimary.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .opacity(chartProgress)
            .overlay {
                MockAreaChartLine()
                    .trim(from: 0, to: chartProgress)
                    .stroke(Color.appPrimary, lineWidth: 2)
            }
            .frame(height: 80)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerSmall))
    }
}

// MARK: - Chart Shapes

private struct MockAreaChart: Shape {
    nonisolated internal func path(in rect: CGRect) -> Path {
        var path = chartLine(in: rect)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct MockAreaChartLine: Shape {
    nonisolated internal func path(in rect: CGRect) -> Path {
        chartLine(in: rect)
    }
}

private func chartLine(in rect: CGRect) -> Path {
    let w = rect.width
    let h = rect.height
    var path = Path()
    path.move(to: CGPoint(x: 0, y: h * 0.7))
    path.addCurve(
        to: CGPoint(x: w * 0.25, y: h * 0.4),
        control1: CGPoint(x: w * 0.1, y: h * 0.6),
        control2: CGPoint(x: w * 0.18, y: h * 0.3)
    )
    path.addCurve(
        to: CGPoint(x: w * 0.55, y: h * 0.5),
        control1: CGPoint(x: w * 0.35, y: h * 0.5),
        control2: CGPoint(x: w * 0.45, y: h * 0.6)
    )
    path.addCurve(
        to: CGPoint(x: w, y: h * 0.15),
        control1: CGPoint(x: w * 0.7, y: h * 0.35),
        control2: CGPoint(x: w * 0.85, y: h * 0.1)
    )
    return path
}

// MARK: - Animations

private extension AllSetPage {
    func animateEntry() {
        guard !reduceMotion else {
            showContent = true; showPills = true; showCard = true
            showStats = [true, true, true]; chartProgress = 1
            return
        }
        let spring = Motion.spatialDefault
        withAnimation(spring.delay(0.1)) { showContent = true }
        withAnimation(spring.delay(0.2)) { showPills = true }
        withAnimation(spring.delay(0.35)) { showCard = true }
        for i in 0..<3 {
            withAnimation(spring.delay(0.45 + Double(i) * 0.08)) { showStats[i] = true }
        }
        withAnimation(Motion.effectDefault.delay(0.55)) { chartProgress = 1 }
    }
}

#Preview {
    AllSetPage(viewModel: OnboardingViewModel())
}
