// MARK: - Purpose: Calendar helpers for month boundaries and date key generation
import Foundation

// MARK: - Calendar Month & Day Helpers

internal extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }

    func endOfMonth(for date: Date) -> Date {
        guard let nextMonth = self.date(
            byAdding: .month, value: 1, to: startOfMonth(for: date)
        ) else { return date }
        return self.date(byAdding: .second, value: -1, to: nextMonth) ?? date
    }

    func endOfDay(for date: Date) -> Date {
        var components = dateComponents(
            [.year, .month, .day], from: date
        )
        components.hour = 23
        components.minute = 59
        components.second = 59
        return self.date(from: components) ?? date
    }

    func monthYearKey(for date: Date) -> String {
        let components = dateComponents([.year, .month], from: date)
        return String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
    }
}
