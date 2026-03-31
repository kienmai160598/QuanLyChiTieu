import Foundation
import UIKit // UIKit: UIImage required for Vision framework CGImage conversion

// MARK: - Scan State

internal enum ReceiptScanState: Sendable {
    case idle
    case scanning
    case parsed(ReceiptScanResult)
    case error(String)
}

// MARK: - ViewModel

@MainActor @Observable
internal final class ReceiptScanViewModel {
    internal var state: ReceiptScanState = .idle
    internal var selectedImage: UIImage? // UIKit: UIImage needed for PhotosPicker output
    internal var editableAmount: String = ""
    internal var editableDate: Date = .now

    internal var scanResult: ReceiptScanResult? {
        if case .parsed(let result) = state { return result }
        return nil
    }

    internal var isScanning: Bool {
        if case .scanning = state { return true }
        return false
    }

    internal var errorMessage: String? {
        if case .error(let message) = state { return message }
        return nil
    }

    internal var canCreateTransaction: Bool {
        scanResult != nil && !editableAmount.isEmpty
    }

    private let parser = ReceiptParser()

    // MARK: - Actions

    internal func processImage() async {
        guard let image = selectedImage else { return }
        guard let cgImage = image.cgImage else {
            state = .error(String(localized: "Kh\u{00F4}ng th\u{1EC3} x\u{1EED} l\u{00FD} \u{1EA3}nh"))
            return
        }

        state = .scanning

        do {
            let result = try await parser.parseReceipt(from: cgImage)
            state = .parsed(result)
            applyParsedResult(result)
        } catch {
            state = .error(
                String(localized: "L\u{1ED7}i qu\u{00E9}t ho\u{00E1} \u{0111}\u{01A1}n: \(error.localizedDescription)")
            )
        }
    }

    internal func clearScan() {
        state = .idle
        selectedImage = nil
        editableAmount = ""
        editableDate = .now
    }
}

// MARK: - Private Helpers

private extension ReceiptScanViewModel {
    private func applyParsedResult(_ result: ReceiptScanResult) {
        if let amount = result.amount {
            editableAmount = "\(amount)"
        }
        if let date = result.date {
            editableDate = date
        }
    }
}
