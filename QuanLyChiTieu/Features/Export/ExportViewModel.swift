import Foundation
import SwiftData

@MainActor @Observable
internal final class ExportViewModel {
    internal var startDate: Date
    internal var endDate: Date
    internal var selectedFormat: ExportFormat = .csv
    internal var selectedType: TransactionType?
    internal var isExporting: Bool = false
    internal var exportError: String?
    internal var exportedFileURL: URL?

    private let exportService = ExportService()

    internal init() {
        let calendar = Calendar.current
        let now = Date()
        self.startDate = calendar.date(
            byAdding: .month, value: -1, to: now
        ) ?? now
        self.endDate = now
    }

    // MARK: - Filtering

    internal func filteredTransactions(
        from allTransactions: [Transaction]
    ) -> [Transaction] {
        let calendar = Calendar.current
        let rangeStart = calendar.startOfDay(for: startDate)
        let rangeEnd = calendar.endOfDay(for: endDate)

        let filtered = allTransactions.filter { tx in
            let inRange = tx.date >= rangeStart && tx.date <= rangeEnd
            guard inRange else { return false }
            if let selectedType {
                return tx.type == selectedType
            }
            return true
        }
        return filtered.sorted { $0.date > $1.date }
    }

    internal func transactionCount(
        from allTransactions: [Transaction]
    ) -> Int {
        filteredTransactions(from: allTransactions).count
    }

    // MARK: - Export

    internal func exportFile(
        transactions: [Transaction]
    ) async {
        let filtered = filteredTransactions(from: transactions)
        guard !filtered.isEmpty else {
            exportError = String(localized: "Không có giao dịch nào để xuất")
            return
        }

        isExporting = true
        exportError = nil

        do {
            let data = try await generateExportData(filtered: filtered)
            let url = try writeToTempFile(data: data)
            exportedFileURL = url
        } catch {
            let desc = error.localizedDescription
            exportError = String(localized: "Không thể xuất file: \(desc)")
        }

        isExporting = false
    }

    // MARK: - Private Helpers

    private func generateExportData(
        filtered: [Transaction]
    ) async throws -> Data {
        let dtos = TransactionDTO.from(filtered)
        switch selectedFormat {
        case .csv:
            return await exportService.exportToCSV(
                transactions: dtos
            )
        case .pdf:
            let title = buildPDFTitle()
            return await exportService.exportToPDF(
                transactions: dtos,
                title: title
            )
        }
    }

    private func writeToTempFile(data: Data) throws -> URL {
        let fileName = buildFileName()
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: [.completeFileProtection])
        return fileURL
    }

    private func buildFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "ddMMyyyy"
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        return "chi_tieu_\(start)_\(end).\(selectedFormat.fileExtension)"
    }

    private func buildPDFTitle() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        dateFormatter.locale = Locale(identifier: "vi_VN")
        let start = dateFormatter.string(from: startDate)
        let end = dateFormatter.string(from: endDate)
        return String(localized: "Báo cáo chi tiêu: \(start) - \(end)")
    }
}
