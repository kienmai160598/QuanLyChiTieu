import Foundation
import SwiftUI

// MARK: - Savings Goal Helper Functions

/// Namespace for shared savings goal utility functions.
/// Eliminates duplication between SavingsGoalListViewModel and SavingsGoalDetailViewModel.
internal enum SavingsGoalHelpers {

    // MARK: - Progress Color

    /// Returns the appropriate color for the goal's progress indicator.
    /// - Green (appIncome): completed or progress >= 70%
    /// - Yellow (appWarning): progress 40-70%
    /// - Red (appError): progress < 40%
    internal static func progressColor(for goal: SavingsGoal) -> Color {
        if goal.isCompleted { return .appIncome }
        if goal.progress >= 0.7 { return .appIncome }
        if goal.progress >= 0.4 { return .appWarning }
        return .appError
    }

    // MARK: - Days Remaining

    /// Calculates the number of days remaining until the goal's deadline.
    /// Returns nil if the goal has no deadline.
    /// Returns negative values if the deadline has passed.
    internal static func daysRemaining(for goal: SavingsGoal) -> Int? {
        guard let deadline = goal.deadline else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: deadline).day
    }
}
