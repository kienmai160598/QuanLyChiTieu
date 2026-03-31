# UX Research Synthesis — 2026-03-23

**Prepared by:** Teammate 4 (Recommendations Writer)
**Sources:** UX Audit (30 issues), Business Logic Review (24 findings), Competitive Research (feature gap matrix)

---

## 1. Executive Summary

The app has a solid foundation — SwiftData models, Liquid Glass design, biometric auth, and a working transaction flow — but three structural problems prevent it from competing effectively: navigation is buried behind a hamburger menu with no tab bar, critical dashboard sections (budget and upcoming recurring) are built but never rendered, and the budget overview ring calculates against all expenses rather than only budgeted categories, producing misleading data. Beyond these critical fixes, the absence of multi-wallet support and savings goals places the app far behind every major Vietnamese competitor (Money Lover, MISA, Monefy). A phased approach — fix data-correctness bugs first, then add missing core features, then pursue differentiation features like Tet Mode — will maximize user trust and retention at each stage.

---

## 2. Themes

### 2.1 Navigation & Information Architecture

**Current state:** The entire app routes through a hamburger `Menu` on the dashboard toolbar. All features (Transactions, Budget, Recurring, Categories, Insights) are hidden behind a disclosure button that violates iOS conventions.

**Desired state:** A `TabView` with 4-5 primary tabs (Dashboard, Transactions, Budget, Insights, and optionally Settings) provides single-tap access to every major feature. The hamburger menu is eliminated.

**Effort estimate:** M
**Impact estimate:** High

**Key findings:**
1. A1 (UX Audit) — No tab bar; entire app uses hidden hamburger menu
2. A2 (UX Audit) — Menu is non-discoverable (hamburger pattern)
3. MainTabView.swift currently wraps a single `NavigationStack` with `DashboardView` as the only root — it is not a `TabView` at all

---

### 2.2 Transaction Entry & Management

**Current state:** AddTransaction sheet never auto-dismisses after save (form resets, sheet stays open). No auto-focus on amount field forces an extra tap. Transaction list has no date-range filter or category filter, and search only matches note text and category name — not amount.

**Desired state:** AddTransaction auto-dismisses after success animation. Amount field receives focus automatically. Transaction list supports date-range picker, category filter chip, and amount search.

**Effort estimate:** S-M
**Impact estimate:** High

**Key findings:**
1. AT1 (UX Audit) — AddTransaction sheet never auto-dismisses after save
2. AT2 (UX Audit) — No auto-focus on amount field
3. T-1 (Business Logic) — No date-range filter in transaction list
4. T-3 (Business Logic) — No category filter in transaction list

---

### 2.3 Budget System

**Current state:** The budget overview ring in `BudgetListViewModel.loadData` sums ALL month expenses into `totalSpent` but compares against only budgeted-category limits in `totalBudget`, producing a misleading overspend ratio. Copy-to-next-month has zero success feedback. No overall monthly spending cap exists. No auto-rollover of budgets between months.

**Desired state:** `totalSpent` only sums expenses belonging to budgeted categories. Copy-to-next-month shows a success toast. An optional overall monthly cap is available. Budgets can auto-rollover.

**Effort estimate:** S (ring fix) / M (monthly cap + rollover)
**Impact estimate:** High

**Key findings:**
1. B1 (UX Audit) — Budget overview ring compares ALL expenses vs only budgeted categories
2. B-2 (Business Logic) — totalSpent vs totalBudget mismatch (confirms B1)
3. B2 (UX Audit) — Copy-to-next-month has zero success feedback
4. B-1 (Business Logic) — No overall monthly spending cap
5. B-3 (Business Logic) — No auto-rollover of budgets

---

### 2.4 Insights & Analytics

**Current state:** Budget utilization in Insights always uses the current month regardless of the selected period. Week period shows a single-bar monthly trend (useless). Income category breakdown is missing. No savings rate or net worth metric.

**Desired state:** All Insights charts respect the selected `TimePeriod`. Week view shows daily bars. Income breakdown is included. A savings rate card is displayed.

**Effort estimate:** M
**Impact estimate:** Medium

**Key findings:**
1. I-4/I-5 (Business Logic) — Budget utilization in Insights ignores selected period
2. I-2 (Business Logic) — Week period shows single-bar monthly trend
3. I-3 (Business Logic) — Income category breakdown missing
4. I-6 (Business Logic) — No savings rate or net worth

---

### 2.5 Data Integrity & Model

**Current state:** `RecurringTransactionService.generatePendingTransactions` has no idempotency guard — a double-call on the same launch or a background/foreground cycle creates duplicate transactions. Deleting a category orphans its transactions (nullifies the relationship) which distorts calculations that group by category. `AppMigrationPlan.stages` is empty, so any future schema change risks data loss. Orphaned budget records accumulate after category deletion.

**Desired state:** Recurring generation uses a date-based idempotency check (e.g., compare `lastGeneratedDate` before inserting). Category deletion either reassigns transactions to an "Other" category or explicitly warns and handles orphans. Migration stages are defined for each schema change. Orphaned budgets are cleaned up on category delete.

**Effort estimate:** M
**Impact estimate:** High (data correctness)

**Key findings:**
1. R-4 (Business Logic) — generatePendingTransactions has no idempotency guard
2. D-1 (Business Logic) — Orphaned transactions after category delete distort calculations
3. D-5 (Business Logic) — AppMigrationPlan.stages is empty
4. D-2 (Business Logic) — Orphaned budget records accumulate after category deletion
5. C2 (UX Audit) — Deleting category orphans transactions without clear warning

---

### 2.6 Recurring Transactions

**Current state:** `AddRecurringView` has no discard guard — unsaved data is lost on accidental back-swipe. Only 4 frequencies exist (daily, weekly, monthly, yearly); no biweekly or custom interval. Notification service `nextOccurrence` algorithm diverges from `RecurringTransactionService.calculateNextOccurrence`, which can produce misaligned reminder dates.

**Desired state:** Discard confirmation is shown when `hasChanges` is true. Biweekly and custom intervals are supported. Notification and generation services share a single next-occurrence calculator.

**Effort estimate:** S (discard guard) / M (intervals + unified calculator)
**Impact estimate:** Medium

**Key findings:**
1. R1 (UX Audit) — AddRecurringView has no discard guard
2. R-1/R-2 (Business Logic) — No custom interval or biweekly recurrence
3. R-5 (Business Logic) — Notification service next-occurrence diverges from generation service

---

### 2.7 Onboarding & Profile

**Current state:** Onboarding collects language preference and shows a budget intro, but never asks for the user's name. The user is displayed as "Ban" forever until they manually navigate to ProfileSetup through the hamburger menu. AuthView sheet has no dismiss/cancel button, and sign-in benefits are never explained.

**Desired state:** Onboarding includes a name-collection step. AuthView has a dismiss button and briefly explains sync/backup benefits. ProfileSetup is discoverable from the dashboard header.

**Effort estimate:** S
**Impact estimate:** Medium

**Key findings:**
1. O1 (UX Audit) — No name collection in onboarding
2. AU1 (UX Audit) — No dismiss/cancel button on AuthView sheet
3. AU3 (UX Audit) — Sign-in benefits never explained

---

### 2.8 Settings & Preferences

**Current state:** Language change sets `UserDefaults` and `AppleLanguages` but provides no restart mechanism — the app continues displaying the old language until killed and relaunched. Notification toggle only calls `requestAuthorization` and cannot actually disable notifications once granted (iOS requires directing users to Settings.app). Profile save failure is completely silent. Color palette for categories has only 10 dark colors.

**Desired state:** Language change triggers an in-app restart prompt (or applies immediately via `LanguageManager`). Notification toggle opens Settings.app when notifications are already authorized. Profile save shows an error alert on failure. Color palette expanded to 20+ colors including lighter tones.

**Effort estimate:** S
**Impact estimate:** Medium

**Key findings:**
1. S1 (UX Audit) — Language change requires restart with no restart mechanism
2. S2 (UX Audit) — Notification toggle cannot actually disable iOS notifications
3. P1 (UX Audit) — Profile save failure completely silent
4. C1 (UX Audit) — Color palette only 10 dark colors

---

### 2.9 Missing Financial Features

**Current state:** The app tracks only simple income/expense transactions in a single implicit wallet. No savings goals, debt/loan tracking, account/wallet system, multi-currency, transfer between accounts, or opening balance exist. Every major Vietnamese competitor (Money Lover, MISA, Monefy) supports at least multi-wallet and savings goals.

**Desired state:** A multi-wallet/account system is the structural foundation. Savings goals allow users to set targets and track progress. Debt tracking records loans with interest calculations. Transfers between wallets are first-class transaction types.

**Effort estimate:** L-XL
**Impact estimate:** High

**Key findings:**
1. Competitive Research — No multi-wallet system (biggest structural gap vs all competitors)
2. Competitive Research — Savings goals (S-M effort, high competitive impact)
3. Competitive Research — Debt/loan tracking (M effort)
4. Competitive Research — Bill due reminders (S-M effort)
5. Business Logic — Missing: savings goals, debt tracking, net worth, account/wallet system, multi-currency, bill reminders, transfer between accounts, opening balance

---

### 2.10 Vietnamese-Specific Features

**Current state:** No features cater specifically to Vietnamese financial habits. Competitors like MISA offer gold price tracking, PIT tax calculator, 6-jar budgeting, and receipt scanning. No app in the market offers Tet Mode / seasonal budgeting.

**Desired state:** Tet Mode provides a dedicated seasonal budget overlay for the Lunar New Year period (li xi tracking, holiday spending categories, pre-Tet savings targets). PIT tax calculator helps salaried users estimate tax. Gold price tracking integrates SJC rates.

**Effort estimate:** M-L
**Impact estimate:** Medium-High (differentiation)

**Key findings:**
1. Competitive Research — Tet Mode / seasonal budgeting (clearest white space, nobody has it)
2. Competitive Research — PIT tax calculator (S effort)
3. Competitive Research — Gold price tracking (M effort)
4. Competitive Research — Receipt OCR scanning (M effort)
5. Competitive Research — MISA is most formidable local competitor (free, gold tracking, tax calc, receipt scanning, 6-jar method)

---

## 3. Impact/Effort Matrix

### High Impact + Small Effort — DO FIRST

| Item | Source | Effort | Theme |
|------|--------|--------|-------|
| Fix budget overview ring (only sum budgeted-category expenses) | B1/B-2 | S | Budget |
| Render DashboardBudgetSection + DashboardUpcomingRecurring in DashboardView.body | D1 | S | Dashboard |
| Auto-dismiss AddTransaction sheet after save | AT1 | S | Transaction Entry |
| Auto-focus amount field in AddTransaction | AT2 | S | Transaction Entry |
| Add idempotency guard to generatePendingTransactions | R-4 | S | Data Integrity |
| Add discard guard to AddRecurringView | R1 | S | Recurring |
| Add dismiss/cancel button to AuthView | AU1 | S | Onboarding |
| Copy-to-next-month success feedback | B2 | S | Budget |
| Profile save failure error alert | P1 | S | Settings |

### High Impact + Medium/Large Effort — PLAN NEXT

| Item | Source | Effort | Theme |
|------|--------|--------|-------|
| Replace hamburger menu with TabView | A1/A2 | M | Navigation |
| Multiple wallets/accounts | Competitive | M-L | Financial Features |
| Savings goals | Competitive | S-M | Financial Features |
| Category delete: reassign or warn about orphaned transactions + budgets | D-1/D-2/C2 | M | Data Integrity |
| Define AppMigrationPlan stages | D-5 | M | Data Integrity |
| Add name collection to onboarding | O1 | S-M | Onboarding |
| Date-range filter in transaction list | T-1 | M | Transaction Mgmt |
| Insights: respect selected period for budget utilization | I-4/I-5 | M | Insights |
| Overall monthly spending cap | B-1 | M | Budget |

### Medium Impact + Small Effort — QUICK WINS

| Item | Source | Effort | Theme |
|------|--------|--------|-------|
| Expand category color palette to 20+ colors | C1 | S | Settings |
| Notification toggle opens Settings.app when denied | S2 | S | Settings |
| Language change restart prompt | S1 | S | Settings |
| Explain sign-in benefits on AuthView | AU3 | S | Onboarding |
| Bill due reminders | Competitive | S-M | Financial Features |
| PIT tax calculator | Competitive | S | Vietnamese Features |
| Home screen widgets | Competitive | S | Engagement |
| Category filter in transaction list | T-3 | S | Transaction Mgmt |

### Low Impact + Any Effort — BACKLOG

| Item | Source | Effort | Theme |
|------|--------|--------|-------|
| Biweekly + custom recurrence intervals | R-1/R-2 | M | Recurring |
| Unify notification/generation next-occurrence calculators | R-5 | S | Recurring |
| Week period daily bars in Insights | I-2 | S | Insights |
| Income category breakdown in Insights | I-3 | S | Insights |
| Savings rate / net worth metric | I-6 | M | Insights |
| Auto-rollover budgets | B-3 | M | Budget |
| Gold price tracking | Competitive | M | Vietnamese Features |
| Receipt OCR scanning | Competitive | M | Vietnamese Features |
| Event/trip budget | Competitive | M | Financial Features |
| Tet Mode / seasonal budgeting | Competitive | M | Vietnamese Features |
| Debt/loan tracking | Competitive | M | Financial Features |
| Multi-currency support | Business Logic | L | Financial Features |
| Transfer between accounts | Business Logic | M | Financial Features |

---

## 4. Phased Roadmap

### Phase 1 — Quick Wins (1-2 sessions each, ship immediately)

These items fix critical bugs, data-correctness issues, and small UX gaps. Each can be completed in a single focused session.

#### P1-01: Fix budget overview ring — use only budgeted-category expenses
- **Source:** B1 (UX Audit), B-2 (Business Logic)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Budget/BudgetListViewModel.swift` — change `loadData` to filter `monthExpenses` to only categories that have a budget before summing into `totalSpent`
- **Dependencies:** None

#### P1-02: Render DashboardBudgetSection + DashboardUpcomingRecurring in DashboardView.body
- **Source:** D1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Dashboard/DashboardView.swift` — add `DashboardBudgetSection` and `DashboardUpcomingRecurring` to the `LazyVStack` in `body`, each inside its own `GlassEffectContainer`
  - `QuanLyChiTieu/Features/Dashboard/DashboardBudgetSection.swift` (already built)
  - `QuanLyChiTieu/Features/Dashboard/DashboardUpcomingRecurring.swift` (already built)
- **Dependencies:** None

#### P1-03: Auto-dismiss AddTransaction sheet after save
- **Source:** AT1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/AddTransaction/AddTransactionViewModel.swift` — after success animation completes, set a `shouldDismiss` flag
  - `QuanLyChiTieu/Features/AddTransaction/AddTransactionView.swift` — observe `shouldDismiss` and call `dismiss()`
- **Dependencies:** None

#### P1-04: Auto-focus amount field in AddTransaction
- **Source:** AT2 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/AddTransaction/AddTransactionView.swift` — add `@FocusState` and `.focused()` modifier with `.onAppear { focused = true }`
- **Dependencies:** None

#### P1-05: Add idempotency guard to generatePendingTransactions
- **Source:** R-4 (Business Logic)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Core/Services/RecurringTransactionService.swift` — before inserting a transaction in `insertTransaction(from:date:context:)`, query existing transactions matching the same amount, note, date, and category to prevent duplicates; or use a `generationId` stored on each emitted transaction
- **Dependencies:** Possibly a lightweight schema change to `Transaction` (add optional `recurringSourceId` field) — coordinate with P1-08

#### P1-06: Add discard guard to AddRecurringView
- **Source:** R1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Transactions/AddRecurringView.swift` — add `.interactiveDismissDisabled(viewModel.hasChanges)` and a confirmation dialog
  - `QuanLyChiTieu/Features/Transactions/AddRecurringViewModel.swift` — add `hasChanges` computed property
- **Dependencies:** None

#### P1-07: Add dismiss/cancel button to AuthView sheet
- **Source:** AU1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Auth/AuthView.swift` — add a dismiss button (X or "Huy") at the top of `contentView`
- **Dependencies:** None

#### P1-08: Define AppMigrationPlan stages (non-empty)
- **Source:** D-5 (Business Logic)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Models/SchemaVersioning.swift` — define a SchemaV2 and the corresponding `MigrationStage` so future schema changes are safe
- **Dependencies:** Should be done before any model changes

#### P1-09: Copy-to-next-month success feedback
- **Source:** B2 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Budget/BudgetListViewModel.swift` — add a `copySuccess: Bool` state flag
  - `QuanLyChiTieu/Features/Budget/BudgetListView.swift` — show a toast/banner when `copySuccess` is true
- **Dependencies:** None

#### P1-10: Profile save failure error alert
- **Source:** P1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Dashboard/ProfileSetupViewModel.swift` — surface save errors via an `errorMessage` state property
  - `QuanLyChiTieu/Features/Dashboard/ProfileSetupView.swift` — present `.alert` bound to `errorMessage`
- **Dependencies:** None

#### P1-11: Notification toggle opens Settings.app when denied
- **Source:** S2 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Settings/SettingsViewModel.swift` — in `toggleNotifications()`, when status is `.denied`, open `UIApplication.openSettingsURLString`
  - `QuanLyChiTieu/Features/Settings/SettingsSectionViews.swift` — update toggle UI to show "Open Settings" action when denied
- **Dependencies:** None

#### P1-12: Expand category color palette
- **Source:** C1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Categories/AddCategorySheet.swift` — expand the color array to include 20+ options with lighter tones
  - `QuanLyChiTieu/Features/Categories/AddCategoryViewModel.swift` — update default color list
- **Dependencies:** None

#### P1-13: Language change restart prompt
- **Source:** S1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Core/Services/LanguageManager.swift` — add a `languageDidChange` callback or published flag
  - `QuanLyChiTieu/Features/Settings/SettingsView.swift` — show an alert prompting the user to restart the app after language change
- **Dependencies:** None

#### P1-14: Explain sign-in benefits on AuthView
- **Source:** AU3 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Auth/AuthView.swift` — add a brief text section below the branding explaining sync/backup benefits
- **Dependencies:** None

---

### Phase 2 — Core Improvements (3-5 sessions each)

These items require more design thought and implementation work but significantly improve the core experience.

#### P2-01: Replace hamburger menu with TabView
- **Source:** A1/A2 (UX Audit)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Placeholder/MainTabView.swift` — rewrite as a proper `TabView` with 4 tabs (Dashboard, Transactions, Budget, Insights), each with its own `NavigationStack`
  - `QuanLyChiTieu/Features/Dashboard/DashboardView.swift` — remove hamburger `Menu` from toolbar
  - `QuanLyChiTieu/App/AppRoutes.swift` — potentially refactor route enums per tab
- **Dependencies:** None, but should be done early as it reshapes the entire app shell

#### P2-02: Savings goals
- **Source:** Competitive Research (rank #2)
- **Effort:** S-M
- **Files likely affected:**
  - New `QuanLyChiTieu/Models/SavingsGoal.swift` — `@Model` with name, targetAmount, currentAmount, deadline, icon, colorHex
  - New `QuanLyChiTieu/Features/SavingsGoals/` — SavingsGoalListView, AddSavingsGoalSheet, SavingsGoalViewModel
  - `QuanLyChiTieu/Models/SchemaVersioning.swift` — add to schema
  - `QuanLyChiTieu/Placeholder/MainTabView.swift` — add navigation route or tab
- **Dependencies:** P1-08 (migration plan)

#### P2-03: Home screen widgets
- **Source:** Competitive Research (rank #1, S effort)
- **Effort:** S
- **Files likely affected:**
  - New widget extension target in Xcode project
  - Shared `AppGroup` container for SwiftData access
  - Widget views showing balance, daily spend, budget progress
- **Dependencies:** None, but benefits from P1-01 (correct budget data)

#### P2-04: Category delete handling — reassign orphaned transactions + budgets
- **Source:** D-1/D-2/C2 (Business Logic, UX Audit)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Categories/CategoryListViewModel.swift` — in `deleteCategory`, before deleting, reassign transactions and budgets to an "Other" category or show a detailed warning with counts
  - `QuanLyChiTieu/Models/Category.swift` — ensure delete rule handles orphans correctly or use manual reassignment
- **Dependencies:** None

#### P2-05: Date-range filter in transaction list
- **Source:** T-1 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Transactions/TransactionListView.swift` — add `@State` for start/end date, add a date range picker UI, update `filtered` computed property
  - `QuanLyChiTieu/Features/Transactions/TransactionFilterChips.swift` — add date chip
- **Dependencies:** None

#### P2-06: Category filter in transaction list
- **Source:** T-3 (Business Logic)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Transactions/TransactionListView.swift` — add `@State` for selectedCategory, update `filtered`
  - `QuanLyChiTieu/Features/Transactions/TransactionFilterChips.swift` — add category filter chip group
- **Dependencies:** None

#### P2-07: Insights — respect selected period for budget utilization
- **Source:** I-4/I-5 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Insights/InsightsViewModel.swift` — change `budgetSpent(for:transactions:)` to use `dateRange` instead of hardcoded current month
  - `QuanLyChiTieu/Features/Insights/Components/BudgetUtilizationCard.swift` — pass selected period context
- **Dependencies:** None

#### P2-08: Insights — week period daily bars + income breakdown
- **Source:** I-2/I-3 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Insights/InsightsViewModel.swift` — add `dailyTrend(from:)` method for week period; add `incomeCategoryBreakdown(from:)` method
  - `QuanLyChiTieu/Features/Insights/Components/MonthlyTrendChart.swift` — conditionally render daily bars when period is `.week`
  - New `QuanLyChiTieu/Features/Insights/Components/IncomeCategoryChart.swift`
- **Dependencies:** None

#### P2-09: Overall monthly spending cap
- **Source:** B-1 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Models/Budget.swift` — add an optional `isOverallCap` flag, or create a separate `MonthlyBudgetCap` model
  - `QuanLyChiTieu/Features/Budget/BudgetListViewModel.swift` — check overall cap in calculations
  - `QuanLyChiTieu/Features/Budget/BudgetListView.swift` — display overall cap UI
- **Dependencies:** P1-08 (migration plan)

#### P2-10: Name collection in onboarding
- **Source:** O1 (UX Audit)
- **Effort:** S
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Onboarding/OnboardingViewModel.swift` — add `userName` state, save to `UserProfile` on completion
  - New `QuanLyChiTieu/Features/Onboarding/Pages/NamePage.swift` — name input page
  - `QuanLyChiTieu/Features/Onboarding/OnboardingView.swift` — add NamePage to page sequence, update `totalPages`
- **Dependencies:** None

#### P2-11: Bill due reminders
- **Source:** Competitive Research (rank #7)
- **Effort:** S-M
- **Files likely affected:**
  - `QuanLyChiTieu/Core/Services/NotificationService.swift` — add bill-specific reminder scheduling
  - Could reuse `RecurringTransaction` with an `isBillReminder` flag, or create a dedicated model
- **Dependencies:** P2-02 or standalone

#### P2-12: Multiple wallets/accounts
- **Source:** Competitive Research (rank #3, biggest structural gap)
- **Effort:** M-L
- **Files likely affected:**
  - New `QuanLyChiTieu/Models/Wallet.swift` — `@Model` with name, balance, icon, type (cash/bank/e-wallet), currency
  - `QuanLyChiTieu/Models/Transaction.swift` — add `@Relationship` to Wallet
  - `QuanLyChiTieu/Models/SchemaVersioning.swift` — SchemaV2 migration
  - `QuanLyChiTieu/Features/Dashboard/DashboardViewModel.swift` — filter by selected wallet
  - New `QuanLyChiTieu/Features/Wallets/` — WalletListView, WalletDetailView, AddWalletSheet
  - All views/viewmodels that query transactions need wallet-awareness
- **Dependencies:** P1-08 (migration plan must be in place before schema changes)

---

### Phase 3 — Major Features (dedicated build-feature teams)

These items require full feature design, new models, and potentially external API integrations.

#### P3-01: Tet Mode / Seasonal Budgeting
- **Source:** Competitive Research (rank #6, clearest white space)
- **Effort:** M
- **Files likely affected:**
  - New `QuanLyChiTieu/Features/TetMode/` — TetBudgetView, TetBudgetViewModel
  - New categories: li xi given, li xi received, holiday food, decorations, travel
  - `QuanLyChiTieu/Models/Budget.swift` — add seasonal budget type or date-range-based budget
  - Dashboard banner/card during Tet season
- **Dependencies:** P2-09 (date-range budgets foundation)

#### P3-02: Debt / Loan Tracking
- **Source:** Competitive Research (rank #4)
- **Effort:** M
- **Files likely affected:**
  - New `QuanLyChiTieu/Models/Debt.swift` — `@Model` with lender/borrower, principal, interestRate, startDate, endDate, payments
  - New `QuanLyChiTieu/Features/Debt/` — DebtListView, DebtDetailView, AddDebtSheet, DebtViewModel
  - `QuanLyChiTieu/Models/SchemaVersioning.swift`
- **Dependencies:** P1-08 (migration plan), P2-12 (wallet system for tracking repayments)

#### P3-03: Receipt OCR Scanning
- **Source:** Competitive Research (rank #5)
- **Effort:** M
- **Files likely affected:**
  - New `QuanLyChiTieu/Features/ReceiptScan/` — ReceiptScanView (camera), ReceiptParser (Vision framework)
  - `QuanLyChiTieu/Features/AddTransaction/AddTransactionView.swift` — add scan button
  - `QuanLyChiTieu/Features/AddTransaction/AddTransactionViewModel.swift` — populate from scan result
- **Dependencies:** None (can be built independently)

#### P3-04: Event / Trip Budget
- **Source:** Competitive Research (rank #9)
- **Effort:** M
- **Files likely affected:**
  - New `QuanLyChiTieu/Models/Event.swift` — `@Model` with name, startDate, endDate, budgetLimit
  - New `QuanLyChiTieu/Features/Events/` — EventListView, EventDetailView, AddEventSheet
  - `QuanLyChiTieu/Models/Transaction.swift` — optional `@Relationship` to Event
- **Dependencies:** P1-08 (migration plan)

#### P3-05: Gold Price Tracking
- **Source:** Competitive Research (rank #8)
- **Effort:** M
- **Files likely affected:**
  - New `QuanLyChiTieu/Core/Services/GoldPriceService.swift` — fetch SJC gold rates from API
  - New `QuanLyChiTieu/Features/Gold/` — GoldPriceView, GoldHoldingView
  - Network layer with certificate pinning
- **Dependencies:** External API integration, network layer

#### P3-06: PIT Tax Calculator
- **Source:** Competitive Research (rank #10)
- **Effort:** S
- **Files likely affected:**
  - New `QuanLyChiTieu/Features/Tax/` — PITCalculatorView, PITCalculatorViewModel
  - Pure calculation logic based on Vietnamese PIT brackets (no external API needed)
- **Dependencies:** None

#### P3-07: Savings Rate / Net Worth
- **Source:** I-6 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Insights/InsightsViewModel.swift` — add `savingsRate(from:)` method
  - New `QuanLyChiTieu/Features/Insights/Components/SavingsRateCard.swift`
  - `QuanLyChiTieu/Features/Insights/InsightsView.swift` — add savings rate section
- **Dependencies:** P2-12 (wallets) for net worth calculation

#### P3-08: Budget Auto-Rollover
- **Source:** B-3 (Business Logic)
- **Effort:** M
- **Files likely affected:**
  - `QuanLyChiTieu/Features/Budget/BudgetListViewModel.swift` — add auto-rollover logic on month change
  - `QuanLyChiTieu/Models/Budget.swift` — add `autoRollover` boolean flag
- **Dependencies:** P1-08 (migration plan)

---

## 5. Open Questions

### From UX Audit
1. **Tab bar scope:** Should the tab bar have 4 tabs (Dashboard, Transactions, Budget, Insights) or 5 (adding a dedicated Settings tab)? The current settings are reachable via a gear icon in the toolbar — is that sufficient?
2. **AddTransaction dismiss timing:** Should the sheet auto-dismiss immediately after save, or after the 1.2-second success animation completes? Users may want to add another transaction quickly.
3. **Balance hero metric:** The dashboard hero currently shows balance (income - expense). UX Audit flagged D2 that it "shows expenses instead." Should the hero prominently display balance, with income/expense as secondary metrics, or should it lead with spending? Need user preference data.
4. **Category delete orphan strategy:** Should orphaned transactions be reassigned to a default "Other" category automatically, or should the user be forced to choose a replacement category before deletion is allowed?
5. **Color palette design:** The expanded palette needs design review — should it use Material Design 3 tonal palettes, or a curated set of Vietnamese-aesthetic colors?

### From Business Logic Review
6. **Idempotency mechanism:** Should the recurring transaction idempotency guard use a date-match check against existing transactions, or should each generated transaction store a `recurringSourceId + generatedDate` composite key? The latter is more robust but requires a schema change.
7. **Migration plan urgency:** The empty `AppMigrationPlan.stages` is a ticking time bomb. Should we define SchemaV2 proactively now (before adding any new models like Wallet, SavingsGoal, Debt), or wait until the first feature that requires a schema change?
8. **Budget utilization period:** When Insights is set to "3 months," should budget utilization show 3 separate months of budget data, or aggregate them? Most users likely expect monthly granularity.
9. **Notification service divergence (R-5):** The `NotificationService.nextOccurrence` and `RecurringTransactionService.calculateNextOccurrence` use different algorithms. Should we extract a shared `RecurrenceCalculator` utility, or is the simpler notification algorithm acceptable since it only needs approximate dates for reminders?

### From Competitive Research
10. **Multi-wallet priority:** Multi-wallet is the biggest structural gap vs competitors, but it is also the most invasive change (touches every query). Should it be prioritized in Phase 2, or deferred to Phase 3 to avoid destabilizing the app while critical bugs are being fixed?
11. **Tet Mode timing:** Tet 2027 is late January. If we want Tet Mode ready for 2027, development should start by October 2026. Is this timeline realistic given the Phase 1 and Phase 2 backlog?
12. **Gold price API:** Which gold price API should we use for SJC rates? Options include scraping SJC's website (fragile), using a third-party aggregator, or partnering with a Vietnamese fintech data provider. Certificate pinning is required per security rules.
13. **Receipt OCR scope:** Should receipt scanning only extract total amount and date, or should it attempt to parse individual line items? Line-item parsing is significantly harder and may require a cloud ML model rather than on-device Vision.
14. **Competitive positioning:** Given MISA's dominance in the free tier (gold tracking, tax calc, receipt scanning, 6-jar method), should we compete on features or differentiate on design quality (Liquid Glass) and privacy (no account required, local-first data)?

---

*This document consolidates findings from the UX Audit (30 issues), Business Logic Review (24 findings), and Competitive Research (feature gap matrix). It should be revisited after Phase 1 is complete to re-prioritize Phase 2 items based on user feedback and usage data.*
