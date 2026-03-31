import SwiftUI
import SwiftData

internal struct AddCategorySheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    internal let editingCategory: Category?
    internal var preselectedType: TransactionType?

    @State private var viewModel = AddCategoryViewModel()
    @State private var showDiscardAlert = false

    internal var body: some View {
        NavigationStack {
            sheetContent
                .appBackground()
                .navigationTitle(viewModel.isEditing
                    ? String(localized: "Sửa danh mục")
                    : String(localized: "Thêm danh mục"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
                .toolbar { sheetToolbar }
                .task { loadEditingCategory() }
                .discardGuard(hasChanges: viewModel.hasChanges, showAlert: $showDiscardAlert)
        }
    }

    private func loadEditingCategory() {
        if let editingCategory {
            viewModel.loadForEdit(editingCategory)
        } else if let preselectedType {
            viewModel.selectedType = preselectedType
        }
    }

    @ToolbarContentBuilder
    private var sheetToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(String(localized: "Hu\u{1EF7}")) {
                if viewModel.hasChanges {
                    showDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Sheet Content

private extension AddCategorySheet {
    private var sheetContent: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                nameSection
                typeSection
                iconSection
                colorSection
                errorBanner
                saveButton
            }
            .padding(Spacing.lg)
        }
    }
}

// MARK: - Name Input

private extension AddCategorySheet {
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "T\u{00EA}n danh m\u{1EE5}c"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(
                String(localized: "\u{0110}\u{1EB7}t t\u{00EA}n danh m\u{1EE5}c"),
                text: $viewModel.name
            )
            .font(Typography.bodyLarge)
            .padding(Spacing.md)
            .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
        }
    }
}

// MARK: - Type Picker

private extension AddCategorySheet {
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Lo\u{1EA1}i"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            Picker(String(localized: "Lo\u{1EA1}i"), selection: $viewModel.selectedType) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Icon Picker

private extension AddCategorySheet {
    private static let availableIcons: [String] = [
        "fork.knife", "car.fill", "bag.fill", "heart.fill",
        "house.fill", "book.fill", "gamecontroller.fill", "gift.fill",
        "banknote.fill", "doc.text.fill", "cross.fill", "airplane",
        "tram.fill", "cart.fill", "graduationcap.fill", "paintbrush.fill",
        "wrench.fill", "music.note", "film.fill", "person.2.fill"
    ]

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "Bi\u{1EC3}u t\u{01B0}\u{1EE3}ng"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            iconGrid
        }
    }

    private var iconGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5),
            spacing: Spacing.sm
        ) {
            ForEach(Self.availableIcons, id: \.self) { icon in
                iconCell(icon)
            }
        }
        .padding(Spacing.md)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private func iconCell(_ icon: String) -> some View {
        let isSelected = viewModel.selectedIcon == icon
        return Button {
            viewModel.selectedIcon = icon
        } label: {
            Image(systemName: icon)
                .font(Typography.titleMedium)
                .foregroundStyle(isSelected ? Color.onPrimary : Color.onSurface)
                .frame(width: IconSize.containerXL, height: IconSize.containerXL)
                .background(isSelected ? Color.appPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerSmall))
        }
        .accessibilityLabel(icon)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Color Picker

private extension AddCategorySheet {
    private static let presetColors: [String] = [
        "#D7A49A", "#A4B1BA", "#B5B89A", "#E4C9B6", "#E1DAD3",
        "#C4877D", "#8A97A0", "#8A9A72", "#C4A890", "#3D3633",
    ]

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(String(localized: "M\u{00E0}u s\u{1EAF}c"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurfaceVariant)
            colorGrid
        }
    }

    private var colorGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: 5),
            spacing: Spacing.sm
        ) {
            ForEach(Self.presetColors, id: \.self) { hex in
                colorCell(hex)
            }
        }
        .padding(Spacing.md)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .surfaceContainerHigh)
    }

    private func colorCell(_ hex: String) -> some View {
        let isSelected = viewModel.selectedColorHex == hex
        return Button {
            viewModel.selectedColorHex = hex
        } label: {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 36, height: 36)
                .overlay {
                    if isSelected {
                        Circle()
                            .strokeBorder(Color.onSurface, lineWidth: 2.5)
                    }
                }
        }
        .accessibilityLabel(hex)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Error & Save

private extension AddCategorySheet {
    private var errorBanner: some View {
        ErrorBannerView(message: viewModel.errorMessage)
    }

    private var saveButton: some View {
        let label = viewModel.isEditing
            ? String(localized: "L\u{01B0}u thay \u{0111}\u{1ED5}i")
            : String(localized: "T\u{1EA1}o danh m\u{1EE5}c")
        return GlassSaveButton(label: label, isEnabled: viewModel.canSave) { save() }
    }

    private func save() {
        let success = viewModel.save(context: context)
        if success {
            HapticService.success()
            dismiss()
        }
    }
}
