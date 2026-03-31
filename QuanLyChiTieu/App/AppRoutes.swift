import Foundation
import SwiftData

// MARK: - Dashboard Routes

internal enum DashboardRoute: Hashable {
    case transactionDetail(PersistentIdentifier)
    case budgetDetail(PersistentIdentifier)
    case allTransactions
    case budgetList
    case recurringList
    case profileSetup
    case settings
    case insights
    case categoryManagement
}

// MARK: - Transaction Routes

internal enum TransactionRoute: Hashable {
    case detail(PersistentIdentifier)
    case edit(PersistentIdentifier)
}

// MARK: - Budget Routes

internal enum BudgetRoute: Hashable {
    case detail(PersistentIdentifier)
    case addBudget
}

// MARK: - Debt Routes

internal enum DebtRoute: Hashable {
    case detail(PersistentIdentifier)
}

// MARK: - Event Routes

internal enum EventRoute: Hashable {
    case detail(PersistentIdentifier)
}

// MARK: - Savings Goal Routes

internal enum SavingsGoalRoute: Hashable {
    case detail(PersistentIdentifier)
}

