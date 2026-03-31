import OSLog
import SwiftUI
import SwiftData

internal struct AppRootView: View {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "QuanLyChiTieu",
        category: "SeedData"
    )

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthService.self) private var authService
    @State private var isBiometricLockEnabled = false
    @State private var appLockService: AppLockService?
    @State private var recurringService = RecurringTransactionService()
    @State private var notificationService = NotificationService()
    private let keychain = KeychainService()

    internal var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView()
            } else if shouldShowLockScreen {
                LockScreenView(
                    lockId: appLockService?.lockId ?? 0,
                    onUnlock: handleUnlock
                )
                .transition(.opacity)
            } else {
                MainTabView()
                    .task {
                        seedDataIfNeeded()
                        processRecurringTransactions()
                        scheduleNotifications()
                    }
                    .transition(.opacity)
            }
        }
        .appSwitcherProtection(isAppLocked: shouldShowLockScreen)
        .animation(Motion.effectDefault, value: shouldShowLockScreen)
        .task { await initializeLockServiceIfNeeded() }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private var shouldShowLockScreen: Bool {
        guard isBiometricLockEnabled else { return false }
        return appLockService?.isLocked ?? false
    }
}

// MARK: - Lifecycle

private extension AppRootView {
    func initializeLockServiceIfNeeded() async {
        let enabled = await keychain.isBiometricLockEnabled()
        isBiometricLockEnabled = enabled
        guard enabled, appLockService == nil else { return }
        let biometricService = BiometricAuthService()
        let service = AppLockService(biometricService: biometricService)
        let timeout = await keychain.loadLockTimeout()
        service.lockTimeout = timeout.interval
        appLockService = service
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        Task { await refreshBiometricState() }
        appLockService?.handleScenePhaseChange(to: phase)
    }

    func refreshBiometricState() async {
        let enabled = await keychain.isBiometricLockEnabled()
        isBiometricLockEnabled = enabled
        if enabled, appLockService == nil {
            let biometricService = BiometricAuthService()
            let service = AppLockService(biometricService: biometricService)
            let timeout = await keychain.loadLockTimeout()
            service.lockTimeout = timeout.interval
            appLockService = service
        } else if enabled, let service = appLockService {
            let timeout = await keychain.loadLockTimeout()
            service.lockTimeout = timeout.interval
        } else if !enabled {
            appLockService = nil
        }
    }

    @discardableResult
    func handleUnlock() async -> Bool {
        await appLockService?.unlockApp() ?? false
    }

    func processRecurringTransactions() {
        do {
            try recurringService.generatePendingTransactions(
                context: modelContext
            )
        } catch {
            Self.logger.error(
                "Recurring transaction generation failed: \(error.localizedDescription)"
            )
        }
    }

    func scheduleNotifications() {
        let currentKey = Date().monthYearKey
        var budgetDescriptor = FetchDescriptor<Budget>()
        budgetDescriptor.predicate = #Predicate<Budget> {
            $0.monthYear == currentKey
        }

        if let budgets = try? modelContext.fetch(budgetDescriptor) {
            let startOfMonth = Date().startOfMonth
            let endOfMonth = Date().endOfMonth
            let expenseType = TransactionType.expense
            var txDescriptor = FetchDescriptor<Transaction>()
            txDescriptor.predicate = #Predicate<Transaction> {
                $0.type == expenseType
                && $0.date >= startOfMonth
                && $0.date <= endOfMonth
            }

            let monthExpenses = (try? modelContext.fetch(txDescriptor)) ?? []

            var spent: [String: Decimal] = [:]
            for tx in monthExpenses {
                let key = currentKey + (tx.category?.name ?? "")
                spent[key, default: 0] += tx.amount
            }

            notificationService.scheduleBudgetAlerts(
                budgets: budgets, spent: spent
            )
        }

        let recurringDescriptor = FetchDescriptor<RecurringTransaction>()
        if let recurring = try? modelContext.fetch(recurringDescriptor) {
            notificationService.scheduleRecurringReminders(
                transactions: recurring
            )
        }
    }

    func seedDataIfNeeded() {
        let key = "com.quanlychitieu.hasSeededCategories.v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        let cats = Category.defaultExpenseCategories.map {
            Category(name: $0.0, icon: $0.1, colorHex: $0.2, type: .expense)
        }
        let incomeCats = Category.defaultIncomeCategories.map {
            Category(name: $0.0, icon: $0.1, colorHex: $0.2, type: .income)
        }
        (cats + incomeCats).forEach { modelContext.insert($0) }

        do {
            try modelContext.save()
            UserDefaults.standard.set(true, forKey: key)
        } catch {
            Self.logger.error("Failed to seed categories: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(
            for: [Transaction.self, Category.self, Budget.self],
            inMemory: true
        )
}
