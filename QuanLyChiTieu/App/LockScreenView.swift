import SwiftUI

internal struct LockScreenView: View {
    internal let lockId: Int
    internal let onUnlock: () async -> Bool

    @State private var isAuthenticating = false
    @State private var showRetryHint = false

    internal var body: some View {
        ZStack {
            Color.appSurface
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxxl) {
                Spacer()
                brandSection
                Spacer()
                authSection
                Spacer().frame(height: Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.xxl)
        }
        .task(id: lockId) { await attemptUnlock() }
    }
}

// MARK: - Brand

private extension LockScreenView {
    var brandSection: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "wallet.bifold.fill")
                .font(Typography.displaySmall)
                .foregroundStyle(Color.appSecondary)

            Text(String(localized: "Quản Lý Chi Tiêu"))
                .font(Typography.headlineMedium)
                .foregroundStyle(Color.onSurface)
        }
    }
}

// MARK: - Auth

private extension LockScreenView {
    var authSection: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.md) {
                Image(systemName: "lock.fill")
                    .font(Typography.headlineLarge)
                    .foregroundStyle(Color.onSurfaceVariant)

                Text(String(localized: "Xác thực để tiếp tục"))
                    .font(Typography.titleMedium)
                    .foregroundStyle(Color.onSurface)
            }

            Button {
                Task { await attemptUnlock() }
            } label: {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "faceid")
                    Text(String(localized: "Mở khoá"))
                }
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
            }
            .background(Color.appPrimary, in: .capsule)
            .padding(.horizontal, Spacing.xl)
            .disabled(isAuthenticating)
            .accessibilityLabel(String(localized: "Mở khoá bằng Face ID"))

            if showRetryHint {
                Text(String(localized: "Nhấn Mở khoá để thử lại"))
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Action

private extension LockScreenView {
    func attemptUnlock() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let success = await onUnlock()
        if !success {
            showRetryHint = true
        }
    }
}

#Preview {
    LockScreenView(lockId: 0, onUnlock: { true })
}
