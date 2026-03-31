import SwiftUI
import UIKit

// MARK: - Preferences Rows

internal extension SettingsView {
    var languageRow: some View {
        @Bindable var manager = languageManager
        return SettingsRow(
            materialIcon: .language,
            iconColor: .appSecondary,
            title: "Ngôn ngữ"
        ) {
            Picker("", selection: $manager.currentLanguage) {
                Text("Tiếng Việt").tag("vi")
                Text("English").tag("en")
            }
            .labelsHidden()
            .tint(Color.appSecondary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .onChange(of: languageManager.currentLanguage) { _, _ in
            showLanguageRestartAlert = true
        }
    }

    var notificationRow: some View {
        Toggle(isOn: notificationBinding) {
            SettingsRow(
                materialIcon: .notifications,
                iconColor: .accentOrange,
                title: LocalizedStringKey(
                    stringLiteral: String(localized: "Thông báo")
                )
            )
        }
        .tint(Color.appSecondary)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var darkModeRow: some View {
        Toggle(isOn: $isDarkMode) {
            SettingsRow(
                materialIcon: .darkMode,
                iconColor: .appTertiary,
                title: "Chế độ tối"
            )
        }
        .tint(Color.appSecondary)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var backTapRow: some View {
        NavigationLink { BackTapSetupView() } label: {
            SettingsRow(
                icon: "iphone.rear.camera",
                iconColor: .appSecondary,
                title: "Back Tap"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Security Rows

internal extension SettingsView {
    var biometricRow: some View {
        Toggle(isOn: biometricBinding) {
            SettingsRow(
                icon: viewModel.biometricIcon,
                iconColor: .appPrimary,
                title: LocalizedStringKey(viewModel.biometricTypeName)
            )
        }
        .tint(Color.appSecondary)
        .disabled(!viewModel.isBiometricAvailable)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var lockTimeoutRow: some View {
        SettingsRow(
            materialIcon: .lockClock,
            iconColor: .appSecondary,
            title: "Tự động khoá"
        ) {
            Picker("", selection: Binding(
                get: { viewModel.lockTimeoutOption },
                set: { viewModel.lockTimeoutOption = $0 }
            )) {
                ForEach(
                    SecurityConfiguration.LockTimeoutOption.allCases,
                    id: \.self
                ) { Text($0.displayName).tag($0) }
            }
            .labelsHidden()
            .tint(Color.appSecondary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Feature Rows

internal extension SettingsView {
    var budgetRow: some View {
        NavigationLink(value: DashboardRoute.budgetList) {
            SettingsRow(
                materialIcon: .payments,
                iconColor: .appSecondary,
                title: "Ngân sách"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var debtRow: some View {
        NavigationLink { DebtListView() } label: {
            SettingsRow(
                icon: "creditcard",
                iconColor: .appError,
                title: "Quản lý nợ"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var eventRow: some View {
        NavigationLink { EventListView() } label: {
            SettingsRow(
                materialIcon: .event,
                iconColor: .accentOrange,
                title: "Sự kiện"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }


    var insightsRow: some View {
        NavigationLink(value: DashboardRoute.insights) {
            SettingsRow(
                materialIcon: .barChart,
                iconColor: .appTertiary,
                title: "Thống kê"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Data Rows

internal extension SettingsView {
    var categoryRow: some View {
        NavigationLink(value: DashboardRoute.categoryManagement) {
            SettingsRow(
                materialIcon: .label,
                iconColor: .appSecondary,
                title: "Danh mục"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var exportRow: some View {
        NavigationLink { ExportView() } label: {
            SettingsRow(
                materialIcon: .share,
                iconColor: .appPrimary,
                title: "Xuất dữ liệu"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }

    var recurringRow: some View {
        NavigationLink { RecurringTransactionView() } label: {
            SettingsRow(
                materialIcon: .autorenew,
                iconColor: .appTertiary,
                title: "Giao dịch định kỳ"
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Account Rows

internal extension SettingsView {
    @ViewBuilder
    var accountActionRow: some View {
        if authService.isSignedIn {
            Button(role: .destructive) {
                Task { await viewModel.authenticateForSignOut() }
            } label: {
                SettingsRow(
                    materialIcon: .logout,
                    iconColor: .appError,
                    title: "Đăng xuất",
                    isDestructive: true
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        } else {
            Button { isShowingAuthSheet = true } label: {
                SettingsRow(
                    materialIcon: .personAdd,
                    iconColor: .appPrimary,
                    title: "Đăng nhập"
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }

    var deleteRow: some View {
        Button(role: .destructive) {
            Task { await viewModel.authenticateForReset() }
        } label: {
            SettingsRow(
                materialIcon: .delete,
                iconColor: .appError,
                title: "Xoá tất cả dữ liệu",
                isDestructive: true
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Author Card

internal extension SettingsView {
    var authorCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.sm) {
                MaterialIcon(.wallet, size: IconSize.xl)
                    .foregroundStyle(Color.appSecondary)
                Text(String(localized: "Quản Lý Chi Tiêu"))
                    .font(Typography.titleMedium)
                    .foregroundStyle(Color.onSurface)
            }
            HStack(spacing: Spacing.xs) {
                Text("Mai Trung Kiên")
                Text("·")
                phoneLink
                Text("·")
                Text("v\(viewModel.appVersion)")
            }
            .font(Typography.bodySmall)
            .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }
}

// MARK: - Bindings

internal extension SettingsView {
    var notificationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.notificationsEnabled },
            set: { _ in
                Task {
                    await viewModel.toggleNotifications()
                    if viewModel.shouldOpenSettings {
                        viewModel.clearShouldOpenSettings()
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            await UIApplication.shared.open(url)
                        }
                    }
                }
            }
        )
    }

    var biometricBinding: Binding<Bool> {
        Binding(
            get: { viewModel.faceIDEnabled },
            set: { _ in Task { await viewModel.toggleBiometric() } }
        )
    }
}

// MARK: - Private Helpers

private extension SettingsView {
    @ViewBuilder
    var phoneLink: some View {
        if let url = URL(string: "tel:0913451267") {
            Link("0913 451 267", destination: url)
                .foregroundStyle(Color.onSurfaceVariant)
                .accessibilityLabel(
                    String(localized: "Gọi điện thoại 0913 451 267")
                )
        } else {
            Text("0913 451 267")
                .foregroundStyle(Color.onSurfaceVariant)
        }
    }
}
