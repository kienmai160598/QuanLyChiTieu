import PhotosUI
import SwiftUI

// MARK: - ReceiptScanView

internal struct ReceiptScanView: View {
    @State private var viewModel = ReceiptScanViewModel()
    @State private var selectedItem: PhotosPickerItem?

    internal let onCreateTransaction: (Decimal, Date) -> Void

    internal var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                imagePickerCard
                if viewModel.selectedImage != nil {
                    scanButtonCard
                }
                resultCard
                if viewModel.canCreateTransaction {
                    createTransactionButton
                }
            }
            .padding(Spacing.lg)
        }
        .appBackground()
        .navigationTitle(String(localized: "Qu\u{00E9}t ho\u{00E1} \u{0111}\u{01A1}n"))
        .onChange(of: selectedItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }
}

// MARK: - Image Picker Card

private extension ReceiptScanView {
    private var imagePickerCard: some View {
        VStack(spacing: Spacing.md) {
            imagePreviewOrPlaceholder
            photosPickerButton
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    @ViewBuilder
    private var imagePreviewOrPlaceholder: some View {
        // UIKit: UIImage required for Vision framework processing
        if let uiImage = viewModel.selectedImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 250)
                .clipShape(RoundedRectangle(cornerRadius: Spacing.cornerMedium))
                .accessibilityLabel(String(localized: "\u{1EA2}nh ho\u{00E1} \u{0111}\u{01A1}n \u{0111}\u{00E3} ch\u{1ECD}n"))
        } else {
            placeholderContent
        }
    }

    private var placeholderContent: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "doc.text.viewfinder")
                .font(Typography.heroLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            Text(String(localized: "Ch\u{1ECD}n \u{1EA3}nh ho\u{00E1} \u{0111}\u{01A1}n"))
                .font(Typography.bodyLarge)
                .foregroundStyle(Color.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }

    private var photosPickerButton: some View {
        PhotosPicker(
            selection: $selectedItem,
            matching: .images
        ) {
            Label(
                String(localized: "Ch\u{1ECD}n t\u{1EEB} th\u{01B0} vi\u{1EC7}n"),
                systemImage: "photo.on.rectangle"
            )
            .font(Typography.titleSmall)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(ExpressivePressStyle())
    }
}

// MARK: - Scan Button

private extension ReceiptScanView {
    private var scanButtonCard: some View {
        Button {
            Task { await viewModel.processImage() }
        } label: {
            scanButtonLabel
        }
        .buttonStyle(ExpressivePressStyle())
        .disabled(viewModel.isScanning)
    }

    private var scanButtonLabel: some View {
        HStack(spacing: Spacing.sm) {
            if viewModel.isScanning {
                ProgressView()
                    .tint(Color.onPrimary)
            }
            Text(
                viewModel.isScanning
                    ? String(localized: "\u{0110}ang qu\u{00E9}t...")
                    : String(localized: "Qu\u{00E9}t ho\u{00E1} \u{0111}\u{01A1}n")
            )
            .font(Typography.titleSmall)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Result Display

private extension ReceiptScanView {
    @ViewBuilder
    private var resultCard: some View {
        if let error = viewModel.errorMessage {
            errorCard(message: error)
        } else if viewModel.scanResult != nil {
            parsedResultCard
        }
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.appError)
            Text(message)
                .font(Typography.bodyMedium)
                .foregroundStyle(Color.appError)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerLarge)
    }

    private var parsedResultCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(String(localized: "K\u{1EBF}t qu\u{1EA3} qu\u{00E9}t"))
                .font(Typography.sectionHeader)
                .foregroundStyle(Color.onSurface)
            amountField
            dateField
            rawTextPreview
        }
        .padding(Spacing.lg)
        .m3Card(cornerRadius: Spacing.cornerExtraLarge)
    }

    private var amountField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "S\u{1ED1} ti\u{1EC1}n"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            TextField(
                String(localized: "Nh\u{1EAD}p s\u{1ED1} ti\u{1EC1}n"),
                text: $viewModel.editableAmount
            )
            .keyboardType(.numberPad)
            .font(Typography.titleLarge)
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(String(localized: "Ng\u{00E0}y"))
                .font(Typography.labelLarge)
                .foregroundStyle(Color.onSurfaceVariant)
            DatePicker(
                "",
                selection: $viewModel.editableDate,
                displayedComponents: [.date]
            )
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var rawTextPreview: some View {
        if let rawText = viewModel.scanResult?.rawText, !rawText.isEmpty {
            DisclosureGroup(String(localized: "V\u{0103}n b\u{1EA3}n g\u{1ED1}c")) {
                Text(rawText)
                    .font(Typography.bodySmall)
                    .foregroundStyle(Color.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(Typography.labelLarge)
        }
    }
}

// MARK: - Create Transaction Button

private extension ReceiptScanView {
    private var createTransactionButton: some View {
        Button {
            handleCreateTransaction()
        } label: {
            Text(String(localized: "T\u{1EA1}o giao d\u{1ECB}ch"))
                .font(Typography.titleSmall)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(ExpressivePressStyle())
    }

    private func handleCreateTransaction() {
        let cleaned = viewModel.editableAmount
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
        guard let amount = Decimal(string: cleaned), amount > 0 else { return }
        onCreateTransaction(amount, viewModel.editableDate)
    }
}

// MARK: - Image Loading

private extension ReceiptScanView {
    // UIKit: UIImage needed for PhotosPicker -> Vision pipeline
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        guard let uiImage = UIImage(data: data) else { return }
        viewModel.selectedImage = uiImage
        viewModel.state = .idle
    }
}
