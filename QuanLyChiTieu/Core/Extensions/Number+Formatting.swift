// MARK: - Purpose: VND currency formatting (standard, signed, compact) and percentage display
import Foundation

// MARK: - Decimal VND Formatting

internal extension Decimal {
    /// Vietnamese locale shared across all VND formatters
    private static let vietnameseLocale = Locale(identifier: "vi_VN")

    /// Shared VND formatter to avoid repeated allocation
    private static let vndFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.locale = vietnameseLocale
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    /// Standard VND: "1.500.000 ₫"
    var formattedVND: String {
        Self.vndFormatter.string(from: self as NSDecimalNumber) ?? "0 ₫"
    }

    /// Alias for formattedVND (used in export/PDF)
    var fullFormattedVND: String { formattedVND }

    /// Signed VND: "+1.500.000 ₫" or "-500.000 ₫"
    var signedFormattedVND: String {
        let absDecimal = abs(self)
        let formatted = absDecimal.formattedVND
        if self > 0 {
            return "+\(formatted)"
        } else if self < 0 {
            return "-\(formatted)"
        }
        return formatted
    }

    /// Compact VND for charts/cards: "1,5tr" / "500k" (vi) or "1.5M" / "500k" (en)
    @MainActor
    var compactVND: String {
        let doubleValue = (self as NSDecimalNumber).doubleValue
        let absValue = abs(doubleValue)
        let sign = doubleValue < 0 ? "-" : ""
        let isEnglish = LanguageManager.shared.currentLanguage == "en"

        let billionSuffix = isEnglish ? "B" : "tỷ"
        let millionSuffix = isEnglish ? "M" : "tr"

        if absValue >= 1_000_000_000 {
            let billions = absValue / 1_000_000_000
            return formatCompact(sign: sign, value: billions, suffix: billionSuffix)
        } else if absValue >= 1_000_000 {
            let millions = absValue / 1_000_000
            return formatCompact(sign: sign, value: millions, suffix: millionSuffix)
        } else if absValue >= 1_000 {
            let thousands = absValue / 1_000
            return formatCompact(sign: sign, value: thousands, suffix: "k")
        }
        return "\(sign)\(Int(absValue))₫"
    }

    private func formatCompact(
        sign: String,
        value: Double,
        suffix: String
    ) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(sign)\(Int(value))\(suffix)"
        }
        let formatted = String(format: "%.1f", value)
            .replacingOccurrences(of: ".", with: ",")
        return "\(sign)\(formatted)\(suffix)"
    }
}

// MARK: - Double Percentage Formatting

internal extension Double {
    /// Percentage: "65%" — zero decimal for whole numbers, one decimal otherwise
    var formattedPercent: String {
        if truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(self))%"
        }
        return String(format: "%.1f%%", self)
    }
}
