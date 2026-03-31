# Overview Tab Renovation Brief

> **Author:** BAUX (Business Analyst / UX Researcher)
> **Date:** 2026-03-16
> **Status:** Ready for UXUI design spec (Task #2)
> **Scope:** DashboardView.swift + DashboardViewModel.swift renovation

---

## 1. Current State Analysis

### What Exists Today

The Overview tab (`DashboardView.swift`, 230 lines) is a vertical `ScrollView` with 5 sections:

| # | Section | Source | What It Shows |
|---|---------|--------|---------------|
| 1 | **Balance Hero** | `balanceHero` | Current month name (uppercase), formatted balance (display medium), "So du hien tai" label |
| 2 | **Flow Row** | `flowRow` | Two `M3Card`s side-by-side: income (compact VND, green) and expense (compact VND, red) |
| 3 | **Chart Card** | `chartCard` | Section header "Chi tieu theo danh muc" + donut chart (160pt) + divider + horizontal bar chart. Shows top 5 expense categories with name, amount, ratio |
| 4 | **Recent Transactions** | `recentSection` | "Gan day" header + last 5 transactions as `M3TransactionRow` in an `M3Card`. Each row: icon badge, title, date, signed amount. Taps navigate to detail |
| 5 | **Insights Link** | `insightsLink` | `M3OutlinedCard` with icon + "Xem bao cao chi tiet" + arrow. Navigates to `InsightsView` |

### ViewModel (DashboardViewModel.swift, 130 lines)

**State properties:**
- `totalIncome`, `totalExpense` (Decimal) -- current month only
- `recentTransactions` ([Transaction]) -- last 5 globally (NOT month-scoped)
- `topCategories` ([CategorySpend]) -- top 5 expense categories this month

**Derived properties:**
- `totalBalance`, `formattedBalance`, `formattedIncome`, `formattedExpense`
- `compactIncome`, `compactExpense` -- abbreviated VND strings
- `spendingRatio` (Double) -- expense/income ratio, **computed but never used in UI**
- `balanceColor` -- green if positive, red if negative
- `currentMonthName` -- Vietnamese month name
- `donutSlices`, `barItems` -- chart data transforms

**Data loading:** Single `loadData(transactions:)` method filters current month, computes totals, takes last 5 global transactions, builds category breakdown.

### Strengths
- Clean MVVM separation; view is purely declarative
- Proper `@Observable` + `@MainActor` pattern
- Good use of `M3Card`, `M3MetricPill`, `M3TransactionRow` shared components
- Responsive to data changes via `.onChange(of:)` + `.task`
- Well within 300-line file limit
- Vietnamese locale for month formatting
- VND formatting via shared `.formattedVND` / `.compactVND` extensions

---

## 2. UX Pain Points

### P1. No Budget Integration (Critical)
The `Budget` model (`limitAmount`, `monthYear`, `category`) exists and is fully functional in `BudgetListView`. But the Dashboard -- the first screen users see -- shows zero budget information. Users must manually switch to the Budget tab (tab index 3) to check if they're overspending. This is the single biggest gap.

### P2. No Spending Velocity / Pace Indicator (High)
The dashboard shows total expense but provides no context for whether the user is spending faster or slower than sustainable. A user who spent 5.000.000 VND on day 5 vs. day 25 is in very different financial situations, but the dashboard treats them identically.

### P3. No Temporal Context (High)
The month name is displayed but there's no "X days remaining" or "day Y of Z" indicator. Without this, the balance figure is not actionable -- the user cannot gauge whether their remaining funds will last the month.

### P4. Recent Transactions Are Global (High)
`recentTransactions = Array(transactions.prefix(5))` takes the 5 most recent transactions regardless of month. If a user added January transactions while viewing February's overview, those January items appear. This is inconsistent with the month-scoped totals above them.

### P5. No Quick Actions (Medium)
The Overview tab is read-only. To add a transaction, the user must tap the "Them" tab (tab index 2). A quick-action affordance on the overview could reduce the most common action to one tap.

### P6. No Recurring Transaction Awareness (Medium)
`RecurringTransaction` model exists with `amount`, `frequency`, `isActive`, `startDate`, and `lastGeneratedDate`. Active recurring transactions represent upcoming bills the user needs to prepare for. None of this is surfaced on the dashboard.

### P7. Chart Section Is Too Heavy (Medium)
The donut chart (160pt diameter) plus horizontal bar chart together consume significant scroll space. For an overview screen, this level of detail belongs in the Insights tab. The overview should show a compact summary, not a full analytical chart.

### P8. Spending Ratio Computed But Unused (Low)
`spendingRatio` (expense/income as 0-1 Double) is calculated in the ViewModel but no UI element displays it. This is wasted computation and a missed opportunity for a visual budget health indicator.

### P9. No Liquid Glass on Chrome (Low)
Per CLAUDE.md, `.glassEffect()` should be applied to navigation chrome (toolbars, FABs). The current DashboardView has no glass-treated elements. If a floating action or toolbar element is added, it must use `.glassEffect()`.

### P10. No Budget Health Alerts (Medium)
When a category budget is at 90%+ utilization, there's no warning on the overview. The `BudgetListViewModel` already computes `progressColorFor()` with red/orange/green thresholds -- this logic should be surfaced on the dashboard for at-risk budgets.

---

## 3. User Needs Assessment

### Primary User Profile
Vietnamese individual tracking personal/household expenses in VND. Opens the app daily or every few days, primarily to:
1. **Check financial health** -- "Am I on track this month?"
2. **Log a new expense** -- quickly after a purchase
3. **Review recent activity** -- "What did I spend on recently?"

### What Users Need at First Glance (Priority Order)

| Priority | Need | Vietnamese Phrasing | Current Coverage |
|----------|------|---------------------|-----------------|
| **1st** | How much money do I have left? | "Thang nay minh con bao nhieu tien?" | Partial -- balance shown but no budget context |
| **2nd** | Am I on track or overspending? | "Minh dang chi tieu co on khong?" | Missing -- no velocity, no budget progress |
| **3rd** | Which budgets are at risk? | "Ngan sach danh muc nao sap het?" | Missing entirely |
| **4th** | What's my safe daily spend? | "Hom nay minh chi duoc bao nhieu?" | Missing entirely |
| **5th** | What did I spend on recently? | "Gan day minh mua gi?" | Partial -- global not month-scoped |
| **6th** | Top spending categories? | "Minh chi nhieu nhat vao gi?" | Covered but oversized |
| **7th** | Any upcoming bills? | "Sap toi co khoan nao tu tru?" | Missing entirely |
| **8th** | Detailed analytics | "Xem bao cao chi tiet" | Covered via Insights link |

---

## 4. Proposed New Sections

### Section A: Balance Hero (Revised)

**Current:** Month name + balance + "So du hien tai" label in an `M3Card`.

**Proposed:** Enhanced hero that merges Balance Hero + Flow Row into one denser, more informative card:
- Balance as primary number (keep `displayMedium` font)
- **Spending ratio ring** around or beside the balance (reuse existing `spendingRatio` computation)
- Ring color: `appPrimary` (green, <70%) -> `appWarning` (orange, 70-89%) -> `appError` (red, 90%+)
- Month name + "con X ngay" (days remaining) as subtitle
- Income/Expense figures shown inline below balance (compact, two columns)

**Rationale:** Merges two sections into one. The ring gives instant visual feedback on spending health. Temporal context makes balance actionable. Addresses P3 and P8.

**Data needed:**
- `daysElapsed: Int`, `daysInMonth: Int`, `daysRemaining: Int` (computed from `Calendar`)
- `temporalLabel: String` -- e.g., "Ngay 16/31 -- con 15 ngay"
- Existing `spendingRatio` (already computed)

### Section B: Budget Health Summary (New -- Critical)

**What:** A compact card showing overall budget utilization + up to 3 at-risk or highest-utilization category budgets with mini progress bars.

**Layout:**
- Header: "Ngan sach thang nay" with overall percentage badge
- Each budget row: category icon + name + `M3ProgressBar` + "X / Y" compact amounts
- Color coding: green (<70%), orange (70-89%), red (90%+)
- "Xem tat ca" link to Budget tab if more than 3 budgets exist
- Hidden entirely if user has no budgets (clean empty handling)

**Rationale:** Addresses P1 (no budget integration) and P10 (no alerts). Budget health is the #2 user need. The `BudgetListViewModel` already has all the computation logic (`spentFor`, `progressFor`, `progressColorFor`) -- this needs to be adapted into `DashboardViewModel`.

**Data needed:**
- `@Query private var budgets: [Budget]` in the view (or passed to ViewModel)
- `budgetSummaries: [BudgetSummary]` -- struct with category name, icon, colorHex, spent, limit, progress, progressColor
- `overallBudgetProgress: Double`
- `overallBudgetColor: Color`
- `hasBudgets: Bool`

### Section C: Spending Velocity Card (New -- High Value)

**What:** A single compact card showing daily spending pace.

**Content:**
- "Toc do chi tieu" (Spending velocity) header
- Primary metric: safe daily amount -- "(monthBalance or budgetRemaining) / daysRemaining"
- Secondary: actual daily average so far -- "totalExpense / daysElapsed"
- Visual indicator: green if daily avg < safe limit, orange if close, red if over
- One-line insight: "Ban dang chi [nhieu hon / it hon] X/ngay so voi muc an toan"
- If over budget for the month: "Da vuot ngan sach thang nay" warning

**Rationale:** Addresses P2 (no velocity) and P3 (no temporal context). This is the most actionable metric for daily financial decisions. Answers "Can I afford this purchase today?"

**Data needed:**
- `dailyAverage: Decimal` -- totalExpense / daysElapsed
- `safeDailyLimit: Decimal` -- (budget or balance remaining) / daysRemaining
- `velocityStatus: VelocityStatus` -- enum: `.onTrack`, `.warning`, `.overPace`
- `velocityColor: Color`
- `formattedDailyAverage: String`, `formattedSafeDailyLimit: String`

### Section D: Category Breakdown (Streamlined)

**Current:** Full donut chart (160pt) + horizontal bar chart for top 5 categories.

**Proposed:** Compact horizontal bars only, top 3 categories (not 5). No donut chart.
- Section header: "Chi tieu theo danh muc"
- 3 horizontal bars with category icon, name, compact amount, percentage
- Tappable -- navigates to Insights for full breakdown

**Rationale:** Addresses P7 (chart too heavy). The donut is visually dominant and duplicates what Insights already shows better. Compact bars give the same information in 1/3 the space. Users who want deep analysis tap through to Insights.

**Data needed:** Same `topCategories` / `barItems` as today, but limit to 3 instead of 5. Remove `donutSlices`.

### Section E: Upcoming Recurring Transactions (New)

**What:** A compact list of the next 3 upcoming recurring transactions.

**Layout:**
- Header: "Sap toi" (Upcoming) with count badge
- Each row: category icon + note/name + formatted amount + "trong X ngay" (in X days)
- Only rendered if active recurring transactions exist
- "Quan ly giao dich dinh ky" link at bottom

**Rationale:** Addresses P6. Users need to anticipate upcoming expenses to manage cash flow. Especially important for rent (tien nha), utilities (dien nuoc), subscriptions.

**Data needed:**
- `@Query` for `RecurringTransaction` where `isActive == true` in the view
- `upcomingRecurring: [UpcomingItem]` -- struct with name, icon, colorHex, amount, daysUntilNext
- Logic to compute next occurrence date from `frequency` + `lastGeneratedDate` + `startDate`

### Section F: Recent Transactions (Fixed)

**Current:** Last 5 from all-time via `transactions.prefix(5)`.

**Proposed:** Last 5 from **current month only**.
- Header: "Gan day" (keep) -- context is now implicitly this month
- Keep existing `M3TransactionRow` layout in `M3Card`
- Add "Xem tat ca" link to Transaction tab if month has more than 5 transactions
- Empty state if no transactions this month

**Rationale:** Addresses P4 (global scoping). Month-scoping makes the section consistent with all other metrics on the page.

**Data needed:** Change `recentTransactions` computation in `loadData()` from `transactions.prefix(5)` to `monthTx.prefix(5)`.

### Section G: Insights Link (Unchanged)

**What:** Keep the "Xem bao cao chi tiet" `M3OutlinedCard` as the last section.

**Rationale:** Still needed as a bridge to detailed analytics. No changes needed.

### Design Decision: Quick Actions

After analysis, a dedicated quick-action strip is **not recommended** because:
- The app has a dedicated "Them" (Add) tab (tab index 2) always visible in the tab bar
- Adding inline quick-add would duplicate tab functionality and add glass element count
- If the team later decides to add a FAB, it must use `.glassEffect(.regular.tint(.green).interactive(), in: .circle)` per CLAUDE.md -- this is a design-level decision for UXUI to evaluate

### Removed Elements
- **Flow Row** -- income/expense metrics merged into Balance Hero
- **Donut Chart** -- removed from overview; belongs in Insights tab

---

## 5. Information Hierarchy

### Primary (Immediately Visible, No Scroll)
1. **Smart Balance Hero** -- answers "How much do I have?" + "How far through the month?"
   - Balance amount, spending ratio ring, income/expense inline, days remaining

### Secondary (One Thumb-Scroll)
2. **Budget Health Summary** -- answers "Am I within budget?"
   - Top 3 budget progress bars with color-coded health
3. **Spending Velocity Card** -- answers "Should I slow down?"
   - Safe daily amount vs actual daily average

### Tertiary (Further Scroll)
4. **Category Breakdown** (compact bars) -- answers "What am I spending on?"
5. **Upcoming Recurring** -- answers "What bills are coming?"
6. **Recent Transactions** (month-scoped) -- answers "What did I do recently?"
7. **Insights Link** -- escape hatch to full analytics

### Visual Flow
```
+-----------------------------------+
| BALANCE HERO (ring + amounts)     |  <- No scroll needed
| Income: X    Expense: Y          |
| Thang 3 - con 15 ngay            |
+-----------------------------------+
| BUDGET HEALTH                     |  <- One scroll
| [===75%===  ] An uong  2.5/3.5tr |
| [====90%====] Di chuyen 1.8/2tr  |
| [==40%==    ] Mua sam   800k/2tr |
+-----------------------------------+
| SPENDING VELOCITY                 |
| Chi duoc: 150k/ngay              |
| Dang chi: 180k/ngay (!)          |
+-----------------------------------+
| CATEGORY BARS (top 3, compact)    |  <- Further scroll
+-----------------------------------+
| UPCOMING (next 3 bills)           |
+-----------------------------------+
| RECENT TRANSACTIONS (this month)  |
+-----------------------------------+
| [ Xem bao cao chi tiet -> ]      |
+-----------------------------------+
```

---

## 6. Data Requirements for DashboardViewModel

### New Properties

```swift
// Temporal context
internal private(set) var daysElapsed: Int = 0
internal private(set) var daysInMonth: Int = 0
internal private(set) var daysRemaining: Int = 0
internal var temporalLabel: String { /* "Ngay X/Y -- con Z ngay" */ }

// Budget health
internal private(set) var budgetSummaries: [BudgetSummary] = []
internal private(set) var overallBudgetProgress: Double = 0
internal var overallBudgetColor: Color { /* green/orange/red */ }
internal var hasBudgets: Bool { !budgetSummaries.isEmpty }

// Spending velocity
internal private(set) var dailyAverage: Decimal = 0
internal private(set) var safeDailyLimit: Decimal = 0
internal private(set) var velocityStatus: VelocityStatus = .onTrack
internal var velocityColor: Color { /* based on status */ }
internal var formattedDailyAverage: String { dailyAverage.compactVND }
internal var formattedSafeDailyLimit: String { safeDailyLimit.compactVND }

// Upcoming recurring
internal private(set) var upcomingRecurring: [UpcomingItem] = []
internal var hasUpcoming: Bool { !upcomingRecurring.isEmpty }
```

### Modified Existing Properties
```swift
// recentTransactions: change from global prefix(5) to monthTx.prefix(5)
// topCategories: reduce from top 5 to top 3
```

### New Supporting Types

```swift
internal struct BudgetSummary: Identifiable, Sendable {
    internal let id: UUID
    internal let categoryName: String
    internal let categoryIcon: String
    internal let categoryColorHex: String
    internal let spent: Decimal
    internal let limit: Decimal
    internal let progress: Double      // spent/limit, capped at 1.0
    internal let progressColor: Color  // green/orange/red
    internal var formattedSpent: String { spent.compactVND }
    internal var formattedLimit: String { limit.compactVND }
}

internal enum VelocityStatus: Sendable {
    case onTrack   // dailyAvg < safeDailyLimit
    case warning   // dailyAvg within 20% of safeDailyLimit
    case overPace  // dailyAvg > safeDailyLimit
}

internal struct UpcomingItem: Identifiable, Sendable {
    internal let id: UUID
    internal let name: String
    internal let icon: String
    internal let colorHex: String
    internal let amount: Decimal
    internal let formattedAmount: String
    internal let daysUntilNext: Int
    internal let type: TransactionType
}
```

### New / Modified Methods

```swift
// Expanded signature -- accepts budget and recurring data
internal func loadData(
    transactions: [Transaction],
    budgets: [Budget],
    recurringTransactions: [RecurringTransaction]
)

// New private methods
private func computeTemporalContext()
private func buildBudgetSummaries(
    budgets: [Budget],
    monthTransactions: [Transaction]
) -> [BudgetSummary]
private func computeVelocity()
private func buildUpcomingItems(
    recurring: [RecurringTransaction]
) -> [UpcomingItem]
```

### View-Level Changes
- Add `@Query private var budgets: [Budget]` to DashboardView
- Add `@Query private var recurringTransactions: [RecurringTransaction]` (filtered to `isActive`)
- Pass all three data sets to `viewModel.loadData(transactions:budgets:recurringTransactions:)`
- Add `.onChange(of:)` handlers for budgets and recurring transactions
- New subview computed properties: `budgetHealthSection`, `velocityCard`, `upcomingSection`
- Remove `donutSection` from `chartCard`

---

## 7. CLAUDE.md Constraints Checklist

| Constraint | Impact on Renovation |
|-----------|---------------------|
| Max 300 lines per file | DashboardView is currently 230 lines. Adding 4 new sections will exceed 300. **Must extract subviews into separate files** |
| Max 30 lines per function | All new section computed properties must stay under 30 lines each |
| `@Observable` / `@MainActor` | Already compliant. New properties follow same pattern |
| Liquid Glass on chrome only | New sections are content -- NO `.glassEffect()`. If a FAB is added, it gets glass |
| No glass on cards/charts/content | `M3Card` is correct (surface color, no glass). Continue using it for new sections |
| Max 5 glass elements per screen | Currently 0 glass elements. Budget for toolbar + optional FAB only |
| VND formatting | Use existing `.formattedVND` and `.compactVND` extensions |
| Vietnamese primary locale | All new labels in Vietnamese. English fallback via String Catalogs |
| `let` over `var` | All new struct properties use `let` |
| `Sendable` for boundary types | All new structs marked `Sendable` |
| No force unwraps (`!`) | Guard-let pattern for optional budget/category access |
| `async/await` only | No async work needed -- all data is in-memory from `@Query` |
| Explicit access modifiers | Every type, property, and method gets explicit `internal` or `private` |

### File Split Recommendation

To stay under 300 lines per file, split DashboardView into:

| File | Contents | Est. Lines |
|------|----------|-----------|
| `DashboardView.swift` | Main ScrollView + body composition + balance hero | ~120 |
| `DashboardBudgetSection.swift` | Budget health summary section | ~80 |
| `DashboardVelocityCard.swift` | Spending velocity card | ~50 |
| `DashboardUpcomingSection.swift` | Upcoming recurring transactions | ~70 |
| `DashboardRecentSection.swift` | Recent transactions + category bars + empty state + insights link | ~90 |
| `DashboardViewModel.swift` | All ViewModel logic | ~200 |

If ViewModel exceeds 200 lines, extract budget and recurring computation into a lightweight service.

---

## 8. Out of Scope

- **Insights tab changes** -- the donut chart could be moved there but is a separate task
- **Widget updates** -- widget could benefit from velocity data but is not part of this renovation
- **Push notifications** -- budget alerts as notifications are a future feature
- **Historical comparison** -- month-over-month trends belong in Insights, not overview
- **Theming/color changes** -- use existing Color+Theme tokens as-is
- **Accessibility overhaul** -- basic labels should be added but a full audit is separate

---

## 9. Success Criteria

After renovation, the Overview tab should:

1. **Answer "Am I on track this month?" within 2 seconds of opening** -- balance + spending ring + budget bars visible without scrolling
2. **Show budget health without requiring a tab switch** -- top 3 budgets with progress bars on the overview
3. **Display spending pace relative to remaining days** -- safe daily amount vs actual daily average
4. **Surface upcoming bills for cash flow awareness** -- next 3 recurring transactions with countdown
5. **Keep all content month-scoped and consistent** -- recent transactions filtered to current month
6. **Stay within CLAUDE.md file size and architecture constraints** -- all files under 300 lines, all functions under 30 lines
7. **Load instantly** -- all data from in-memory `@Query`, no async fetching needed
8. **Reduce total scroll depth** -- merging flow row into hero + compact bars (no donut) should keep total content shorter despite adding new sections
