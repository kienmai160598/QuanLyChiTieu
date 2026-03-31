# Overview Tab — Design Specification

**Version:** 1.0
**Date:** 2026-03-16
**Author:** UXUI Agent
**Based on:** `rebuild/overview-renovation-brief.md` (BAUX)
**Status:** Ready for implementation (Tasks #3 and #4)

---

## 1. Screen Architecture

### 1.1 View Hierarchy

```
NavigationStack
 └─ DashboardView
     ├─ .navigationTitle("Tong quan")
     ├─ .appBackground()
     └─ ScrollView(.vertical, showsIndicators: false)
         └─ LazyVStack(spacing: Spacing.lg)            // 16pt between sections
              ├─ [1] DashboardBalanceHero               // new file
              ├─ [2] DashboardBudgetSection              // new file
              ├─ [3] DashboardDailyPaceCard              // inline (small)
              ├─ [4] DashboardCategoryBreakdown           // inline
              ├─ [5] DashboardUpcomingRecurring           // new file
              ├─ [6] recentSection                        // existing, updated
              └─ [7] insightsLink                         // existing, keep as-is
```

**Note:** Use `LazyVStack` instead of `VStack` for scroll performance. The stack sits inside `ScrollView(.vertical, showsIndicators: false)` with `.padding(.horizontal, Spacing.lg)`, `.padding(.top, Spacing.sm)`, `.padding(.bottom, Spacing.xxxl)`.

### 1.2 File Decomposition

| File | Estimated Lines | Content |
|------|----------------|---------|
| `DashboardView.swift` | ~120 | Main scroll + section composition, @Query, task{}, navigation |
| `DashboardBalanceHero.swift` | ~100 | Smart balance hero with spending ring |
| `DashboardBudgetSection.swift` | ~80 | Budget health cards + "Xem tat ca" link |
| `DashboardUpcomingRecurring.swift` | ~70 | Upcoming recurring rows |
| `DashboardViewModel.swift` | ~200 | All state, computed properties, data loading |

Sections 3 (Daily Pace), 4 (Category Breakdown), 6 (Recent), and 7 (Insights Link) stay inside `DashboardView.swift` as `private extension` computed properties because they are each under 30 lines.

---

## 2. Section-by-Section Specification

---

### Section 1: Smart Balance Hero

**File:** `DashboardBalanceHero.swift`
**Priority:** PRIMARY — always visible first on screen

#### Layout

```
M3Card(cornerRadius: Spacing.cornerExtraLarge)
 └─ VStack(spacing: Spacing.md)                 // 12pt
      ├─ HStack                                  // month + days remaining
      │    ├─ Text(monthName.uppercased())        // "THANG 3"
      │    ├─ Spacer()
      │    └─ Text("con X ngay")                  // "con 15 ngay"
      │
      ├─ ZStack                                   // balance + spending ring
      │    ├─ SpendingRatioRing(progress:)        // circular progress
      │    └─ VStack(spacing: 2)
      │         ├─ Text(formattedBalance)          // "4.300.000 d"
      │         └─ Text("So du thang nay")         // subtitle
      │
      └─ HStack(spacing: Spacing.lg)              // income / expense inline
           ├─ HStack(spacing: Spacing.sm)
           │    ├─ Image(systemName: "arrow.down.left")
           │    └─ Text(compactIncome)             // "+12,5tr"
           ├─ Divider().frame(height: 16)
           └─ HStack(spacing: Spacing.sm)
                ├─ Image(systemName: "arrow.up.right")
                └─ Text(compactExpense)            // "-8,2tr"
```

#### Visual Tokens

| Element | Typography | Color | Notes |
|---------|-----------|-------|-------|
| Month name | `Typography.labelMedium` | `Color.onSurfaceVariant` | `.tracking(1.2)`, `.uppercased()` |
| Days remaining | `Typography.labelSmall` | `Color.onSurfaceVariant` | "con X ngay" |
| Balance amount | `Typography.displaySmall` | Dynamic (see below) | `.minimumScaleFactor(0.4)`, `.lineLimit(1)`, `.contentTransition(.numericText())` |
| Balance subtitle | `Typography.bodySmall` | `Color.onSurfaceVariant` | "So du thang nay" |
| Income value | `Typography.titleSmall` | `Color.appPrimary` | Compact VND |
| Expense value | `Typography.titleSmall` | `Color.appError` | Compact VND |
| Income/Expense icons | `.font(.caption.weight(.medium))` | Same as respective value | SF Symbol, 12pt |

#### SpendingRatioRing (New Component — inline in file)

A simple circular progress ring drawn with `Circle().trim()`:

```
ZStack {
    // Track
    Circle()
        .stroke(Color.outlineVariant.opacity(0.3), lineWidth: 6)
    // Progress
    Circle()
        .trim(from: 0, to: spendingRatio)
        .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
        .rotationEffect(.degrees(-90))
        .animation(.easeOut(duration: 0.6), value: spendingRatio)
}
.frame(width: 140, height: 140)
```

**Ring color logic (ViewModel computed property `ringColor`):**
- `spendingRatio < 0.6` -> `Color.appPrimary` (healthy)
- `spendingRatio >= 0.6 && < 0.85` -> `Color.categoryBills` (#F59F00, warning yellow)
- `spendingRatio >= 0.85` -> `Color.appError` (danger)

**Balance color** uses the same logic as `ringColor`.

#### Spacing

- Card internal padding: `.padding(.vertical, Spacing.xl)` `.padding(.horizontal, Spacing.lg)`
- Ring frame: 140x140pt
- Balance text inside ring is centered via ZStack alignment

#### Glass Treatment

**None.** This is a content card (M3Card). No `.glassEffect()`.

---

### Section 2: Budget Health Summary

**File:** `DashboardBudgetSection.swift`
**Priority:** SECONDARY
**Visibility:** Only shown when `viewModel.hasBudgets == true`

#### Layout

```
VStack(alignment: .leading, spacing: Spacing.md)    // 12pt
 ├─ M3SectionHeader("Ngan sach", trailing: monthName)
 │
 ├─ M3Card
 │    └─ VStack(spacing: 0)
 │         ├─ BudgetRow(summary: budgetSummaries[0])
 │         ├─ M3CardDivider(leadingInset: 56)
 │         ├─ BudgetRow(summary: budgetSummaries[1])
 │         ├─ M3CardDivider(leadingInset: 56)
 │         └─ BudgetRow(summary: budgetSummaries[2])
 │
 └─ NavigationLink(value: DashboardRoute.budgetList)
      └─ M3OutlinedCard { ... "Xem tat ca ngan sach" ... }
```

#### BudgetRow (private struct inside file)

```
HStack(spacing: Spacing.md)                          // 12pt
 ├─ M3IconBadge(icon:, color:, size: 36)
 ├─ VStack(alignment: .leading, spacing: Spacing.xs)  // 4pt
 │    ├─ HStack
 │    │    ├─ Text(categoryName)                       // "An uong"
 │    │    ├─ Spacer()
 │    │    └─ Text("X / Y")                            // "2,1tr / 3tr"
 │    └─ M3ProgressBar(progress: ratio, tint: barColor)
 └─ (no trailing — progress bar fills width)
```

| Element | Typography | Color |
|---------|-----------|-------|
| Category name | `Typography.bodyMedium` | `Color.onSurface` |
| Spent / Limit | `Typography.labelSmall` | `Color.onSurfaceVariant` |
| Progress bar | height: 6 | Dynamic tint (see below) |
| Icon badge | size: 36 | `Color(hex: colorHex)` |

**Progress bar color logic (computed per BudgetSummary):**
- `ratio < 0.7` -> `Color.appPrimary`
- `ratio >= 0.7 && < 0.9` -> `Color.categoryBills` (warning)
- `ratio >= 0.9` -> `Color.appError`

#### Row sizing

- Each BudgetRow: `.padding(.horizontal, Spacing.lg)`, `.frame(minHeight: 60)`
- Max 3 budgets shown. If fewer than 3, show whatever exists.

#### Glass Treatment

**None.** Content cards. No `.glassEffect()`.

---

### Section 3: Daily Pace Card

**File:** Inline in `DashboardView.swift` (private extension)
**Priority:** SECONDARY
**Visibility:** Always shown when there are transactions this month

#### Layout

```
M3Card
 └─ HStack(spacing: Spacing.md)                    // 12pt
      ├─ M3IconBadge(
      │      icon: "gauge.with.needle",
      │      color: paceColor,
      │      size: 40
      │  )
      ├─ VStack(alignment: .leading, spacing: 2)
      │    ├─ Text("Hom nay ban co the chi")        // label
      │    └─ Text(formattedSafeDailyAmount)         // "286.000 d"
      └─ Spacer()
```

**Override when over budget:**
Replace the entire card content with:
```
HStack
 ├─ M3IconBadge(icon: "exclamationmark.triangle", color: .appError)
 ├─ VStack
 │    ├─ Text("Da vuot ngan sach thang nay")
 │    └─ Text(formattedOverAmount)                   // "Vuot 1.200.000 d"
```

| Element | Typography | Color |
|---------|-----------|-------|
| Label | `Typography.bodySmall` | `Color.onSurfaceVariant` |
| Daily amount | `Typography.titleMedium` | `Color.appPrimary` (or `Color.appError` if over budget) |
| Over-budget label | `Typography.bodySmall` | `Color.appError` |
| Over-budget amount | `Typography.titleSmall` | `Color.appError` |

#### Spacing

- Card internal: `.padding(Spacing.lg)` all sides
- Minimum height: 56pt via `.frame(minHeight: 56)`

#### Glass Treatment

**None.** Content card.

---

### Section 4: Category Breakdown (Compact)

**File:** Inline in `DashboardView.swift` (private extension)
**Priority:** TERTIARY
**Visibility:** Only when `viewModel.topCategories` is not empty

#### Layout

```
VStack(alignment: .leading, spacing: Spacing.md)     // 12pt
 ├─ M3SectionHeader(
 │      "Chi tieu theo danh muc",
 │      trailing: formattedExpense
 │  )
 └─ M3Card
      └─ VStack(spacing: Spacing.lg)                  // 16pt
           └─ HorizontalBarChart(items: barItems)      // existing component
      .padding(Spacing.lg)
```

**Changes from current:**
- **Remove DonutChartWithLabels** entirely (too heavy, duplicates Insights)
- **Reduce to top 3** categories (from 5)
- Wrap in NavigationLink to Insights for tap-to-expand
- Keep existing `HorizontalBarChart` component unchanged

#### Tap Action

The entire M3Card is wrapped in a `NavigationLink` to `InsightsView()`:
```swift
NavigationLink {
    InsightsView()
} label: {
    M3Card { ... }
}
.buttonStyle(.plain)
```

#### Glass Treatment

**None.** Content card.

---

### Section 5: Upcoming Recurring

**File:** `DashboardUpcomingRecurring.swift`
**Priority:** TERTIARY
**Visibility:** Only when `viewModel.upcomingRecurring` is not empty

#### Layout

```
VStack(alignment: .leading, spacing: Spacing.md)      // 12pt
 ├─ M3SectionHeader("Sap toi")
 │
 ├─ M3Card
 │    └─ VStack(spacing: 0)
 │         ├─ RecurringRow(item: upcoming[0])
 │         ├─ M3CardDivider()
 │         ├─ RecurringRow(item: upcoming[1])
 │         ├─ M3CardDivider()
 │         └─ RecurringRow(item: upcoming[2])
 │
 └─ NavigationLink { RecurringTransactionView() }
      label: { linkCard("Quan ly giao dich dinh ky") }
```

#### RecurringRow (private struct inside file)

Reuse the same visual pattern as `M3TransactionRow`:

```
HStack(spacing: Spacing.lg)                           // 16pt
 ├─ M3IconBadge(icon:, color:, size: 40)
 ├─ VStack(alignment: .leading, spacing: 2)
 │    ├─ Text(note)                                    // "Netflix"
 │    └─ Text(nextDate.relativeVietnamese)             // "18 Thang 3"
 ├─ Spacer(minLength: Spacing.xs)
 └─ Text(formattedAmount)                              // "-149.000 d"
```

| Element | Typography | Color |
|---------|-----------|-------|
| Note | `Typography.bodyLarge` | `Color.onSurface` |
| Next date | `Typography.bodySmall` | `Color.onSurfaceVariant` |
| Amount | `Typography.titleSmall` | `Color.appError` (expense) or `Color.appPrimary` (income) |

#### Row sizing

- `.padding(.horizontal, Spacing.lg)`, `.frame(minHeight: 56)`
- Max 3 items. Sorted by next occurrence date ascending.

#### Glass Treatment

**None.** Content card.

---

### Section 6: Recent Transactions (Updated)

**File:** Inline in `DashboardView.swift` (existing, updated)
**Priority:** SECONDARY

#### Changes from Current

1. **Month-scoped:** `recentTransactions` now filtered to current month only (ViewModel change)
2. **"Xem tat ca" link** added at bottom, navigating to TransactionListView
3. **Empty state** updated: show `EmptyStateView` with action to add transaction

#### Layout (unchanged structure)

```
VStack(alignment: .leading, spacing: Spacing.md)
 ├─ M3SectionHeader("Gan day", trailing: "Thang nay")
 │
 ├─ if recentTransactions.isEmpty:
 │    EmptyStateView(
 │        icon: "tray",
 │        title: "Chua co giao dich",
 │        subtitle: "Them giao dich dau tien cua thang nay",
 │        actionTitle: "Them giao dich"
 │    ) { showAddTransaction = true }
 │
 └─ else:
      M3Card
       └─ VStack(spacing: 0)
            └─ ForEach(recentTransactions) { M3TransactionRow }
                 separated by M3CardDivider()
```

Existing components reused: `M3TransactionRow`, `M3CardDivider`, `M3SectionHeader`, `M3Card`.

#### Glass Treatment

**None.** Content.

---

### Section 7: Insights Link (Unchanged)

Keep the existing `insightsLink` implementation as-is. The `M3OutlinedCard` with NavigationLink to `InsightsView()`. No modifications needed.

---

## 3. Liquid Glass Plan

### Glass Budget: 3 elements (well under the 5-element maximum)

| # | Element | Glass Modifier | Location |
|---|---------|---------------|----------|
| 1 | **Navigation bar** | System default `.glassEffect(.regular)` | Top chrome, applied by NavigationStack |
| 2 | **Tab bar** | System default `.glassEffect(.regular)` | Bottom chrome, applied by TabView |
| 3 | **FAB ("+" add transaction)** | `.glassEffect(.regular.tint(.appPrimary).interactive(), in: .circle)` | Bottom-trailing overlay via `.glassFABOverlay()` |

**Simultaneously visible:** Max 3 (nav bar + tab bar + FAB) — meets the "max 3 simultaneously visible" constraint.

### What does NOT get glass

- M3Card (content) — uses `Color.surfaceContainerLow` background
- M3OutlinedCard (content) — uses `Color.appSurface` + outline
- Balance Hero (content) — surface card
- Progress bars, charts, transaction rows — all content layer
- Section headers — plain text

### FAB Placement

The FAB is applied at the DashboardView level using the existing `.glassFABOverlay()` modifier:
```swift
ScrollView { ... }
    .glassFABOverlay {
        showAddTransaction = true
    }
```

This triggers a `.sheet()` presentation with `AddTransactionView`.

---

## 4. Animations & Transitions

### 4.1 Number Animations

All monetary values use `.contentTransition(.numericText())` for smooth digit changes when data reloads:

```swift
Text(viewModel.formattedBalance)
    .contentTransition(.numericText())
```

Applied to: balance, income, expense, safe daily amount, budget spent/limit values.

### 4.2 Spending Ratio Ring

```swift
Circle()
    .trim(from: 0, to: spendingRatio)
    .animation(.easeOut(duration: 0.6), value: spendingRatio)
```

### 4.3 Progress Bars

Already animated in `M3ProgressBar`:
```swift
.animation(.easeOut(duration: 0.4), value: progress)
```

### 4.4 Section Appearance

Sections fade in as data loads. Use `.transition(.opacity)` combined with `withAnimation` on the data change:

```swift
if viewModel.hasBudgets {
    DashboardBudgetSection(viewModel: viewModel)
        .transition(.opacity)
}
```

### 4.5 Reduce Motion

All animations respect `@Environment(\.accessibilityReduceMotion)`:
- When `reduceMotion == true`: skip ring animation, use `.animation(.none)`
- The `M3ProgressBar` and `HorizontalBarChart` already do not check this — consider adding in a future pass, but not blocking for this release

### 4.6 Haptic Feedback

- FAB press: `UIImpactFeedbackGenerator(style: .medium)` — already in GlassFAB
- NavigationLink taps: no haptic (system default)

---

## 5. State Management

### 5.1 View States

```swift
internal enum DashboardState: Sendable {
    case loading
    case populated
    case empty
    case error(any Error)
}
```

**Note:** Keep this simple. The dashboard always has *something* to show (even if individual sections are empty). The `error` state is for catastrophic failures (SwiftData unavailable). In practice, `loading` is shown briefly on first appear, then `populated` or `empty`.

### 5.2 Loading State

Shown on first `task {}` before data is available:

```
ScrollView
 └─ VStack
      ├─ M3Card (placeholder balance hero, redacted)
      ├─ M3Card (placeholder budget row, redacted)
      └─ M3Card (placeholder transactions, redacted)
```

Use SwiftUI's `.redacted(reason: .placeholder)` on the entire ScrollView content:

```swift
ScrollView {
    content
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
}
```

### 5.3 Empty State (No Transactions This Month)

When the user has zero transactions for the current month, show:
- **Balance Hero:** Shows `0 d` balance, empty ring (0% progress)
- **Budget Section:** Hidden (no budgets or no spending)
- **Daily Pace:** Hidden (no income to compute from)
- **Category Breakdown:** Hidden (no expenses)
- **Upcoming Recurring:** Still shown if recurring transactions exist
- **Recent Transactions:** Shows `EmptyStateView` with "Them giao dich" action
- **Insights Link:** Still shown

### 5.4 Error State

If SwiftData query fails or ViewModel encounters an error:

```swift
RetryView(error: error) {
    Task { viewModel.loadData(transactions: allTransactions, budgets: allBudgets, recurring: allRecurring) }
}
```

Full-screen replacement of the scroll content.

---

## 6. Data Flow

### 6.1 @Query Declarations (in DashboardView)

```swift
@Query(sort: \Transaction.date, order: .reverse)
private var allTransactions: [Transaction]

@Query
private var allBudgets: [Budget]

@Query(filter: #Predicate<RecurringTransaction> { $0.isActive == true })
private var activeRecurring: [RecurringTransaction]
```

### 6.2 ViewModel Loading

```swift
.task {
    viewModel.loadData(
        transactions: allTransactions,
        budgets: allBudgets,
        recurring: activeRecurring
    )
}
.onChange(of: allTransactions) {
    viewModel.loadData(
        transactions: allTransactions,
        budgets: allBudgets,
        recurring: activeRecurring
    )
}
.onChange(of: allBudgets) {
    viewModel.loadData(
        transactions: allTransactions,
        budgets: allBudgets,
        recurring: activeRecurring
    )
}
```

### 6.3 New ViewModel Properties

```swift
// Budget health
internal private(set) var budgetSummaries: [BudgetSummary] = []
internal var hasBudgets: Bool { !budgetSummaries.isEmpty }

// Daily pace
internal private(set) var daysRemainingInMonth: Int = 0
internal private(set) var safeDailyAmount: Decimal = 0
internal var formattedSafeDailyAmount: String { safeDailyAmount.formattedVND }
internal var isOverBudget: Bool { totalBalance < 0 }
internal var formattedOverAmount: String { "Vuot \(abs(totalBalance).formattedVND)" }

// Spending ring
internal var ringColor: Color {
    if spendingRatio < 0.6 { return Color.appPrimary }
    if spendingRatio < 0.85 { return Color.categoryBills }
    return Color.appError
}

// Upcoming recurring
internal private(set) var upcomingRecurring: [UpcomingRecurring] = []

// Existing — modified
internal private(set) var topCategories: [CategorySpend] = []   // top 3 (was 5)
internal private(set) var recentTransactions: [Transaction] = [] // month-scoped (was all-time)
```

---

## 7. Navigation

### 7.1 Routes (AppRoutes.swift update)

Add new routes to `DashboardRoute`:

```swift
internal enum DashboardRoute: Hashable {
    case transactionDetail(PersistentIdentifier)   // existing
    case budgetDetail(PersistentIdentifier)         // existing
    case budgetList                                  // NEW
    case recurringList                               // NEW
}
```

### 7.2 Sheet Presentation

```swift
@State private var showAddTransaction = false

// On DashboardView body
.sheet(isPresented: $showAddTransaction) {
    AddTransactionView()
}
```

Triggered by FAB.

---

## 8. Dark Mode

All colors are already adaptive via `Color+Theme.swift` using `Color(light:dark:)`. No manual overrides needed.

### Per-Section Dark Mode Behavior

| Section | Light | Dark | Notes |
|---------|-------|------|-------|
| Balance Hero | `surfaceContainerLow` bg | `surfaceContainerLow` bg | Auto via M3Card |
| Spending Ring track | `outlineVariant` @ 0.3 | `outlineVariant` @ 0.3 | Adaptive |
| Spending Ring fill | `appPrimary`/`categoryBills`/`appError` | Same tokens, adaptive | Automatic |
| Budget rows | `surfaceContainerLow` bg | `surfaceContainerLow` bg | Auto via M3Card |
| Progress bars | `outlineVariant` track, colored fill | Same | Auto via M3ProgressBar |
| Daily Pace | `surfaceContainerLow` bg | `surfaceContainerLow` bg | Auto |
| Category bars | Colored bars on `outlineVariant` track | Same, adaptive | Auto via HorizontalBarChart |
| Recurring rows | `surfaceContainerLow` bg | `surfaceContainerLow` bg | Auto |
| Transaction rows | `surfaceContainerLow` bg | `surfaceContainerLow` bg | Auto |
| Section headers | `onSurface` / `onSurfaceVariant` text | Adaptive | Auto |
| FAB | Glass auto-adapts | Glass auto-adapts | Per CLAUDE.md: never override glass dark mode |
| App background | Gradient with `appSurface` + `primaryContainer` hint | Adaptive | Auto via AppBackground |

**Rule:** Do NOT manually override any glass appearance for dark mode. Liquid Glass self-adapts.

---

## 9. Accessibility

### 9.1 VoiceOver Labels

| Element | accessibilityLabel | accessibilityValue |
|---------|-------------------|-------------------|
| Balance Hero card | "So du thang nay" | "{formattedBalance}" |
| Spending ring | "Ti le chi tieu" | "{spendingRatio * 100} phan tram" |
| Income pill | "Thu nhap thang nay" | "{formattedIncome}" |
| Expense pill | "Chi tieu thang nay" | "{formattedExpense}" |
| Budget row | "{categoryName} ngan sach" | "{spent.compactVND} tren {limit.compactVND}, {ratio}%" |
| Daily pace card | "Muc chi tieu an toan hom nay" | "{formattedSafeDailyAmount}" |
| Over-budget card | "Canh bao vuot ngan sach" | "{formattedOverAmount}" |
| Category bar | "{categoryName}" | "{percentage} phan tram chi tieu" |
| Recurring row | "{note}, {frequency.displayName}" | "{formattedAmount}, ngay {nextDate.shortVietnamese}" |
| Transaction row | Already has accessible content via M3TransactionRow | — |
| FAB | "Them giao dich" (already in GlassFAB) | — |

### 9.2 Accessibility Grouping

Group related elements so VoiceOver reads them as a unit:

```swift
// Balance Hero
VStack { ... }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("So du thang \(monthName)")
    .accessibilityValue(formattedBalance)

// Each Budget Row
HStack { ... }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(categoryName) ngan sach")
    .accessibilityValue("\(spent.compactVND) tren \(limit.compactVND)")
```

### 9.3 Dynamic Type

- All text uses `Typography.*` which maps to `Font.system(size:weight:)` — supports Dynamic Type automatically
- Balance uses `.minimumScaleFactor(0.4)` to prevent overflow at largest type sizes
- Compact VND values use `.lineLimit(1)` + `.minimumScaleFactor(0.6)` (already on M3MetricPill)
- Ring size is fixed at 140pt — does not scale with Dynamic Type (decorative, not informational)

### 9.4 Reduce Motion

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
```

When `true`:
- Ring animation: `.animation(.none)`
- Number content transitions: disabled
- Section transitions: instant (no `.opacity` fade)

---

## 10. New Components to Create

### 10.1 SpendingRatioRing

**Location:** Inside `DashboardBalanceHero.swift` (private struct, not shared)

```swift
private struct SpendingRatioRing: View {
    let progress: Double    // 0.0 to 1.0
    let ringColor: Color
    let size: CGFloat = 140
    let lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.outlineVariant.opacity(0.3), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
```

### 10.2 BudgetRow

**Location:** Inside `DashboardBudgetSection.swift` (private struct, not shared)

Uses existing `M3IconBadge` and `M3ProgressBar`. No new shared components needed.

### 10.3 RecurringRow

**Location:** Inside `DashboardUpcomingRecurring.swift` (private struct, not shared)

Follows the same visual pattern as `M3TransactionRow` but with next-date instead of transaction date.

---

## 11. Existing Components Reused

| Component | Used In |
|-----------|---------|
| `M3Card` | Sections 1, 2, 3, 4, 5, 6 |
| `M3OutlinedCard` | Section 2 link, Section 7 |
| `M3SectionHeader` | Sections 2, 4, 5, 6 |
| `M3IconBadge` | Sections 2, 3, 5, 7 |
| `M3TransactionRow` | Section 6 |
| `M3MetricPill` | NOT used (replaced by inline income/expense in hero) |
| `M3ProgressBar` | Section 2 |
| `M3CardDivider` | Sections 2, 5, 6 |
| `HorizontalBarChart` | Section 4 |
| `DonutChart` | NOT used (removed) |
| `DonutChartWithLabels` | NOT used (removed) |
| `GlassFAB` / `.glassFABOverlay()` | FAB overlay |
| `EmptyStateView` | Section 6 empty state |
| `RetryView` | Error state |
| `AppBackground` / `.appBackground()` | View background |

---

## 12. ViewModel New Structs

### BudgetSummary

```swift
internal struct BudgetSummary: Identifiable, Sendable {
    internal let id: UUID
    internal let categoryName: String
    internal let categoryIcon: String
    internal let categoryColorHex: String
    internal let spent: Decimal
    internal let limit: Decimal
    internal var ratio: Double { // spent / limit, capped
        guard limit > 0 else { return 0 }
        return min(NSDecimalNumber(decimal: spent / limit).doubleValue, 1.0)
    }
    internal var barColor: Color {
        if ratio < 0.7 { return Color.appPrimary }
        if ratio < 0.9 { return Color.categoryBills }
        return Color.appError
    }
}
```

### UpcomingRecurring

```swift
internal struct UpcomingRecurring: Identifiable, Sendable {
    internal let id: UUID
    internal let note: String
    internal let amount: Decimal
    internal let formattedAmount: String
    internal let nextDate: Date
    internal let formattedNextDate: String
    internal let icon: String
    internal let colorHex: String
    internal let isExpense: Bool
}
```

---

## 13. Scroll Behavior & Performance

- Use `LazyVStack` for the main content stack (sections load as they scroll into view)
- `ScrollView(.vertical, showsIndicators: false)` — hide scroll indicator for clean UI
- No `List` — not needed since there are no swipe actions on the dashboard
- `@Query` results are reactive; ViewModel recomputes on change via `.onChange(of:)`
- Top 3 budget/category limits keep computation lightweight
- `recentTransactions` limited to 5 items via `.prefix(5)`

---

## 14. Summary of Changes from Current

| Aspect | Current | Renovated |
|--------|---------|-----------|
| Balance Hero | Month + balance + subtitle | Month + days remaining + balance inside ring + income/expense inline |
| Flow Row | Separate HStack with 2 M3Cards | Merged into Balance Hero |
| Chart Section | Donut + Horizontal bars (top 5) | Horizontal bars only (top 3), tappable to Insights |
| Budget | Not shown | Top 3 budgets with progress bars |
| Daily Pace | Not shown | Safe daily spend card |
| Upcoming Recurring | Not shown | Next 3 upcoming bills |
| Recent Transactions | Last 5 all-time | Last 5 current month |
| Insights Link | Static outlined card | Unchanged |
| Glass elements | 0 on dashboard chrome | 3 (nav bar, tab bar, FAB) |
| Accessibility | None | Full VoiceOver labels, grouping, Dynamic Type |
| States | Only empty transactions | Loading (redacted), empty, error, populated |
| File count | 2 files | 5 files (DashboardView, BalanceHero, BudgetSection, UpcomingRecurring, ViewModel) |
