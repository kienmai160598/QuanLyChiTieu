import SwiftUI
import SwiftData

// MARK: - Edit Profile View

internal struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]
    @State private var viewModel = ProfileSetupViewModel()
    @State private var showDiscardAlert = false
    @FocusState private var focusedField: Field?

    internal enum Field { case name, phone }

    internal var body: some View {
        profileContent
            .appBackground()
            .navigationTitle(String(localized: "Chỉnh sửa hồ sơ"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(viewModel.hasChanges)
            .toolbar { backButtonToolbar }
            .toolbar { keyboardToolbar }
            .confirmationDialog(
                String(localized: "Huỷ thay đổi?"),
                isPresented: $showDiscardAlert,
                titleVisibility: .visible
            ) { discardDialogButtons }
            .alert(String(localized: "Lỗi"), isPresented: saveErrorBinding) {
                Button(String(localized: "OK"), role: .cancel) {}
            } message: {
                Text(viewModel.saveErrorMessage ?? "")
            }
            .task { await loadProfile() }
    }
}

// MARK: - Content

private extension ProfileSetupView {
    var profileContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                ProfileAvatarSection(viewModel: viewModel, authService: authService)
                PersonalInfoCard(viewModel: $viewModel, focusedField: $focusedField)
                ContactCard(viewModel: $viewModel, authService: authService, focusedField: $focusedField)
                if authService.isSignedIn { ProviderCard(authService: authService) }
                ProfileSaveButton(viewModel: viewModel) { handleSave() }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    var saveErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.saveErrorMessage != nil },
            set: { if !$0 { viewModel.saveErrorMessage = nil } }
        )
    }

    @ToolbarContentBuilder
    var keyboardToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button(String(localized: "Xong")) { focusedField = nil }
        }
    }
}

// MARK: - Actions

private extension ProfileSetupView {
    func handleSave() {
        if viewModel.saveProfile(
            profiles: profiles,
            authService: authService,
            context: modelContext
        ) {
            dismiss()
        }
    }

    func loadProfile() async {
        viewModel.loadExistingData(profiles: profiles, authService: authService)
        if viewModel.name.isEmpty { focusedField = .name }
    }
}

// MARK: - Discard Guard

private extension ProfileSetupView {
    @ToolbarContentBuilder
    var backButtonToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.hasChanges {
                Button {
                    showDiscardAlert = true
                } label: {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "chevron.backward")
                        Text(String(localized: "Quay lại"))
                    }
                }
            }
        }
    }

    @ViewBuilder
    var discardDialogButtons: some View {
        Button(String(localized: "Huỷ thay đổi"), role: .destructive) {
            dismiss()
        }
        Button(String(localized: "Tiếp tục chỉnh sửa"), role: .cancel) {}
    }
}
