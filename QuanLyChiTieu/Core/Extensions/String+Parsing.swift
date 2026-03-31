// MARK: - Purpose: VND amount string parsing for form inputs
import Foundation

internal extension String {
    /// Strips Vietnamese thousands-separator dots, then parses as Decimal.
    /// Returns nil when the string is empty, non-numeric, or the value is zero or negative.
    var parsedVNDAmount: Decimal? {
        let cleaned = replacingOccurrences(of: ".", with: "")
        guard let amount = Decimal(string: cleaned), amount > 0 else { return nil }
        return amount
    }
}
