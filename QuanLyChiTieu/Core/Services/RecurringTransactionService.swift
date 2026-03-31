// MARK: - Purpose: Generates pending transactions from recurring transaction schedules
import Foundation
import OSLog
import SwiftData

@MainActor
internal final class RecurringTransactionService {

    private static let logger = Logger(
        subsystem: "com.quanlychitieu",
        category: "RecurringService"
    )

    internal func generatePendingTransactions(
        context: ModelContext
    ) throws {
        let descriptor = FetchDescriptor<RecurringTransaction>(
            predicate: #Predicate<RecurringTransaction> { $0.isActive }
        )

        let recurring: [RecurringTransaction]
        do {
            recurring = try context.fetch(descriptor)
        } catch {
            Self.logger.error(
                "Failed to fetch recurring transactions: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }

        for item in recurring {
            generateTransactions(for: item, context: context)
        }

        do {
            try context.save()
        } catch {
            Self.logger.error(
                "Failed to save generated transactions: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    // MARK: - Private

    private func generateTransactions(
        for recurring: RecurringTransaction,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let endDate = recurring.endDate, endDate < today {
            recurring.isActive = false
            return
        }

        let startFrom = resolveStartDate(recurring, calendar: calendar)
        emitPendingTransactions(
            recurring: recurring, from: startFrom,
            until: today, context: context
        )
    }

    private func resolveStartDate(
        _ recurring: RecurringTransaction,
        calendar: Calendar
    ) -> Date {
        recurring.lastGeneratedDate
            ?? calendar.date(byAdding: .second, value: -1, to: recurring.startDate)
            ?? recurring.startDate
    }

    private func emitPendingTransactions(
        recurring: RecurringTransaction,
        from startFrom: Date,
        until today: Date,
        context: ModelContext
    ) {
        var nextDate = calculateNextOccurrence(
            after: startFrom, originalStart: recurring.startDate,
            frequency: recurring.frequency
        )
        while nextDate <= today {
            if let endDate = recurring.endDate, nextDate > endDate { break }
            insertTransaction(from: recurring, date: nextDate, context: context)
            recurring.lastGeneratedDate = nextDate
            nextDate = calculateNextOccurrence(
                after: nextDate, originalStart: recurring.startDate,
                frequency: recurring.frequency
            )
        }
    }

    private func calculateNextOccurrence(
        after date: Date,
        originalStart: Date,
        frequency: RecurrenceFrequency
    ) -> Date {
        let calendar = Calendar.current
        switch frequency {
        case .daily:
            return calendar.date(
                byAdding: .day, value: 1, to: date
            ) ?? date
        case .weekly:
            return calendar.date(
                byAdding: .weekOfYear, value: 1, to: date
            ) ?? date
        case .monthly:
            return nextMonthlyOccurrence(
                after: date, originalStart: originalStart
            )
        case .yearly:
            return nextYearlyOccurrence(
                after: date, originalStart: originalStart
            )
        }
    }

    private func nextMonthlyOccurrence(
        after date: Date,
        originalStart: Date
    ) -> Date {
        let calendar = Calendar.current
        let originalDay = calendar.component(.day, from: originalStart)
        let nextRaw = calendar.date(
            byAdding: .month, value: 1, to: date
        ) ?? date
        let targetMonth = calendar.component(.month, from: nextRaw)
        let targetYear = calendar.component(.year, from: nextRaw)

        let daysInMonth = calendar.range(
            of: .day, in: .month, for: nextRaw
        )?.count ?? 28

        let clampedDay = min(originalDay, daysInMonth)

        var components = DateComponents()
        components.year = targetYear
        components.month = targetMonth
        components.day = clampedDay
        return calendar.date(from: components) ?? nextRaw
    }

    private func nextYearlyOccurrence(
        after date: Date,
        originalStart: Date
    ) -> Date {
        let calendar = Calendar.current
        let originalMonth = calendar.component(
            .month, from: originalStart
        )
        let originalDay = calendar.component(.day, from: originalStart)
        let nextRaw = calendar.date(
            byAdding: .year, value: 1, to: date
        ) ?? date
        let targetYear = calendar.component(.year, from: nextRaw)

        var components = DateComponents()
        components.year = targetYear
        components.month = originalMonth
        components.day = 1
        guard let targetDate = calendar.date(from: components) else {
            return nextRaw
        }

        let daysInMonth = calendar.range(
            of: .day, in: .month, for: targetDate
        )?.count ?? 28

        let clampedDay = min(originalDay, daysInMonth)
        components.day = clampedDay
        return calendar.date(from: components) ?? nextRaw
    }

    private func insertTransaction(
        from recurring: RecurringTransaction,
        date: Date,
        context: ModelContext
    ) {
        let targetDate = date
        let targetAmount = recurring.amount
        let targetType = recurring.type
        let targetNote = recurring.note

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> {
                $0.date == targetDate
                    && $0.amount == targetAmount
                    && $0.type == targetType
                    && $0.note == targetNote
            }
        )
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        let transaction = Transaction(
            amount: recurring.amount,
            note: recurring.note,
            date: date,
            type: recurring.type,
            category: recurring.category
        )
        context.insert(transaction)
    }
}
