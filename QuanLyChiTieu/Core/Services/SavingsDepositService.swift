// MARK: - Purpose: Processes recurring auto-deposits for savings goals
import Foundation
import OSLog
import SwiftData

@MainActor
@Observable
internal final class SavingsDepositService {

    private static let logger = Logger(
        subsystem: "com.quanlychitieu",
        category: "SavingsDepositService"
    )

    // MARK: - Public

    /// Processes all scheduled deposits that are due.
    /// Creates SavingsTransaction records and updates goal amounts.
    internal func processScheduledDeposits(
        context: ModelContext
    ) async throws {
        let descriptor = FetchDescriptor<RecurringSavingsDeposit>(
            predicate: #Predicate<RecurringSavingsDeposit> { $0.isActive }
        )

        let recurringDeposits: [RecurringSavingsDeposit]
        do {
            recurringDeposits = try context.fetch(descriptor)
        } catch {
            Self.logger.error(
                "Failed to fetch recurring deposits: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }

        for deposit in recurringDeposits {
            processDeposit(deposit, context: context)
        }

        do {
            try context.save()
        } catch {
            Self.logger.error(
                "Failed to save processed deposits: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    // MARK: - Private

    private func processDeposit(
        _ deposit: RecurringSavingsDeposit,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if deposit has expired
        if let endDate = deposit.endDate, endDate < today {
            deposit.isActive = false
            return
        }

        // Skip if no goal is associated
        guard let goal = deposit.goal else {
            Self.logger.warning(
                "Recurring deposit has no associated goal, skipping"
            )
            return
        }

        // Skip if goal is already completed or archived
        guard !goal.isCompleted, !goal.isArchived else {
            deposit.isActive = false
            return
        }

        let startFrom = resolveStartDate(deposit, calendar: calendar)
        emitScheduledDeposits(
            deposit: deposit,
            goal: goal,
            from: startFrom,
            until: today,
            context: context
        )
    }

    private func resolveStartDate(
        _ deposit: RecurringSavingsDeposit,
        calendar: Calendar
    ) -> Date {
        deposit.lastDepositDate
            ?? calendar.date(byAdding: .second, value: -1, to: deposit.startDate)
            ?? deposit.startDate
    }

    private func emitScheduledDeposits(
        deposit: RecurringSavingsDeposit,
        goal: SavingsGoal,
        from startFrom: Date,
        until today: Date,
        context: ModelContext
    ) {
        var nextDate = calculateNextOccurrence(
            after: startFrom,
            originalStart: deposit.startDate,
            frequency: deposit.frequency
        )

        while nextDate <= today {
            if let endDate = deposit.endDate, nextDate > endDate { break }

            createDepositTransaction(
                deposit: deposit,
                goal: goal,
                date: nextDate,
                context: context
            )

            deposit.lastDepositDate = nextDate

            nextDate = calculateNextOccurrence(
                after: nextDate,
                originalStart: deposit.startDate,
                frequency: deposit.frequency
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
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        case .monthly:
            return nextMonthlyOccurrence(
                after: date,
                originalStart: originalStart,
                calendar: calendar
            )
        case .yearly:
            return nextYearlyOccurrence(
                after: date,
                originalStart: originalStart,
                calendar: calendar
            )
        }
    }

    private func nextMonthlyOccurrence(
        after date: Date,
        originalStart: Date,
        calendar: Calendar
    ) -> Date {
        let originalDay = calendar.component(.day, from: originalStart)
        let nextRaw = calendar.date(byAdding: .month, value: 1, to: date) ?? date
        let targetMonth = calendar.component(.month, from: nextRaw)
        let targetYear = calendar.component(.year, from: nextRaw)

        let daysInMonth = calendar.range(of: .day, in: .month, for: nextRaw)?.count ?? 28
        let clampedDay = min(originalDay, daysInMonth)

        var components = DateComponents()
        components.year = targetYear
        components.month = targetMonth
        components.day = clampedDay

        return calendar.date(from: components) ?? nextRaw
    }

    private func nextYearlyOccurrence(
        after date: Date,
        originalStart: Date,
        calendar: Calendar
    ) -> Date {
        let originalMonth = calendar.component(.month, from: originalStart)
        let originalDay = calendar.component(.day, from: originalStart)
        let nextRaw = calendar.date(byAdding: .year, value: 1, to: date) ?? date
        let targetYear = calendar.component(.year, from: nextRaw)

        var components = DateComponents()
        components.year = targetYear
        components.month = originalMonth
        components.day = 1

        guard let targetDate = calendar.date(from: components) else {
            return nextRaw
        }

        let daysInMonth = calendar.range(of: .day, in: .month, for: targetDate)?.count ?? 28
        let clampedDay = min(originalDay, daysInMonth)
        components.day = clampedDay

        return calendar.date(from: components) ?? nextRaw
    }

    private func createDepositTransaction(
        deposit: RecurringSavingsDeposit,
        goal: SavingsGoal,
        date: Date,
        context: ModelContext
    ) {
        // Check for duplicate to avoid double-processing
        guard !isDuplicateTransaction(
            goal: goal,
            amount: deposit.amount,
            date: date,
            context: context
        ) else {
            return
        }

        let transaction = SavingsTransaction(
            amount: deposit.amount,
            date: date,
            note: String(localized: "Auto-deposit"),
            isAutomatic: true,
            goal: goal
        )

        context.insert(transaction)

        // Update goal's current amount
        goal.currentAmount += deposit.amount

        // Mark goal as completed if target reached
        if goal.isCompleted, goal.completedAt == nil {
            goal.completedAt = date
        }

        Self.logger.info(
            "Created auto-deposit for goal: \(goal.name, privacy: .public)"
        )
    }

    private func isDuplicateTransaction(
        goal: SavingsGoal,
        amount: Decimal,
        date: Date,
        context: ModelContext
    ) -> Bool {
        let targetDate = date
        let targetAmount = amount

        let descriptor = FetchDescriptor<SavingsTransaction>(
            predicate: #Predicate<SavingsTransaction> {
                $0.date == targetDate
                    && $0.amount == targetAmount
                    && $0.isAutomatic == true
            }
        )

        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        return existingCount > 0
    }
}
