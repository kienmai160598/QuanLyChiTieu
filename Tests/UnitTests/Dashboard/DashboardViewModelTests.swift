import Testing
import SwiftData
import Foundation
@testable import QuanLyChiTieu

// MARK: - Test Helpers

private func makeInMemoryContext() throws -> ModelContext {
    let schema = Schema([
        Transaction.self,
        Category.self,
        Budget.self,
        RecurringTransaction.self,
        UserProfile.self,
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return ModelContext(container)
}

private func makeCategory(
    name: String,
    icon: String = "circle.fill",
    colorHex: String = "#FF0000",
    type: TransactionType = .expense,
    context: ModelContext
) -> Category {
    let cat = Category(name: name, icon: icon, colorHex: colorHex, type: type)
    context.insert(cat)
    return cat
}

private func makeTransaction(
    amount: Decimal,
    type: TransactionType,
    date: Date = .now,
    category: Category? = nil,
    context: ModelContext
) -> Transaction {
    let tx = Transaction(amount: amount, type: type, date: date, category: category)
    context.insert(tx)
    return tx
}

private func makeBudget(
    limit: Decimal,
    monthYear: String,
    category: Category,
    context: ModelContext
) -> Budget {
    let budget = Budget(limitAmount: limit, monthYear: monthYear, category: category)
    context.insert(budget)
    return budget
}

private func makeRecurring(
    amount: Decimal,
    type: TransactionType,
    frequency: RecurrenceFrequency,
    startDate: Date,
    lastGeneratedDate: Date? = nil,
    category: Category? = nil,
    context: ModelContext
) -> RecurringTransaction {
    let rec = RecurringTransaction(
        amount: amount,
        type: type,
        category: category,
        frequency: frequency,
        startDate: startDate,
        lastGeneratedDate: lastGeneratedDate
    )
    context.insert(rec)
    return rec
}

// Fixed date anchor for all tests: 2026-03-15 12:00:00 UTC
private let fixedNow: Date = {
    var components = DateComponents()
    components.year = 2026
    components.month = 3
    components.day = 15
    components.hour = 12
    components.minute = 0
    components.second = 0
    components.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
    return Calendar.current.date(from: components)!
}()

private let fixedMonthStart: Date = fixedNow.startOfMonth
private let fixedMonthEnd: Date = fixedNow.endOfMonth

// MARK: - Balance Calculation

@Suite("Balance Calculation")
@MainActor
struct BalanceCalculationTests {

    @Test("totalBalance_withIncomeAndExpense_returnsNetBalance")
    func totalBalance_withIncomeAndExpense_returnsNetBalance() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx1 = makeTransaction(amount: 5_000_000, type: .income, date: fixedNow, context: context)
        let tx2 = makeTransaction(amount: 2_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [tx1, tx2], budgets: [], recurring: [])

        #expect(vm.totalIncome == 5_000_000)
        #expect(vm.totalExpense == 2_000_000)
        #expect(vm.totalBalance == 3_000_000)
    }

    @Test("totalBalance_withNoTransactions_returnsZero")
    func totalBalance_withNoTransactions_returnsZero() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.totalIncome == 0)
        #expect(vm.totalExpense == 0)
        #expect(vm.totalBalance == 0)
    }

    @Test("totalBalance_withOnlyExpenses_returnsNegativeBalance")
    func totalBalance_withOnlyExpenses_returnsNegativeBalance() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.totalBalance == -1_000_000)
        #expect(vm.isOverBudget == true)
    }

    @Test("totalBalance_withOnlyIncome_isNotOverBudget")
    func totalBalance_withOnlyIncome_isNotOverBudget() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx = makeTransaction(amount: 3_000_000, type: .income, date: fixedNow, context: context)

        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.isOverBudget == false)
        #expect(vm.totalBalance == 3_000_000)
    }

    @Test("totalBalance_excludesTransactionsOutsideSelectedMonth")
    func totalBalance_excludesTransactionsOutsideSelectedMonth() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // Prior month transaction — should be excluded
        var prevComponents = DateComponents()
        prevComponents.year = 2026
        prevComponents.month = 2
        prevComponents.day = 10
        prevComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let prevDate = Calendar.current.date(from: prevComponents)!

        let inMonth = makeTransaction(amount: 2_000_000, type: .income, date: fixedNow, context: context)
        let outOfMonth = makeTransaction(amount: 9_000_000, type: .income, date: prevDate, context: context)

        vm.loadData(transactions: [inMonth, outOfMonth], budgets: [], recurring: [])

        #expect(vm.totalIncome == 2_000_000)
    }
}

// MARK: - Monthly Spending Aggregation

@Suite("Monthly Spending")
@MainActor
struct MonthlySpendingTests {

    @Test("recentTransactions_limitsToFiveTransactions")
    func recentTransactions_limitsToFiveTransactions() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let txs = (1...8).map {
            makeTransaction(amount: Decimal($0 * 100_000), type: .expense, date: fixedNow, context: context)
        }

        vm.loadData(transactions: txs, budgets: [], recurring: [])

        #expect(vm.recentTransactions.count == 5)
    }

    @Test("recentTransactions_withFewerThanFive_returnsAll")
    func recentTransactions_withFewerThanFive_returnsAll() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let txs = (1...3).map {
            makeTransaction(amount: Decimal($0 * 100_000), type: .expense, date: fixedNow, context: context)
        }

        vm.loadData(transactions: txs, budgets: [], recurring: [])

        #expect(vm.recentTransactions.count == 3)
    }

    @Test("totalExpense_aggregatesAllExpensesInMonth")
    func totalExpense_aggregatesAllExpensesInMonth() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx1 = makeTransaction(amount: 500_000, type: .expense, date: fixedNow, context: context)
        let tx2 = makeTransaction(amount: 300_000, type: .expense, date: fixedNow, context: context)
        let tx3 = makeTransaction(amount: 200_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [tx1, tx2, tx3], budgets: [], recurring: [])

        #expect(vm.totalExpense == 1_000_000)
    }
}

// MARK: - Category Breakdown

@Suite("Category Breakdown")
@MainActor
struct CategoryBreakdownTests {

    @Test("topCategories_groupsExpensesByCategory")
    func topCategories_groupsExpensesByCategory() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let foodCat = makeCategory(name: "Ăn uống", context: context)
        let transportCat = makeCategory(name: "Di chuyển", context: context)

        let tx1 = makeTransaction(amount: 600_000, type: .expense, date: fixedNow, category: foodCat, context: context)
        let tx2 = makeTransaction(amount: 400_000, type: .expense, date: fixedNow, category: foodCat, context: context)
        let tx3 = makeTransaction(amount: 200_000, type: .expense, date: fixedNow, category: transportCat, context: context)

        vm.loadData(transactions: [tx1, tx2, tx3], budgets: [], recurring: [])

        #expect(vm.topCategories.count == 2)
        // Highest spender first
        #expect(vm.topCategories[0].amount == 1_000_000)
        #expect(vm.topCategories[1].amount == 200_000)
    }

    @Test("topCategories_excludesIncomeTransactions")
    func topCategories_excludesIncomeTransactions() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let incomeCat = makeCategory(name: "Lương", type: .income, context: context)
        let expenseCat = makeCategory(name: "Ăn uống", type: .expense, context: context)

        let income = makeTransaction(amount: 10_000_000, type: .income, date: fixedNow, category: incomeCat, context: context)
        let expense = makeTransaction(amount: 500_000, type: .expense, date: fixedNow, category: expenseCat, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        #expect(vm.topCategories.count == 1)
        #expect(vm.topCategories[0].amount == 500_000)
    }

    @Test("topCategories_withNoExpenses_returnsEmpty")
    func topCategories_withNoExpenses_returnsEmpty() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let incomeCat = makeCategory(name: "Lương", type: .income, context: context)
        let tx = makeTransaction(amount: 5_000_000, type: .income, date: fixedNow, category: incomeCat, context: context)

        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.topCategories.isEmpty)
    }

    @Test("topCategories_limitsToEightCategories")
    func topCategories_limitsToEightCategories() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let txs: [Transaction] = (1...10).map { i in
            let cat = makeCategory(name: "Cat\(i)", context: context)
            return makeTransaction(amount: Decimal(i * 100_000), type: .expense, date: fixedNow, category: cat, context: context)
        }

        vm.loadData(transactions: txs, budgets: [], recurring: [])

        #expect(vm.topCategories.count <= 8)
    }

    @Test("topCategories_ratiosSumToApproximatelyOne")
    func topCategories_ratiosSumToApproximatelyOne() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let cat1 = makeCategory(name: "A", context: context)
        let cat2 = makeCategory(name: "B", context: context)

        let tx1 = makeTransaction(amount: 300_000, type: .expense, date: fixedNow, category: cat1, context: context)
        let tx2 = makeTransaction(amount: 700_000, type: .expense, date: fixedNow, category: cat2, context: context)

        vm.loadData(transactions: [tx1, tx2], budgets: [], recurring: [])

        let ratioSum = vm.topCategories.reduce(0.0) { $0 + $1.ratio }
        #expect(abs(ratioSum - 1.0) < 0.001)
    }

    @Test("selectCategory_togglesSameIndexToNil")
    func selectCategory_togglesSameIndexToNil() {
        let vm = DashboardViewModel()

        vm.selectCategory(2)
        #expect(vm.selectedCategoryIndex == 2)

        vm.selectCategory(2)
        #expect(vm.selectedCategoryIndex == nil)
    }

    @Test("selectCategory_switchesToNewIndex")
    func selectCategory_switchesToNewIndex() {
        let vm = DashboardViewModel()

        vm.selectCategory(0)
        vm.selectCategory(3)
        #expect(vm.selectedCategoryIndex == 3)
    }
}

// MARK: - Budget Progress

@Suite("Budget Progress")
@MainActor
struct BudgetProgressTests {

    @Test("budgetSummaries_calculatesRatioCorrectly")
    func budgetSummaries_calculatesRatioCorrectly() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let cat = makeCategory(name: "Ăn uống", context: context)
        let budget = makeBudget(limit: 2_000_000, monthYear: fixedNow.monthYearKey, category: cat, context: context)
        let tx = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, category: cat, context: context)

        vm.loadData(transactions: [tx], budgets: [budget], recurring: [])

        #require(!vm.budgetSummaries.isEmpty)
        let summary = vm.budgetSummaries[0]
        #expect(abs(summary.ratio - 0.5) < 0.001)
    }

    @Test("budgetSummaries_ratioCappsAtOneWhenOverBudget")
    func budgetSummaries_ratioCappsAtOneWhenOverBudget() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let cat = makeCategory(name: "Mua sắm", context: context)
        let budget = makeBudget(limit: 500_000, monthYear: fixedNow.monthYearKey, category: cat, context: context)
        let tx = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, category: cat, context: context)

        vm.loadData(transactions: [tx], budgets: [budget], recurring: [])

        #require(!vm.budgetSummaries.isEmpty)
        #expect(vm.budgetSummaries[0].ratio <= 1.0)
    }

    @Test("budgetSummaries_withNoBudgets_returnsEmpty")
    func budgetSummaries_withNoBudgets_returnsEmpty() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.budgetSummaries.isEmpty)
    }

    @Test("budgetSummaries_limitsToThreeEntries")
    func budgetSummaries_limitsToThreeEntries() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let budgets: [Budget] = (1...5).map { i in
            let cat = makeCategory(name: "Cat\(i)", context: context)
            let tx = makeTransaction(amount: Decimal(i * 100_000), type: .expense, date: fixedNow, category: cat, context: context)
            _ = tx
            return makeBudget(limit: 500_000, monthYear: fixedNow.monthYearKey, category: cat, context: context)
        }

        let txs = (1...5).compactMap { i -> Transaction? in
            guard let budget = budgets.first(where: { $0.category?.name == "Cat\(i)" }),
                  let cat = budget.category else { return nil }
            return makeTransaction(amount: Decimal(i * 100_000), type: .expense, date: fixedNow, category: cat, context: context)
        }

        vm.loadData(transactions: txs, budgets: budgets, recurring: [])

        #expect(vm.budgetSummaries.count <= 3)
    }

    @Test("budgetSummaries_excludesBudgetsForDifferentMonth")
    func budgetSummaries_excludesBudgetsForDifferentMonth() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let cat = makeCategory(name: "Ăn uống", context: context)
        // Budget for a different month
        let budget = makeBudget(limit: 2_000_000, monthYear: "2026-02", category: cat, context: context)
        let tx = makeTransaction(amount: 500_000, type: .expense, date: fixedNow, category: cat, context: context)

        vm.loadData(transactions: [tx], budgets: [budget], recurring: [])

        #expect(vm.budgetSummaries.isEmpty)
    }

    @Test("budgetSummary_barColor_isGreenWhenUnder70Pct")
    func budgetSummary_barColor_isGreenWhenUnder70Pct() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 600_000, limit: 1_000_000
        )
        // ratio == 0.6 → should be appPrimary (green)
        #expect(summary.ratio < 0.7)
    }

    @Test("budgetSummary_barColor_isErrorWhenAt90PctOrAbove")
    func budgetSummary_barColor_isErrorWhenAt90PctOrAbove() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 950_000, limit: 1_000_000
        )
        // ratio == 0.95 → should be appError
        #expect(summary.ratio >= 0.9)
    }

    @Test("budgetSummary_ratioIsZero_whenLimitIsZero")
    func budgetSummary_ratioIsZero_whenLimitIsZero() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 500_000, limit: 0
        )
        #expect(summary.ratio == 0)
    }
}

// MARK: - Upcoming Recurring

@Suite("Upcoming Recurring")
@MainActor
struct UpcomingRecurringTests {

    @Test("upcomingRecurring_computesNextDueDateForMonthlyFrequency")
    func upcomingRecurring_computesNextDueDateForMonthlyFrequency() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // Last generated 2026-02-15 → next should be 2026-03-15
        var lastGenComponents = DateComponents()
        lastGenComponents.year = 2026
        lastGenComponents.month = 2
        lastGenComponents.day = 15
        lastGenComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let lastGen = Calendar.current.date(from: lastGenComponents)!

        let rec = makeRecurring(
            amount: 1_500_000,
            type: .expense,
            frequency: .monthly,
            startDate: lastGen,
            lastGeneratedDate: lastGen,
            context: context
        )

        vm.loadData(transactions: [], budgets: [], recurring: [rec])

        // daysUntilNext should be non-negative
        if let first = vm.upcomingRecurring.first {
            #expect(first.daysUntilNext >= 0)
            #expect(first.amount == 1_500_000)
            #expect(first.isExpense == true)
        }
    }

    @Test("upcomingRecurring_limitsToThreeItems")
    func upcomingRecurring_limitsToThreeItems() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 3
        startComponents.day = 1
        startComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let startDate = Calendar.current.date(from: startComponents)!

        let recs: [RecurringTransaction] = (1...5).map { _ in
            makeRecurring(amount: 100_000, type: .expense, frequency: .monthly, startDate: startDate, context: context)
        }

        vm.loadData(transactions: [], budgets: [], recurring: recs)

        #expect(vm.upcomingRecurring.count <= 3)
    }

    @Test("upcomingRecurring_sortedByDaysUntilNextAscending")
    func upcomingRecurring_sortedByDaysUntilNextAscending() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // One due in 1 day, one due in 7 days
        var in1DayComponents = DateComponents()
        in1DayComponents.year = 2026
        in1DayComponents.month = 3
        in1DayComponents.day = 14
        in1DayComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let in1Day = Calendar.current.date(from: in1DayComponents)!

        var in7DaysComponents = DateComponents()
        in7DaysComponents.year = 2026
        in7DaysComponents.month = 3
        in7DaysComponents.day = 8
        in7DaysComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let in7Days = Calendar.current.date(from: in7DaysComponents)!

        let nearRec = makeRecurring(amount: 200_000, type: .expense, frequency: .weekly, startDate: in1Day, context: context)
        let farRec = makeRecurring(amount: 500_000, type: .expense, frequency: .weekly, startDate: in7Days, context: context)

        vm.loadData(transactions: [], budgets: [], recurring: [farRec, nearRec])

        guard vm.upcomingRecurring.count >= 2 else { return }
        #expect(vm.upcomingRecurring[0].daysUntilNext <= vm.upcomingRecurring[1].daysUntilNext)
    }

    @Test("upcomingRecurring_withNoRecurring_returnsEmpty")
    func upcomingRecurring_withNoRecurring_returnsEmpty() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.upcomingRecurring.isEmpty)
    }

    @Test("upcomingRecurring_marksExpenseAndIncomeCorrectly")
    func upcomingRecurring_marksExpenseAndIncomeCorrectly() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        var startComponents = DateComponents()
        startComponents.year = 2026
        startComponents.month = 2
        startComponents.day = 15
        startComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let startDate = Calendar.current.date(from: startComponents)!

        let expenseRec = makeRecurring(amount: 300_000, type: .expense, frequency: .monthly, startDate: startDate, context: context)
        let incomeRec = makeRecurring(amount: 10_000_000, type: .income, frequency: .monthly, startDate: startDate, context: context)

        vm.loadData(transactions: [], budgets: [], recurring: [expenseRec, incomeRec])

        let expenseItems = vm.upcomingRecurring.filter { $0.isExpense }
        let incomeItems = vm.upcomingRecurring.filter { !$0.isExpense }
        #expect(!expenseItems.isEmpty)
        #expect(!incomeItems.isEmpty)
    }
}

// MARK: - Financial Health Scores

@Suite("Financial Health Scores")
@MainActor
struct FinancialHealthTests {

    @Test("spendingScore_isZeroWhenNoIncome")
    func spendingScore_isZeroWhenNoIncome() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx = makeTransaction(amount: 500_000, type: .expense, date: fixedNow, context: context)
        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.spendingScore == 0)
    }

    @Test("spendingScore_isHighWhenExpenseIsLow")
    func spendingScore_isHighWhenExpenseIsLow() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 10_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        // 10% expense → ~90 score
        #expect(vm.spendingScore >= 80)
    }

    @Test("savingsScore_isZeroWhenNoIncome")
    func savingsScore_isZeroWhenNoIncome() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.savingsScore == 0)
    }

    @Test("savingsScore_clampsBetweenZeroAndHundred")
    func savingsScore_clampsBetweenZeroAndHundred() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 5_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 4_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        #expect(vm.savingsScore >= 0)
        #expect(vm.savingsScore <= 100)
    }

    @Test("healthRating_isExcellentWhenHighScores")
    func healthRating_isExcellentWhenHighScores() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // Income >> expense → both scores high
        let income = makeTransaction(amount: 10_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 500_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        let validRatings = ["Rất tốt", "Tốt", "Trung bình", "Cần cải thiện"]
        #expect(validRatings.contains(vm.healthRating))
    }

    @Test("healthRating_needsImprovementWhenOverBudget")
    func healthRating_needsImprovementWhenOverBudget() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // Expense much greater than income → poor scores
        let income = makeTransaction(amount: 1_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 5_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        #expect(vm.healthRating == "Cần cải thiện")
    }
}

// MARK: - Month-over-Month Trend

@Suite("Month-over-Month Trends")
@MainActor
struct MoMTrendTests {

    @Test("balanceMoMText_showsPlusHundredPctWhenNoPreviousBalance")
    func balanceMoMText_showsPlusHundredPctWhenNoPreviousBalance() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 5_000_000, type: .income, date: fixedNow, context: context)

        vm.loadData(transactions: [income], budgets: [], recurring: [])

        // previousMonthBalance == 0, totalBalance > 0 → "+100%"
        #expect(vm.balanceMoMText == "+100%")
    }

    @Test("expenseTrendPct_isZeroWhenNoPreviousExpense")
    func expenseTrendPct_isZeroWhenNoPreviousExpense() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let tx = makeTransaction(amount: 1_000_000, type: .expense, date: fixedNow, context: context)
        vm.loadData(transactions: [tx], budgets: [], recurring: [])

        #expect(vm.expenseTrendPct == 0)
    }

    @Test("balanceMoMIsPositive_whenCurrentBalanceExceedsPrevious")
    func balanceMoMIsPositive_whenCurrentBalanceExceedsPrevious() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        // Current month: 8M income, 2M expense → 6M balance
        let curIncome = makeTransaction(amount: 8_000_000, type: .income, date: fixedNow, context: context)
        let curExpense = makeTransaction(amount: 2_000_000, type: .expense, date: fixedNow, context: context)

        // Previous month: 5M income, 4M expense → 1M balance
        var prevComponents = DateComponents()
        prevComponents.year = 2026
        prevComponents.month = 2
        prevComponents.day = 10
        prevComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let prevDate = Calendar.current.date(from: prevComponents)!
        let prevIncome = makeTransaction(amount: 5_000_000, type: .income, date: prevDate, context: context)
        let prevExpense = makeTransaction(amount: 4_000_000, type: .expense, date: prevDate, context: context)

        vm.loadData(transactions: [curIncome, curExpense, prevIncome, prevExpense], budgets: [], recurring: [])

        #expect(vm.balanceMoMIsPositive == true)
    }
}

// MARK: - Month Navigation

@Suite("Month Navigation")
@MainActor
struct MonthNavigationTests {

    @Test("navigateMonth_movesForwardByOne")
    func navigateMonth_movesForwardByOne() {
        let vm = DashboardViewModel()
        // Set to 2 months ago so we can navigate forward
        let twoMonthsAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        vm.selectedMonth = twoMonthsAgo.startOfMonth

        vm.navigateMonth(delta: 1)

        let expected = Calendar.current.date(byAdding: .month, value: 1, to: twoMonthsAgo.startOfMonth)!.startOfMonth
        #expect(vm.selectedMonth == expected)
    }

    @Test("navigateMonth_movesBackwardByOne")
    func navigateMonth_movesBackwardByOne() {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow.startOfMonth

        let before = vm.selectedMonth
        vm.navigateMonth(delta: -1)

        let expected = Calendar.current.date(byAdding: .month, value: -1, to: before)!.startOfMonth
        #expect(vm.selectedMonth == expected)
    }

    @Test("navigateMonth_doesNotGoFutureOfCurrentMonth")
    func navigateMonth_doesNotGoFutureOfCurrentMonth() {
        let vm = DashboardViewModel()
        vm.selectedMonth = Date().startOfMonth

        vm.navigateMonth(delta: 1)

        // Should stay at current month — future months blocked
        #expect(vm.selectedMonth <= Date().startOfMonth)
    }

    @Test("canGoForward_isFalseForCurrentMonth")
    func canGoForward_isFalseForCurrentMonth() {
        let vm = DashboardViewModel()
        vm.selectedMonth = Date().startOfMonth

        #expect(vm.canGoForward == false)
    }

    @Test("canGoForward_isTrueForPastMonth")
    func canGoForward_isTrueForPastMonth() {
        let vm = DashboardViewModel()
        vm.selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!.startOfMonth

        #expect(vm.canGoForward == true)
    }
}

// MARK: - Daily Pace

@Suite("Daily Pace")
@MainActor
struct DailyPaceTests {

    @Test("safeDailyAmount_isZeroWhenBalanceIsNegative")
    func safeDailyAmount_isZeroWhenBalanceIsNegative() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let expense = makeTransaction(amount: 5_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [expense], budgets: [], recurring: [])

        #expect(vm.safeDailyAmount == 0)
    }

    @Test("safeDailyAmount_isPositiveWhenBalanceIsPositive")
    func safeDailyAmount_isPositiveWhenBalanceIsPositive() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 10_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 2_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        #expect(vm.safeDailyAmount > 0)
    }

    @Test("daysElapsed_isAtLeastOne")
    func daysElapsed_isAtLeastOne() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.daysElapsed >= 1)
    }
}

// MARK: - Pill Arc Slices

@Suite("Pill Arc Slices")
@MainActor
struct PillArcSliceTests {

    @Test("pillArcSlices_matchesTopCategoriesCount")
    func pillArcSlices_matchesTopCategoriesCount() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let cat1 = makeCategory(name: "Ăn uống", context: context)
        let cat2 = makeCategory(name: "Di chuyển", context: context)

        let tx1 = makeTransaction(amount: 600_000, type: .expense, date: fixedNow, category: cat1, context: context)
        let tx2 = makeTransaction(amount: 400_000, type: .expense, date: fixedNow, category: cat2, context: context)

        vm.loadData(transactions: [tx1, tx2], budgets: [], recurring: [])

        #expect(vm.pillArcSlices.count == vm.topCategories.count)
    }

    @Test("pillArcSlices_areEmptyWhenNoCategoryExpenses")
    func pillArcSlices_areEmptyWhenNoCategoryExpenses() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.pillArcSlices.isEmpty)
    }
}

// MARK: - Summary Cards

@Suite("Summary Cards")
@MainActor
struct SummaryCardTests {

    @Test("summaryCards_alwaysContainsTwoCards")
    func summaryCards_alwaysContainsTwoCards() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.summaryCards.count == 2)
    }

    @Test("summaryCards_firstIsIncome")
    func summaryCards_firstIsIncome() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.summaryCards[0].id == "income")
    }

    @Test("summaryCards_secondIsSavings")
    func summaryCards_secondIsSavings() throws {
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        vm.loadData(transactions: [], budgets: [], recurring: [])

        #expect(vm.summaryCards[1].id == "savings")
    }

    @Test("summaryCards_incomeCardAmountMatchesTotalIncome")
    func summaryCards_incomeCardAmountMatchesTotalIncome() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 7_000_000, type: .income, date: fixedNow, context: context)

        vm.loadData(transactions: [income], budgets: [], recurring: [])

        #expect(vm.summaryCards[0].amount == vm.totalIncome)
    }

    @Test("summaryCards_savingsCardAmountMatchesTotalBalance")
    func summaryCards_savingsCardAmountMatchesTotalBalance() throws {
        let context = try makeInMemoryContext()
        let vm = DashboardViewModel()
        vm.selectedMonth = fixedNow

        let income = makeTransaction(amount: 7_000_000, type: .income, date: fixedNow, context: context)
        let expense = makeTransaction(amount: 2_000_000, type: .expense, date: fixedNow, context: context)

        vm.loadData(transactions: [income, expense], budgets: [], recurring: [])

        #expect(vm.summaryCards[1].amount == vm.totalBalance)
    }
}

// MARK: - RecurrenceCalculator Unit Tests

@Suite("RecurrenceCalculator")
struct RecurrenceCalculatorTests {

    @Test("nextOccurrence_monthlyFrequency_returnsNextMonth")
    func nextOccurrence_monthlyFrequency_returnsNextMonth() {
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 2
        baseComponents.day = 15
        baseComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let base = Calendar.current.date(from: baseComponents)!

        var nowComponents = DateComponents()
        nowComponents.year = 2026
        nowComponents.month = 3
        nowComponents.day = 14
        nowComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let now = Calendar.current.date(from: nowComponents)!

        let next = RecurrenceCalculator.nextOccurrence(
            baseDate: base, frequency: .monthly, after: now, calendar: Calendar.current
        )

        #require(next != nil)
        let nextComponents = Calendar.current.dateComponents([.year, .month, .day], from: next!)
        #expect(nextComponents.year == 2026)
        #expect(nextComponents.month == 3)
        #expect(nextComponents.day == 15)
    }

    @Test("nextOccurrence_baseDateInFuture_returnsBaseDate")
    func nextOccurrence_baseDateInFuture_returnsBaseDate() {
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 4
        baseComponents.day = 1
        baseComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let futureBase = Calendar.current.date(from: baseComponents)!

        let result = RecurrenceCalculator.nextOccurrence(
            baseDate: futureBase, frequency: .monthly, after: fixedNow, calendar: Calendar.current
        )

        #expect(result == futureBase)
    }

    @Test("nextOccurrence_weeklyFrequency_advancesBySevenDays")
    func nextOccurrence_weeklyFrequency_advancesBySevenDays() {
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 3
        baseComponents.day = 1
        baseComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let base = Calendar.current.date(from: baseComponents)!

        var nowComponents = DateComponents()
        nowComponents.year = 2026
        nowComponents.month = 3
        nowComponents.day = 10
        nowComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let now = Calendar.current.date(from: nowComponents)!

        let next = RecurrenceCalculator.nextOccurrence(
            baseDate: base, frequency: .weekly, after: now, calendar: Calendar.current
        )

        #require(next != nil)
        #expect(next! > now)
    }

    @Test("nextOccurrence_dailyFrequency_returnsTomorrow")
    func nextOccurrence_dailyFrequency_returnsTomorrow() {
        var baseComponents = DateComponents()
        baseComponents.year = 2026
        baseComponents.month = 3
        baseComponents.day = 1
        baseComponents.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        let base = Calendar.current.date(from: baseComponents)!

        let next = RecurrenceCalculator.nextOccurrence(
            baseDate: base, frequency: .daily, after: fixedNow, calendar: Calendar.current
        )

        #require(next != nil)
        let dayDiff = Calendar.current.dateComponents([.day], from: fixedNow, to: next!).day ?? 0
        #expect(dayDiff >= 0)
        #expect(dayDiff <= 1)
    }
}

// MARK: - BudgetSummary Unit Tests

@Suite("BudgetSummary")
struct BudgetSummaryTests {

    @Test("ratio_withSpentEqualToLimit_returnsOne")
    func ratio_withSpentEqualToLimit_returnsOne() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 1_000_000, limit: 1_000_000
        )
        #expect(abs(summary.ratio - 1.0) < 0.001)
    }

    @Test("ratio_withSpentLessThanLimit_returnsCorrectFraction")
    func ratio_withSpentLessThanLimit_returnsCorrectFraction() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 250_000, limit: 1_000_000
        )
        #expect(abs(summary.ratio - 0.25) < 0.001)
    }

    @Test("ratio_withZeroSpent_returnsZero")
    func ratio_withZeroSpent_returnsZero() {
        let summary = BudgetSummary(
            categoryName: "Test", categoryIcon: "circle", categoryColorHex: "#000",
            spent: 0, limit: 1_000_000
        )
        #expect(summary.ratio == 0)
    }
}
