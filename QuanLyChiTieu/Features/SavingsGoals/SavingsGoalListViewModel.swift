import Foundation
import SwiftData
import SwiftUI

@MainActor @Observable
internal final class SavingsGoalListViewModel {

    // MARK: - State

    internal var isShowingAddSheet = false
    internal var errorMessage: String?
    internal var selectedFilter: String?
    internal var searchText: String = ""

    // MARK: - Filter Chips

    internal static let filterChips: [ChipItem] = [
        ChipItem(id: "active", label: String(localized: "Đang tiết kiệm"), icon: "target"),
        ChipItem(id: "completed", label: String(localized: "Hoàn thành"), icon: "checkmark.circle"),
        ChipItem(id: "expired", label: String(localized: "Hết hạn"), icon: "clock.badge.exclamationmark"),
        ChipItem(id: "archived", label: String(localized: "Lưu trữ"), icon: "archivebox"),
    ]

    // MARK: - Filtering

    internal func filteredGoals(_ goals: [SavingsGoal]) -> [SavingsGoal] {
        var result = goals

        switch selectedFilter {
        case "active":
            result = result.filter { !$0.isCompleted && !$0.isExpired && !$0.isArchived }
        case "completed":
            result = result.filter { $0.isCompleted && !$0.isArchived }
        case "expired":
            result = result.filter { $0.isExpired && !$0.isArchived }
        case "archived":
            result = result.filter { $0.isArchived }
        default:
            result = result.filter { !$0.isArchived }
        }

        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        return result
    }

    // MARK: - Actions

    internal func deleteSavingsGoal(_ goal: SavingsGoal, context: ModelContext) {
        context.delete(goal)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể xoá mục tiêu")
        }
    }

    internal func archiveGoal(_ goal: SavingsGoal, context: ModelContext) {
        goal.isArchived = true
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể lưu trữ mục tiêu")
        }
    }

    internal func clearError() {
        errorMessage = nil
    }

    // MARK: - Helpers

    internal func daysRemaining(for goal: SavingsGoal) -> Int? {
        guard let deadline = goal.deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day
    }

    internal func progressColor(for goal: SavingsGoal) -> Color {
        if goal.isCompleted { return .appIncome }
        if goal.progress >= 0.7 { return .appIncome }
        if goal.progress >= 0.4 { return .appWarning }
        return .appError
    }
}
