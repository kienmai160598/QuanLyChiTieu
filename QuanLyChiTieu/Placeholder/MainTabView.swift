import SwiftUI
import SwiftData

// MARK: - Tab Enum

internal enum AppTab: Int, Sendable, Equatable {
    case expense
    case savings
}

// MARK: - Main Tab View

internal struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = AppTab.expense
    @Namespace private var transactionZoom

    internal var body: some View {
        TabView(selection: $selectedTab) {
            Tab(String(localized: "Chi tiêu"), systemImage: "plus.circle", value: .expense) {
                NavigationStack {
                    AddTransactionView()
                        .navigationDestinations(zoomNamespace: transactionZoom)
                }
            }

            Tab(String(localized: "Tiết kiệm"), systemImage: "target", value: .savings) {
                NavigationStack {
                    SavingsGoalListView()
                        .navigationDestinations()
                }
            }
        }
    }
}

// MARK: - Navigation Destinations (shared)

private extension View {
    func navigationDestinations(zoomNamespace: Namespace.ID? = nil) -> some View {
        self
            .navigationDestination(for: DashboardRoute.self) { route in
                DashboardRouteDestination(route: route)
            }
            .navigationDestination(for: TransactionRoute.self) { route in
                TransactionRouteDestination(route: route, zoomNamespace: zoomNamespace)
            }
            .navigationDestination(for: BudgetRoute.self) { route in
                BudgetRouteDestination(route: route)
            }
            .navigationDestination(for: DebtRoute.self) { route in
                DebtRouteDestination(route: route)
            }
            .navigationDestination(for: EventRoute.self) { route in
                EventRouteDestination(route: route)
            }
            .navigationDestination(for: SavingsGoalRoute.self) { route in
                SavingsGoalRouteDestination(route: route)
            }
    }
}

// MARK: - Route Destination Views

private struct DashboardRouteDestination: View {
    let route: DashboardRoute
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch route {
        case .transactionDetail(let id):
            modelView(for: id, as: Transaction.self) { TransactionDetailView(transaction: $0) }
        case .budgetDetail(let id):
            modelView(for: id, as: Budget.self) { BudgetDetailView(budget: $0) }
        case .allTransactions:
            TransactionListView()
                .navigationTitle(String(localized: "Giao dịch"))
        case .budgetList:
            BudgetListView()
                .navigationTitle(String(localized: "Ngân sách"))
        case .recurringList:
            RecurringTransactionView()
        case .profileSetup:
            ProfileSetupView()
        case .settings:
            SettingsView()
        case .insights:
            InsightsView()
        case .categoryManagement:
            CategoryListView()
        }
    }

    @ViewBuilder
    private func modelView<M: PersistentModel, V: View>(
        for id: PersistentIdentifier,
        as type: M.Type,
        @ViewBuilder content: (M) -> V
    ) -> some View {
        if let model = modelContext.model(for: id) as? M {
            content(model)
        } else {
            ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle")
        }
    }
}

private struct TransactionRouteDestination: View {
    let route: TransactionRoute
    let zoomNamespace: Namespace.ID?
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        switch route {
        case .detail(let id):
            if let tx = modelContext.model(for: id) as? Transaction {
                if let ns = zoomNamespace {
                    TransactionDetailView(transaction: tx)
                        .navigationTransition(.zoom(sourceID: id, in: ns))
                } else {
                    TransactionDetailView(transaction: tx)
                }
            } else { ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle") }
        case .edit(let id):
            if let tx = modelContext.model(for: id) as? Transaction {
                EditTransactionView(transaction: tx)
            } else { ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle") }
        }
    }
}

private struct BudgetRouteDestination: View {
    let route: BudgetRoute
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        switch route {
        case .detail(let id):
            if let budget = modelContext.model(for: id) as? Budget {
                BudgetDetailView(budget: budget)
            } else { ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle") }
        case .addBudget:
            BudgetListView().navigationTitle(String(localized: "Ngân sách"))
        }
    }
}

private struct DebtRouteDestination: View {
    let route: DebtRoute
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        switch route {
        case .detail(let id):
            if let debt = modelContext.model(for: id) as? Debt {
                DebtDetailView(debt: debt)
            } else {
                ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private struct EventRouteDestination: View {
    let route: EventRoute
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        switch route {
        case .detail(let id):
            if let event = modelContext.model(for: id) as? Event {
                EventDetailView(event: event)
            } else {
                ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

private struct SavingsGoalRouteDestination: View {
    let route: SavingsGoalRoute
    @Environment(\.modelContext) private var modelContext
    var body: some View {
        switch route {
        case .detail(let id):
            if let goal = modelContext.model(for: id) as? SavingsGoal {
                SavingsGoalDetailView(goal: goal)
            } else {
                ContentUnavailableView("Không tìm thấy", systemImage: "exclamationmark.triangle")
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(
            for: [Transaction.self, Category.self, Budget.self, Debt.self, Event.self, SavingsGoal.self],
            inMemory: true
        )
}
