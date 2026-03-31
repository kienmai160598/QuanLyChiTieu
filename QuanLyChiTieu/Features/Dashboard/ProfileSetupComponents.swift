import SwiftUI
import SwiftData

// MARK: - Constants

private enum ProfileLayout {
    static let avatarSize: CGFloat = 88
}

// MARK: - Avatar Section

internal struct ProfileAvatarSection: View {
    internal let viewModel: ProfileSetupViewModel
    internal let authService: AuthService

    internal var body: some View {
        VStack(spacing: Spacing.md) {
            avatarImage
            VStack(spacing: Spacing.xxs) {
                Text(
                    viewModel.name.isEmpty
                        ? String(localized: "Chưa thiết lập")
                        : viewModel.name
                )
                .font(Typography.titleMedium)
                .foregroundStyle(Color.onSurface)

                if let email = authService.currentUserEmail {
                    Text(email)
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.md)
    }

    private var avatarImage: some View {
        Group {
            if let url = authService.currentUserPhotoURL {
                AsyncImage(url: url) { phase in
                    if case .success(let img) = phase {
                        img.resizable().scaledToFill()
                    } else {
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: ProfileLayout.avatarSize, height: ProfileLayout.avatarSize)
        .clipShape(Circle())
        .accessibilityLabel(String(localized: "Ảnh đại diện"))
    }

    private var fallbackAvatar: some View {
        let initial: String = {
            guard let c = viewModel.name.trimmingCharacters(
                in: .whitespaces
            ).first else { return "?" }
            return String(c).uppercased()
        }()
        return Circle()
            .fill(Color.appPrimary)
            .overlay {
                Text(initial)
                    .font(Typography.displaySmall)
                    .foregroundStyle(Color.onPrimary)
            }
    }
}

// MARK: - Personal Info Card

internal struct PersonalInfoCard: View {
    @Binding internal var viewModel: ProfileSetupViewModel
    internal let focusedField: FocusState<ProfileSetupView.Field?>.Binding

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ProfileCardHeader(title: String(localized: "Thông tin cá nhân"))
            VStack(spacing: 0) {
                NameRow(viewModel: $viewModel, focusedField: focusedField)
                Divider()
                GenderRow(viewModel: $viewModel)
                Divider()
                BirthdayRow(viewModel: $viewModel)
            }
            .padding(Spacing.md)
            .background(Color.surfaceContainer.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
            .padding(Spacing.sm)
            .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.sm)
        }
    }
}

internal struct NameRow: View {
    @Binding internal var viewModel: ProfileSetupViewModel
    internal let focusedField: FocusState<ProfileSetupView.Field?>.Binding

    internal var body: some View {
        HStack {
            Text(String(localized: "Họ và tên"))
            Spacer()
            TextField(String(localized: "Nhập tên"), text: $viewModel.name)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.onSurfaceVariant)
                .focused(focusedField, equals: .name)
                .submitLabel(.done)
        }
        .padding(.vertical, Spacing.sm)
    }
}

internal struct GenderRow: View {
    @Binding internal var viewModel: ProfileSetupViewModel

    internal var body: some View {
        Picker(
            String(localized: "Giới tính"),
            selection: $viewModel.selectedGender
        ) {
            Text(String(localized: "Không chọn")).tag(Gender?.none)
            ForEach(Gender.allCases, id: \.self) { g in
                Text(g.displayName).tag(Gender?.some(g))
            }
        }
        .pickerStyle(.menu)
        .tint(
            viewModel.selectedGender == nil
                ? Color.onSurfaceVariant
                : Color.appSecondary
        )
        .padding(.vertical, Spacing.sm)
    }
}

internal struct BirthdayRow: View {
    @Binding internal var viewModel: ProfileSetupViewModel

    internal var body: some View {
        HStack {
            Text(String(localized: "Ngày sinh"))
            Spacer()
            if viewModel.hasBirthday {
                DatePicker(
                    "",
                    selection: $viewModel.birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(Color.appSecondary)
            } else {
                Button(String(localized: "Chọn ngày")) {
                    viewModel.hasBirthday = true
                }
                .foregroundStyle(Color.onSurfaceVariant)
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Contact Card

internal struct ContactCard: View {
    @Binding internal var viewModel: ProfileSetupViewModel
    internal let authService: AuthService
    internal let focusedField: FocusState<ProfileSetupView.Field?>.Binding

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ProfileCardHeader(title: String(localized: "Liên hệ"))
            VStack(spacing: 0) {
                PhoneRow(viewModel: $viewModel, focusedField: focusedField)
                if authService.currentUserEmail != nil {
                    Divider()
                    EmailRow(authService: authService)
                }
            }
            .padding(Spacing.md)
            .background(Color.surfaceContainer.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
            .padding(Spacing.sm)
            .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.sm)
        }
    }
}

internal struct PhoneRow: View {
    @Binding internal var viewModel: ProfileSetupViewModel
    internal let focusedField: FocusState<ProfileSetupView.Field?>.Binding

    internal var body: some View {
        HStack {
            Text(String(localized: "Số điện thoại"))
            Spacer()
            TextField(String(localized: "Nhập số"), text: $viewModel.phoneNumber)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.onSurfaceVariant)
                .keyboardType(.phonePad)
                .focused(focusedField, equals: .phone)
        }
        .padding(.vertical, Spacing.sm)
    }
}

internal struct EmailRow: View {
    internal let authService: AuthService

    internal var body: some View {
        if let email = authService.currentUserEmail {
            HStack {
                Text(String(localized: "Email"))
                Spacer()
                Text(email).foregroundStyle(Color.onSurfaceVariant)
            }
            .padding(.vertical, Spacing.sm)
        }
    }
}

// MARK: - Provider Card

internal struct ProviderCard: View {
    internal let authService: AuthService

    internal var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ProfileCardHeader(title: String(localized: "Tài khoản"))
            VStack(spacing: 0) {
                HStack {
                    Text(String(localized: "Nhà cung cấp"))
                    Spacer()
                    Text(providerLabel).foregroundStyle(Color.onSurfaceVariant)
                }
                .padding(.vertical, Spacing.sm)
            }
            .padding(Spacing.md)
            .background(Color.surfaceContainer.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
            .padding(Spacing.sm)
            .m3Card(cornerRadius: Spacing.cornerMedium + Spacing.sm)
        }
    }

    private var providerLabel: String {
        switch authService.currentProviderID {
        case "apple": "Apple"
        case "google": "Google"
        default: String(localized: "Không rõ")
        }
    }
}

// MARK: - Save Button & Card Header

internal struct ProfileSaveButton: View {
    internal let viewModel: ProfileSetupViewModel
    internal let onSave: () -> Void

    internal var body: some View {
        Button { onSave() } label: {
            Text(String(localized: "Lưu"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color.appPrimary, in: .capsule)
        }
        .buttonStyle(ExpressivePressStyle())
        .disabled(!viewModel.isNameValid)
    }
}

internal struct ProfileCardHeader: View {
    internal let title: String

    internal var body: some View {
        Text(title)
            .font(Typography.titleMedium)
            .foregroundStyle(Color.onSurface)
            .padding(.bottom, Spacing.sm)
    }
}
