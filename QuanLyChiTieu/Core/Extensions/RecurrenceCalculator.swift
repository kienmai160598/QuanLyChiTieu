import Foundation

// MARK: - Recurrence Calculator

/// Shared utility for computing the next occurrence of a recurring transaction.
/// Used by both UpcomingRecurringBuilder and NotificationService.
internal enum RecurrenceCalculator {

    /// Computes the next occurrence date after `now` for a given recurrence.
    /// Uses mathematical jumps for monthly/yearly frequencies instead of
    /// iterating day-by-day.
    internal static func nextOccurrence(
        baseDate: Date,
        frequency: RecurrenceFrequency,
        after now: Date,
        calendar: Calendar = .current
    ) -> Date? {
        if baseDate > now { return baseDate }

        switch frequency {
        case .monthly:
            return nextByComponent(
                .month, baseDate: baseDate, after: now, calendar: calendar
            )
        case .yearly:
            return nextByComponent(
                .year, baseDate: baseDate, after: now, calendar: calendar
            )
        case .weekly:
            return nextByComponent(
                .weekOfYear, baseDate: baseDate, after: now, calendar: calendar
            )
        case .daily:
            return nextByComponent(
                .day, baseDate: baseDate, after: now, calendar: calendar
            )
        }
    }

    // MARK: - Private

    /// Calculates the number of whole intervals elapsed, then jumps forward.
    private static func nextByComponent(
        _ component: Calendar.Component,
        baseDate: Date,
        after now: Date,
        calendar: Calendar
    ) -> Date? {
        let elapsed = calendar.dateComponents(
            [component], from: baseDate, to: now
        )
        let count = componentValue(elapsed, for: component)
        guard let jumped = calendar.date(
            byAdding: component, value: count, to: baseDate
        ) else { return nil }

        if jumped > now { return jumped }

        return calendar.date(byAdding: component, value: count + 1, to: baseDate)
    }

    private static func componentValue(
        _ components: DateComponents,
        for component: Calendar.Component
    ) -> Int {
        switch component {
        case .day: components.day ?? 0
        case .weekOfYear: components.weekOfYear ?? 0
        case .month: components.month ?? 0
        case .year: components.year ?? 0
        default: 0
        }
    }
}
