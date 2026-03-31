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

    // MARK: - History Management

    internal var isHistoryExpanded: Bool = false

    // MARK: - Recurring Deposit Management

    internal var showRecurringDepositSheet: Bool = false

    // MARK: - Milestone Tracking

    internal private(set) var lastTriggeredMilestone: Double?

    // MARK: - Private

    private var celebrationTask: Task<Void, Never>?
    private let milestones: [Double] = [0.25, 0.50, 0.75, 1.0]

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

        let oldProgress = goal.progress
        goal.currentAmount += cappedAmount
        addFundsText = ""

        // Create transaction history record
        let transaction = SavingsTransaction(
            amount: cappedAmount,
            date: .now,
            note: "",
            isAutomatic: false,
            goal: goal
        )
        context.insert(transaction)

        do {
            try context.save()

            // Check for milestone achievements
            let newProgress = goal.progress
            checkMilestones(oldProgress: oldProgress, newProgress: newProgress, goal: goal)

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

        // Create transaction history record with negative amount
        let transaction = SavingsTransaction(
            amount: -cappedAmount,
            date: .now,
            note: "",
            isAutomatic: false,
            goal: goal
        )
        context.insert(transaction)

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

    // MARK: - Recurring Deposit Management

    internal func deleteRecurringDeposit(for goal: SavingsGoal, context: ModelContext) {
        guard let recurringDeposit = goal.recurringDeposit else { return }
        context.delete(recurringDeposit)
        do {
            try context.save()
        } catch {
            errorMessage = String(localized: "Không thể xoá tiết kiệm định kỳ")
        }
    }

    // MARK: - Helpers

    internal func clearError() {
        errorMessage = nil
    }

    internal func daysRemaining(for goal: SavingsGoal) -> Int? {
        SavingsGoalHelpers.daysRemaining(for: goal)
    }

    internal func progressColor(for goal: SavingsGoal) -> Color {
        SavingsGoalHelpers.progressColor(for: goal)
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

    // MARK: - Milestone Detection

    private func checkMilestones(oldProgress: Double, newProgress: Double, goal: SavingsGoal) {
        guard goal.milestoneNotificationsEnabled else { return }

        for milestone in milestones {
            if oldProgress < milestone && newProgress >= milestone {
                // Avoid triggering duplicate notifications for same milestone
                if lastTriggeredMilestone != milestone {
                    lastTriggeredMilestone = milestone
                    triggerMilestoneReached(milestone: milestone, goal: goal)
                }
            }
        }
    }

    private func triggerMilestoneReached(milestone: Double, goal: SavingsGoal) {
        HapticService.success()
        // TODO: Call NotificationService to send milestone notification
        // NotificationService.shared.sendMilestoneNotification(
        //     goalName: goal.name,
        //     milestone: milestone
        // )
    }
}
