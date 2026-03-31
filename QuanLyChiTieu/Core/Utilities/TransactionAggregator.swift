import Foundation
import SwiftData

// MARK: - TransactionAggregator

/// Pure functions for common transaction filtering and aggregation.
/// All methods are stateless and safe to call from any isolation context.
internal enum TransactionAggregator {

    /// Returns the total income and total expense for transactions whose date
    /// falls within `dateRange` (both bounds inclusive).
    internal static func totals(
        from transactions: [Transaction],
        in dateRange: ClosedRange<Date>
    ) -> (income: Decimal, expense: Decimal) {
        let filtered = transactions.filter { dateRange.contains($0.date) }
        let income = filtered
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expense = filtered
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return (income, expense)
    }

    /// Groups the supplied transactions (assumed to be expenses) by their
    /// category's `PersistentIdentifier`, summing amounts per category.
    /// Transactions without a category are excluded.
    internal static func expensesByCategory(
        from transactions: [Transaction]
    ) -> [PersistentIdentifier: Decimal] {
        let grouped = Dictionary(grouping: transactions) {
            $0.category?.persistentModelID
        }
        var result: [PersistentIdentifier: Decimal] = [:]
        for (key, txs) in grouped {
            guard let catID = key else { continue }
            result[catID] = txs.reduce(Decimal.zero) { $0 + $1.amount }
        }
        return result
    }
}
