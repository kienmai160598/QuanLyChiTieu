import SwiftUI

// MARK: - Screen 1: Track Expenses

internal struct WelcomePage: View {
    internal let viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showContent = false
    @State private var showCard = false
    @State private var showPills = false
    @State private var showRows: [Bool] = [false, false, false]
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
                    mockTransactionCard
                    Spacer()
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, OnboardingLayout.bottomBarOffset) // Bottom safe area offset for persistent bar
            }
            .ignoresSafeArea()
        }
        .task(id: viewModel.currentPage) {
            guard viewModel.currentPage == 1, !hasAnimated else { return }
            hasAnimated = true
            animateEntry()
        }
    }
}

// MARK: - Background

private extension WelcomePage {
    var onboardingGradient: some View {
        ZStack {
            Color.appSurface
            Ellipse()
                .fill(Color.blobPurple.opacity(0.55))
                .frame(width: 440, height: 440)
                .blur(radius: 90)
                .offset(x: -100, y: -200)
            Ellipse()
                .fill(Color.blobPink.opacity(0.4))
                .frame(width: 350, height: 350)
                .blur(radius: 75)
                .offset(x: 130, y: 80)
            Ellipse()
                .fill(Color.blobYellow.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: -40, y: 340)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Feature Header

private extension WelcomePage {
    var featureHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: "wallet.bifold.fill")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.onPrimary)
                .frame(width: 52, height: 52)
                .background(Color.appPrimary)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerLarge))


            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(viewModel.t("Theo dõi chi tiêu", "Track Expenses"))
                    .font(Typography.headlineMedium)
                    .foregroundStyle(Color.onSurface)
                    .tracking(-0.3)

                Text(viewModel.t(
                    "Ghi chép mọi khoản thu chi nhanh chóng, mọi lúc mọi nơi",
                    "Record all income and expenses quickly, anytime anywhere"
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

private extension WelcomePage {
    var featurePills: some View {
        HStack(spacing: Spacing.sm) {
            pill(icon: "bolt.fill", text: viewModel.t("Ghi nhanh", "Quick Log"),
                 tint: Color.accentGreen)
            pill(icon: "tag.fill", text: viewModel.t("Phân loại", "Categorize"),
                 tint: Color.accentBlue)
            pill(icon: "bell.fill", text: viewModel.t("Nhắc nhở", "Reminders"),
                 tint: Color.accentOrange)
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

// MARK: - Mock Transaction Card

private extension WelcomePage {
    var mockTransactionCard: some View {
        VStack(spacing: 0) {
            txRow(index: 0, icon: "fork.knife", iconBg: Color.accentOrange.opacity(0.1),
                  iconColor: Color.categoryFood,
                  name: viewModel.t("Phở bò sáng", "Morning Pho"),
                  date: viewModel.t("Hôm nay, 7:30", "Today, 7:30"),
                  amount: "-55.000 ₫", amountColor: Color.appError)
            mockDivider(visible: showRows[0])
            txRow(index: 1, icon: "car.fill", iconBg: Color.accentBlue.opacity(0.1),
                  iconColor: Color.categoryTransport,
                  name: viewModel.t("Grab đi làm", "Grab to Work"),
                  date: viewModel.t("Hôm nay, 8:15", "Today, 8:15"),
                  amount: "-32.000 ₫", amountColor: Color.appError)
            mockDivider(visible: showRows[1])
            txRow(index: 2, icon: "arrow.down.left", iconBg: Color.accentGreen.opacity(0.1),
                  iconColor: Color.appIncome,
                  name: viewModel.t("Lương tháng 3", "March Salary"),
                  date: viewModel.t("15 thg 3", "Mar 15"),
                  amount: "+15.200.000 ₫", amountColor: Color.appIncome)
        }
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
        .scaleEffect(showCard ? 1 : 0.96)
        .opacity(showCard ? 1 : 0)
        .offset(y: showCard ? 0 : 24)
    }

    func txRow(
        index: Int, icon: String, iconBg: Color, iconColor: Color,
        name: String, date: String, amount: String, amountColor: Color
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(Typography.bodyMedium)
                .foregroundStyle(iconColor)
                .frame(width: 36, height: 36)
                .background(iconBg)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(name).font(Typography.titleSmall)
                    .foregroundStyle(Color.onSurface)
                Text(date).font(Typography.labelMedium)
                    .foregroundStyle(Color.onSurfaceVariant)
            }
            Spacer()
            Text(amount).font(Typography.titleSmall)
                .fontWeight(.bold)
                .foregroundStyle(amountColor)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .opacity(showRows[index] ? 1 : 0)
        .offset(x: showRows[index] ? 0 : 16)
    }

    func mockDivider(visible: Bool) -> some View {
        Rectangle()
            .fill(Color.outlineVariant.opacity(0.3))
            .frame(height: 0.5)
            .padding(.leading, OnboardingLayout.dividerInset) // Aligned with text after icon column
            .opacity(visible ? 1 : 0)
    }
}

// MARK: - Animations

private extension WelcomePage {
    func animateEntry() {
        guard !reduceMotion else {
            showContent = true; showPills = true
            showCard = true; showRows = [true, true, true]
            return
        }
        let spring = Motion.spatialDefault
        withAnimation(spring.delay(0.1)) { showContent = true }
        withAnimation(spring.delay(0.2)) { showPills = true }
        withAnimation(spring.delay(0.35)) { showCard = true }
        for i in 0..<3 {
            withAnimation(spring.delay(0.45 + Double(i) * 0.08)) { showRows[i] = true }
        }
    }
}

#Preview {
    WelcomePage(viewModel: OnboardingViewModel())
}
