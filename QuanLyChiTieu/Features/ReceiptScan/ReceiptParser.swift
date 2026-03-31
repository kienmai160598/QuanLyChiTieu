import Foundation
import Vision

// MARK: - Receipt OCR Parser

internal struct ReceiptParser: Sendable {

    // MARK: - Public API

    @concurrent
    internal func parseReceipt(from image: CGImage) async throws -> ReceiptScanResult {
        let recognizedText = try await performOCR(on: image)
        let rawText = recognizedText.joined(separator: "\n")
        let amount = extractAmount(from: recognizedText)
        let date = extractDate(from: rawText)
        return ReceiptScanResult(amount: amount, date: date, rawText: rawText)
    }
}

// MARK: - OCR

private extension ReceiptParser {
    @concurrent
    private func performOCR(on image: CGImage) async throws -> [String] {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["vi-VN", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try handler.perform([request])

        guard let observations = request.results else {
            return []
        }
        return observations.compactMap { $0.topCandidates(1).first?.string }
    }
}

// MARK: - Amount Extraction

private extension ReceiptParser {
    private static let totalKeywords = [
        "tổng", "total", "thành tiền", "thanh toán",
        "tong", "thanh tien", "tong cong",
    ]

    private func extractAmount(from lines: [String]) -> Decimal? {
        let amountFromKeyword = findAmountNearKeyword(in: lines)
        if let amountFromKeyword { return amountFromKeyword }
        return findLargestAmountNearBottom(in: lines)
    }

    private func findAmountNearKeyword(in lines: [String]) -> Decimal? {
        for (index, line) in lines.enumerated() {
            let lowered = line.lowercased()
            let matchesKeyword = Self.totalKeywords.contains { lowered.contains($0) }
            guard matchesKeyword else { continue }

            if let amount = parseAmount(from: line) {
                return amount
            }
            if index + 1 < lines.count, let amount = parseAmount(from: lines[index + 1]) {
                return amount
            }
        }
        return nil
    }

    private func findLargestAmountNearBottom(in lines: [String]) -> Decimal? {
        let bottomLines = lines.suffix(5)
        let amounts = bottomLines.compactMap { parseAmount(from: $0) }
        return amounts.max()
    }

    private func parseAmount(from text: String) -> Decimal? {
        let cleaned = text
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "₫", with: "")
            .replacingOccurrences(of: "VND", with: "")
            .replacingOccurrences(of: "đ", with: "")

        let pattern = "\\d{4,}"
        guard let range = cleaned.range(
            of: pattern,
            options: .regularExpression
        ) else { return nil }

        let numberString = String(cleaned[range])
        return Decimal(string: numberString)
    }
}

// MARK: - Date Extraction

private extension ReceiptParser {
    private static let dateFormats = [
        "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy",
        "dd/MM/yy", "dd-MM-yy",
    ]

    private func extractDate(from text: String) -> Date? {
        let pattern = "\\d{1,2}[/\\-.]\\d{1,2}[/\\-.]\\d{2,4}"
        guard let range = text.range(
            of: pattern,
            options: .regularExpression
        ) else { return nil }

        let dateString = String(text[range])
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")

        for format in Self.dateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        return nil
    }
}
