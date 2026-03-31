// MARK: - Purpose: Exports transaction data to CSV and PDF formats for sharing
import Foundation
import UIKit // UIKit: PDF rendering not available in SwiftUI

// MARK: - ExportFormat

internal enum ExportFormat: String, CaseIterable, Sendable, Identifiable {
    case csv = "CSV"
    case pdf = "PDF"

    internal var id: String { rawValue }

    internal var fileExtension: String {
        switch self {
        case .csv: "csv"
        case .pdf: "pdf"
        }
    }

    internal var mimeType: String {
        switch self {
        case .csv: "text/csv"
        case .pdf: "application/pdf"
        }
    }
}

// MARK: - TransactionDTO

internal struct TransactionDTO: Sendable {
    internal let amount: Decimal
    internal let note: String
    internal let date: Date
    internal let type: TransactionType
    internal let categoryName: String

    @MainActor
    internal static func from(
        _ transaction: Transaction
    ) -> TransactionDTO {
        TransactionDTO(
            amount: transaction.amount,
            note: transaction.note,
            date: transaction.date,
            type: transaction.type,
            categoryName: transaction.category?.localizedName ?? String(localized: "Không rõ")
        )
    }

    @MainActor
    internal static func from(
        _ transactions: [Transaction]
    ) -> [TransactionDTO] {
        transactions.map { from($0) }
    }
}

// MARK: - ExportService

@MainActor @Observable
internal final class ExportService {
    internal var isExporting: Bool = false
    internal var exportError: String?

    @concurrent
    internal func exportToCSV(
        transactions: [TransactionDTO]
    ) async -> Data {
        let bom = "\u{FEFF}"
        let headers = [
            String(localized: "Ngày"),
            String(localized: "Loại"),
            String(localized: "Danh mục"),
            String(localized: "Số tiền"),
            String(localized: "Ghi chú")
        ].joined(separator: ",")
        let header = headers
        let dateFormatter = Self.makeDateFormatter()

        let rows = transactions.map { dto in
            Self.buildCSVRow(dto, dateFormatter: dateFormatter)
        }

        let csvContent = bom + header + "\n"
            + rows.joined(separator: "\n")
        return Data(csvContent.utf8)
    }

    @concurrent
    internal func exportToPDF(
        transactions: [TransactionDTO],
        title: String
    ) async -> Data {
        ExportPDFRenderer.render(
            transactions: transactions,
            title: title
        )
    }
}

// MARK: - CSV Helpers

private extension ExportService {
    nonisolated static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }

    nonisolated static func buildCSVRow(
        _ dto: TransactionDTO,
        dateFormatter: DateFormatter
    ) -> String {
        let date = escapeCSV(dateFormatter.string(from: dto.date))
        let type = escapeCSV(dto.type.displayName)
        let category = escapeCSV(dto.categoryName)
        let amount = escapeCSV("\(dto.amount)")
        let note = escapeCSV(dto.note)
        return "\(date),\(type),\(category),\(amount),\(note)"
    }

    nonisolated static func escapeCSV(
        _ text: String
    ) -> String {
        guard text.contains(",")
            || text.contains("\"")
            || text.contains("\n") else {
            return text
        }
        return "\"\(text.replacingOccurrences(of: "\"", with: "\"\""))\""
    }
}
