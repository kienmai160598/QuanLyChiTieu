import Foundation

// MARK: - Transaction Date Group

/// Groups transactions by relative Vietnamese date labels:
/// "Hôm nay", "Hôm qua", "Tuần này", "Tuần trước", or month/year.
internal struct TransactionDateGroup: Identifiable {
    internal var id: String { label }
    internal let label: String
    internal let transactions: [Transaction]
    internal let sortDate: Date

    @MainActor
    internal static func group(
        _ transactions: [Transaction]
    ) -> [TransactionDateGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let dict = Dictionary(grouping: transactions) { tx in
            dateGroupKey(for: tx.date, calendar: calendar, today: today)
        }

        return dict.map { key, txs in
            let sorted = txs.sorted { $0.date > $1.date }
            let sortDate = sorted.first?.date ?? .now
            return TransactionDateGroup(
                label: key,
                transactions: sorted,
                sortDate: sortDate
            )
        }
        .sorted { $0.sortDate > $1.sortDate }
    }
}

// MARK: - Grouping Logic

private extension TransactionDateGroup {
    @MainActor
    private static func dateGroupKey(
        for date: Date,
        calendar: Calendar,
        today: Date
    ) -> String {
        if calendar.isDateInToday(date) {
            return String(localized: "Hôm nay")
        }
        if calendar.isDateInYesterday(date) {
            return String(localized: "Hôm qua")
        }
        if isInCurrentWeek(date, calendar: calendar, today: today) {
            return String(localized: "Tuần này")
        }
        if isInPreviousWeek(date, calendar: calendar, today: today) {
            return String(localized: "Tuần trước")
        }
        return monthYearLabel(for: date)
    }

    private static func isInCurrentWeek(
        _ date: Date,
        calendar: Calendar,
        today: Date
    ) -> Bool {
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return false
        }
        return weekStart.contains(date)
    }

    private static func isInPreviousWeek(
        _ date: Date,
        calendar: Calendar,
        today: Date
    ) -> Bool {
        guard let prevWeekDay = calendar.date(byAdding: .weekOfYear, value: -1, to: today),
              let prevWeek = calendar.dateInterval(of: .weekOfYear, for: prevWeekDay) else {
            return false
        }
        return prevWeek.contains(date)
    }

    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    @MainActor
    private static func monthYearLabel(for date: Date) -> String {
        monthYearFormatter.locale = LanguageManager.shared.locale
        return monthYearFormatter.string(from: date).capitalizingFirst
    }
}

// MARK: - String Helper

private extension String {
    var capitalizingFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
