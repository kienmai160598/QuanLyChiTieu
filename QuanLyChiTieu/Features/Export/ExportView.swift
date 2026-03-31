import SwiftUI
import SwiftData

// MARK: - ExportView

internal struct ExportView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]

    @State private var viewModel = ExportViewModel()

    internal var body: some View {
        List {
            dateRangeSection
            formatSection
            typeFilterSection
            previewSection
            exportSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .appBackground()
        .navigationTitle(String(localized: "Xuất dữ liệu"))
        .toolbarBackgroundVisibility(.visible, for: .navigationBar)
        .alert(
            String(localized: "Lỗi"),
            isPresented: showErrorBinding,
            actions: { Button(String(localized: "Đóng"), role: .cancel) {} },
            message: { Text(viewModel.exportError ?? "") }
        )
        .sheet(isPresented: showShareBinding) {
            if let url = viewModel.exportedFileURL {
                ShareSheet(items: [url])
            }
        }
    }
}

// MARK: - Sections

private extension ExportView {
    private var dateRangeSection: some View {
        Section {
            DatePicker(
                String(localized: "Từ ngày"),
                selection: $viewModel.startDate,
                displayedComponents: [.date]
            )
            DatePicker(
                String(localized: "Đến ngày"),
                selection: $viewModel.endDate,
                displayedComponents: [.date]
            )
        } header: {
            Text(String(localized: "Khoảng thời gian"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
        }
    }

    private var formatSection: some View {
        Section {
            Picker(String(localized: "Định dạng file"), selection: $viewModel.selectedFormat) {
                ForEach(ExportFormat.allCases) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text(String(localized: "Định dạng"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
        }
    }

    private var typeFilterSection: some View {
        Section {
            Picker(String(localized: "Lọc"), selection: $viewModel.selectedType) {
                Text(String(localized: "Tất cả")).tag(nil as TransactionType?)
                Text(String(localized: "Chi tiêu")).tag(TransactionType.expense as TransactionType?)
                Text(String(localized: "Thu nhập")).tag(TransactionType.income as TransactionType?)
            }
            .pickerStyle(.segmented)
        } header: {
            Text(String(localized: "Loại giao dịch"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onSurface)
        }
    }

    private var previewSection: some View {
        Section {
            let count = viewModel.transactionCount(from: allTransactions)
            HStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(Color.appSecondary)
                    .font(Typography.headlineSmall)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "\(count) giao dịch"))
                        .font(Typography.titleSmall)
                        .foregroundStyle(Color.onSurface)
                    Text(String(localized: "sẽ được xuất"))
                        .font(Typography.bodySmall)
                        .foregroundStyle(Color.onSurfaceVariant)
                }
                Spacer()
            }
        }
    }

    private var exportSection: some View {
        Section {
            Button {
                Task {
                    await viewModel.exportFile(transactions: allTransactions)
                }
            } label: {
                exportButtonContent
            }
            .listRowBackground(
                exportButtonDisabled ? Color.outlineVariant : Color.appPrimary
            )
            .disabled(exportButtonDisabled)
        }
    }

    private var exportButtonContent: some View {
        HStack {
            Spacer()
            if viewModel.isExporting {
                ProgressView()
                    .tint(Color.onPrimary)
                    .padding(.trailing, Spacing.sm)
            }
            Text(viewModel.isExporting
                ? String(localized: "Đang xuất...")
                : String(localized: "Xuất file"))
                .font(Typography.titleSmall)
                .foregroundStyle(Color.onPrimary)
            Spacer()
        }
        .padding(.vertical, Spacing.sm)
    }

    private var exportButtonDisabled: Bool {
        viewModel.isExporting
            || viewModel.transactionCount(from: allTransactions) == 0
    }
}

// MARK: - Bindings

private extension ExportView {
    private var showErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.exportError != nil },
            set: { if !$0 { viewModel.exportError = nil } }
        )
    }

    private var showShareBinding: Binding<Bool> {
        Binding(
            get: { viewModel.exportedFileURL != nil },
            set: { if !$0 { viewModel.exportedFileURL = nil } }
        )
    }
}

// MARK: - ShareSheet (UIKit wrapper)
// UIKit: ShareLink requires iOS 16+ but UIActivityViewController gives more control

private struct ShareSheet: UIViewControllerRepresentable {
    internal let items: [Any]

    internal func makeUIViewController(
        context: Context
    ) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
    }

    internal func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ExportView()
    }
    .modelContainer(
        for: [Transaction.self, Category.self],
        inMemory: true
    )
}
