import SwiftUI

// MARK: - BackTapSetupView

internal struct BackTapSetupView: View {
    @AppStorage("backTapEnabled") private var backTapEnabled = false

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                iconHero
                titleSection
                toggleCard
                instructionsCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Color.appSurface.ignoresSafeArea())
        .navigationTitle(String(localized: "Back Tap"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Icon Hero

private extension BackTapSetupView {
    private var iconHero: some View {
        Image(systemName: "iphone.rear.camera")
            .font(.system(size: 64))
            .foregroundStyle(Color.onSurfaceVariant)
            .frame(height: 120)
            .accessibilityHidden(true)
    }
}

// MARK: - Title Section

private extension BackTapSetupView {
    private var titleSection: some View {
        VStack(spacing: Spacing.sm) {
            Text(String(localized: "Thêm nhanh với Back Tap"))
                .font(Typography.headlineSmallEmphasized)
                .foregroundStyle(Color.onSurface)
            Text(String(localized: "Chạm hai lần vào mặt sau iPhone để mở nhanh màn hình thêm giao dịch"))
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
    }
}

// MARK: - Toggle Card

private extension BackTapSetupView {
    private var toggleCard: some View {
        HStack {
            Text(String(localized: "Bật Back Tap"))
                .font(Typography.bodyLargeEmphasized)
                .foregroundStyle(Color.onSurface)
            Spacer()
            Toggle("", isOn: $backTapEnabled)
                .labelsHidden()
                .tint(Color.appSecondary)
        }
        .padding(Spacing.lg)
        .m3Card(
            cornerRadius: Spacing.cornerExtraLarge,
            background: .surfaceContainerHigh
        )
    }
}

// MARK: - Instructions Card

private extension BackTapSetupView {
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(String(localized: "Hướng dẫn cài đặt"))
                .font(Typography.titleSmallEmphasized)
                .foregroundStyle(Color.onSurface)

            VStack(alignment: .leading, spacing: Spacing.md) {
                stepRow(number: 1, text: String(localized: "Mở Cài đặt iPhone"))
                stepRow(number: 2, text: String(localized: "Chọn Trợ năng → Chạm"))
                stepRow(number: 3, text: String(localized: "Chọn Chạm vào mặt sau"))
                stepRow(number: 4, text: String(localized: "Chọn Phím tắt → Chi tiêu"))
            }
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(spacing: Spacing.md) {
            Text("\(number)")
                .font(Typography.labelLargeEmphasized)
                .foregroundStyle(Color.onSurface)
                .frame(width: 32, height: 32)
                .background(
                    Color.surfaceContainerHigh,
                    in: Circle()
                )
            Text(text)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.onSurface)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BackTapSetupView()
    }
}
