// MARK: - Purpose: Domain errors for CSV and PDF data export operations
import Foundation

// MARK: - Export Error

/// Domain-specific errors for data export operations (CSV, PDF).
/// User-facing messages are in Vietnamese.
internal enum ExportError: LocalizedError, Sendable {
    case noTransactions
    case csvGenerationFailed
    case pdfGenerationFailed
    case shareFailed

    // MARK: - LocalizedError

    internal var errorDescription: String? {
        switch self {
        case .noTransactions:
            return "Không có giao dịch để xuất"
        case .csvGenerationFailed:
            return "Không thể tạo file CSV"
        case .pdfGenerationFailed:
            return "Không thể tạo file PDF"
        case .shareFailed:
            return "Không thể chia sẻ file"
        }
    }

    internal var recoverySuggestion: String? {
        switch self {
        case .noTransactions:
            return "Thêm ít nhất một giao dịch trước khi xuất dữ liệu."
        case .csvGenerationFailed:
            return "Kiểm tra bộ nhớ thiết bị và thử lại."
        case .pdfGenerationFailed:
            return "Kiểm tra bộ nhớ thiết bị và thử lại."
        case .shareFailed:
            return "Thử lại hoặc chia sẻ bằng cách khác."
        }
    }

    internal var failureReason: String? {
        switch self {
        case .noTransactions:
            return "Transaction list is empty. Nothing to export."
        case .csvGenerationFailed:
            return "Failed to encode transaction data as CSV."
        case .pdfGenerationFailed:
            return "UIGraphicsPDFRenderer failed to generate PDF document."
        case .shareFailed:
            return "UIActivityViewController failed to present or share the file."
        }
    }
}
