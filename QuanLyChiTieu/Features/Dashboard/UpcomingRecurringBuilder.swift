import Foundation

// MARK: - Upcoming Recurring Builder

@MainActor
internal struct UpcomingRecurringBuilder {

    internal static func buildUpcomingItems(
        recurring: [RecurringTransaction],
        now: Date
    ) -> [UpcomingRecurring] {
        let calendar = Calendar.current
        let items: [UpcomingRecurring] = recurring.compactMap { rec in
            if let endDate = rec.endDate, endDate < now { return nil }
            guard let nextDate = nextOccurrence(for: rec, after: now, calendar: calendar) else {
                return nil
            }
            let days = max(calendar.dateComponents([.day], from: now, to: nextDate).day ?? 0, 0)
            return UpcomingRecurring(
                note: rec.note.isEmpty ? (rec.category?.localizedName ?? String(localized: "Không rõ")) : rec.note,
                amount: rec.amount, formattedAmount: rec.amount.formattedVND,
                nextDate: nextDate, daysUntilNext: days,
                icon: rec.category?.icon ?? "questionmark.circle.fill",
                colorHex: rec.category?.colorHex ?? Category.defaultColorHex,
                isExpense: rec.type == .expense
            )
        }
        return items.sorted { $0.daysUntilNext < $1.daysUntilNext }.prefix(3).map { $0 }
    }

    private static func nextOccurrence(
        for rec: RecurringTransaction,
        after now: Date,
        calendar: Calendar
    ) -> Date? {
        let baseDate = rec.lastGeneratedDate ?? rec.startDate
        return RecurrenceCalculator.nextOccurrence(
            baseDate: baseDate,
            frequency: rec.frequency,
            after: now,
            calendar: calendar
        )
    }
}
