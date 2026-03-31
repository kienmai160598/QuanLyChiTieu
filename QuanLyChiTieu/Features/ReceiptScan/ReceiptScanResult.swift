import Foundation

// MARK: - Receipt OCR scan result

internal struct ReceiptScanResult: Sendable {
    internal let amount: Decimal?
    internal let date: Date?
    internal let rawText: String
}
