import Foundation
import SwiftData
import SwiftUI

@MainActor @Observable
internal final class SavingsGoalDetailViewModel {

    // MARK: - State

    internal var isShowingAddFundsSheet = false
    internal var isShowingWithdrawSheet = false
    internal var addFundsText: String = ""
    internal var withdrawFundsText: String = ""
    internal private(set) var isSaving: Bool = false
    internal var showCompletionCelebration: Bool = false
    internal var errorMessage: String?

    // MARK: - Private

    private var celebrationTask: Task<Void, Never>?

    // MARK: - Computed

    internal var parsedFundsAmount: Decimal? {
        addFundsText.parsedVNDAmount
    }

    internal var parsedWithdrawAmount: Decimal? {
        withdrawFundsText.parsedVNDAmount
    }

    // MARK: - Add Funds

    internal func addFunds(to goal: SavingsGoal, context: ModelContext) -> Bool {
        guard !isSaving else { return false }
        guard let amount = parsedFundsAmount else {
            errorMessage = String(localized: "Số tiền phải lớn hơn 0")
            return false
        }

        let cappedAmount = min(amount, goal.remainingAmount)
        guard cappedAmount > 0 else {
            errorMessage = String(localized: "Mục tiêu đã hoàn thành")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        goal.currentAmount += cappedAmount
        addFundsText = ""

        do {
            try context.save()
            if goal.isCompleted && goal.completedAt == nil {
                goal.completedAt = .now
                try context.save()
                triggerCelebration()
            }
            return true
        } catch {
            errorMessage = String(localized: "Không thể lưu thay đổi")
            return false
        }
    }

    // MARK: - Withdraw Funds

    internal func withdrawFunds(from goal: SavingsGoal, context: ModelContext) -> Bool {
        guard !isSaving else { return false }
        guard let amount = parsedWithdrawAmount else {
            errorMessage = String(localized: "Số tiền phải lớn hơn 0")
            return false
        }

        let cappedAmount = min(amount, goal.currentAmount)
        guard cappedAmount > 0 else {
            errorMessage = String(localized: "Không có tiền để rút")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        goal.currentAmount -= cappedAmount
        withdrawFundsText = ""

        if !goal.isCompleted {
            goal.completedAt = nil
        }

        do {
            try context.save()
            return true
        } catch {
            errorMessage = String(localized: "Không thể lưu thay đổi")
            return false
        }
    }

    // MARK: - Delete

    internal func deleteSavingsGoal(_ goal: SavingsGoal, context: ModelContext) {
        context.delete(goal)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể xoá mục tiêu")
        }
    }

    // MARK: - Helpers

    internal func clearError() {
        errorMessage = nil
    }

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

    // MARK: - Private

    private func triggerCelebration() {
        HapticService.success()
        showCompletionCelebration = true
        celebrationTask?.cancel()
        celebrationTask = Task {
            do {
                try await Task.sleep(for: .seconds(2.5))
                showCompletionCelebration = false
            } catch {
                // Task cancelled — no action needed.
            }
        }
    }
}
