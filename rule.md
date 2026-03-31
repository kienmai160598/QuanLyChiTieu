# Rule — Quản Lý Chi Tiêu (Swift / iOS)

> **This file contains Swift/SwiftUI production code rules ONLY.**
> For HTML/CSS design mockup rules, see `design-system.md`.
> For critical rules that Claude Code loads automatically, see `CLAUDE.md`.

## Platform

- **iOS 26+** exclusively. No Android. No cross-platform.
- **Swift 6.2** (Xcode 26 toolchain).
- **SwiftUI first.** Use UIKit only for: (1) camera/photo picker if `PhotosPicker` is insufficient, (2) `WKWebView` for in-app web content, (3) MapKit when `Map` view lacks a needed feature. Document every UIKit usage with `// UIKit: <reason>`.
- **M3 Expressive** is the primary visual language. Use `.m3Card()` for content surfaces, solid `Color` backgrounds for buttons/chips, and `M3Elevation` shadows. Never use `.glassEffect()` or `GlassEffectContainer`.

---

## 1. Architecture

- **MVVM** with SwiftUI. Each screen has its own `ViewModel` as an `@Observable` class.
- **One ViewModel per screen.** Place shared state in a dedicated service or manager, injected via `@Environment`.
- **Unidirectional data flow.** Views read state from ViewModels. User actions call ViewModel methods. ViewModels never hold references to Views. Views never mutate ViewModel state directly.
- If a ViewModel exceeds **200 lines**, extract logic into focused services.
- If a View `body` exceeds **40 lines**, extract subviews as separate structs or computed properties.

---

## 2. Navigation

- Use **`NavigationStack`** with a centralized `NavigationPath` for programmatic navigation.
- Use **tab-based navigation** with `TabView`. Each tab owns its own `NavigationStack`.
- Use **`navigationDestination(for:)`** for type-safe routing. Define a `Route` enum per feature module.
- Use **`.sheet()`** / **`.fullScreenCover()`** for modal presentations. Coordinate via ViewModel boolean state.
- Support **deep linking** via `.onOpenURL {}` on the root view. Parse URLs into `Route` values and push to the appropriate `NavigationPath`.
- Support **state restoration** by persisting `NavigationPath` to `@AppStorage` where appropriate.

```swift
// Route enum pattern
enum HomeRoute: Hashable {
    case transactionDetail(Transaction.ID)
    case budgetDetail(Budget.ID)
    case addExpense
}

// In the tab's NavigationStack
NavigationStack(path: $navigationPath) {
    HomeView()
        .navigationDestination(for: HomeRoute.self) { route in
            switch route {
            case .transactionDetail(let id): TransactionDetailView(id: id)
            case .budgetDetail(let id): BudgetDetailView(id: id)
            case .addExpense: AddExpenseView()
            }
        }
}
```

---

## 3. Project Structure

```
QuanLyChiTieu/
├── App/
│   ├── QuanLyChiTieuApp.swift        # @main entry point
│   └── AppDelegate.swift              # Push notifications only
├── Core/
│   ├── Models/                        # @Model classes, DTOs, enums
│   ├── Services/                      # Business logic, networking, persistence
│   ├── Extensions/                    # Date+Formatting, String+, Color+Theme
│   ├── Utilities/                     # Formatters, Validators, Keychain wrapper
│   └── Theme/                         # Color tokens, Typography, Spacing constants
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   ├── OnboardingViewModel.swift
│   │   ├── Components/
│   │   └── FEATURE.md                 # Feature documentation
│   ├── Home/
│   ├── Transactions/
│   ├── Budget/
│   ├── Insights/
│   ├── Settings/
│   └── Widget/                        # WidgetKit extension
├── SharedUI/
│   ├── GlassFAB.swift                 # FAB with M3E solid fill + elevation
│   ├── GlassToolbar.swift             # Toolbar HStack container
│   ├── GlassChipGroup.swift           # Filter chips with M3E filled/outlined
│   ├── EmptyStateView.swift           # Reusable empty state
│   ├── RetryView.swift                # Error + retry button
│   ├── ChartViews/
│   └── Modifiers/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings          # String Catalogs
│   └── Fonts/
└── Tests/
    ├── UnitTests/
    ├── SnapshotTests/
    └── UITests/
```

### Feature Documentation Rule

Every feature folder **must** contain a `FEATURE.md` file that documents:
1. **Purpose** — What the feature does and why it exists.
2. **Screens** — List of views with brief description of each.
3. **Data model** — Which `@Model` entities and relationships it uses.
4. **User flows** — Step-by-step paths (e.g., "User taps Add → fills form → saves → list refreshes").
5. **Edge cases** — Empty states, error states, offline behavior.
6. **Surface treatment** — Which elements use M3E cards/elevation and which colors.
7. **Localization keys** — Key string identifiers used in this feature.

This documentation serves both the developer and Claude Code for context when modifying the feature.

---

## 4. SwiftUI Rules

- Always use native SwiftUI components: `NavigationStack`, `TabView`, `Sheet`, Swift Charts, `ScrollView`.
- Use `.m3Card()` for content surfaces with `M3Elevation` shadows. Use `.background(color, in: shape)` for buttons. Use `ExpressivePressStyle()` for interactive press feedback.
- **State management hierarchy:**
  - `@State` — view-local, value-type state (keep granular — one property per piece of state, not a large struct)
  - `@Binding` — pass mutable state to child views
  - `@Environment` — dependency injection (services, theme, locale)
  - `@Observable` — ViewModels and shared state objects
- Never put logic in `body`. Formatting, computation, and decisions belong in the ViewModel or as computed properties. `body` is purely declarative.
- Use `task {}` and `task(id:) {}` for async work on appear. Never use `onAppear` with `Task {}`.
- Use `LazyVStack` / `LazyHStack` inside `ScrollView` for scrollable content. Use `List` only when you need swipe actions or edit mode.
- Apply `.m3Card()` **last** in the modifier chain (after `.padding()`, `.frame()`).

### Nested Corner Radius Rule

To ensure perfectly aligned rounded corners in nested UI elements, use the formula:

```
Outer Radius = Inner Radius + Padding
```

```swift
// Example: inner card inside an outer card
private let innerRadius: CGFloat = Spacing.cornerMedium   // e.g. 12
private let cardPadding: CGFloat = Spacing.xl              // e.g. 20
private let outerRadius: CGFloat = innerRadius + cardPadding // 32

// Inner element
TextField("Name", text: $name)
    .padding(innerRadius)
    .clipShape(RoundedRectangle(cornerRadius: innerRadius))

// Outer container
VStack { ... }
    .padding(cardPadding)
    .clipShape(RoundedRectangle(cornerRadius: outerRadius))
```

This prevents the visual artifact where inner corners appear "pinched" or misaligned with the outer container's corners.

### DO / DON'T: Body Logic

```swift
// DON'T — logic in body
var body: some View {
    let formatted = transaction.amount > 0 ? "+\(transaction.amount)" : "\(transaction.amount)"
    Text(formatted)
        .foregroundStyle(transaction.amount > 0 ? .green : .red)
}

// DO — logic in ViewModel or computed property
var body: some View {
    Text(viewModel.formattedAmount)
        .foregroundStyle(viewModel.amountColor)
}
```

---

## 5. Swift Language Rules

- **Value types by default.** Use `struct` for models and data. Use `class` only for ViewModels (`@Observable`), services, or UIKit interop.
- **`let` over `var`.** Immutable by default.
- **No `Any` / `AnyObject`** unless interfacing with Objective-C. Use generics and protocols.
- **Enums for fixed sets.** Categories, transaction types, screen states — all enums with associated values.
- **Guard early, return early.** Use `guard let` / `guard else`. Avoid deep nesting.
- **No force unwraps (`!`)** in production code. Use `guard let`, `if let`, or `??`.
- **No force try (`try!`)** in production code. Use `do-catch` or propagate with `throws`.
- **No `NSObject` inheritance** unless required by a framework API.
- **`async/await` only.** No completion handlers for new code. No Combine for new code — use `AsyncStream` or `Observations` async sequence instead. If a third-party SDK only offers completion handlers, wrap them in `withCheckedContinuation`.
- **Explicit access control.** Every type and method must have an explicit access modifier (`private`, `internal`, `public`). Never rely on Swift's default `internal`.

---

## 6. Swift 6.2 Concurrency

- **`@MainActor`** on all ViewModels. All UI state mutations on the main thread.
- The project uses **`defaultIsolation = MainActor`** (Xcode 26 default). All code runs on MainActor unless explicitly opted out.
- Use **`@concurrent`** to explicitly opt a function out of MainActor and run on the cooperative thread pool (e.g., heavy computation, data processing).
- **`nonisolated(nonsending)`** is the new default for nonisolated sync functions — they inherit the caller's isolation. Understand this when reading compiler diagnostics.
- **`Sendable` conformance** is required for all types crossing isolation boundaries. Mark value types as `Sendable`. Use `@unchecked Sendable` only with a `// Safety: <reason>` comment.
- Use **`Task {}`** only for fire-and-forget side effects (analytics, logging) or launching work from a synchronous context. Store the `Task` handle when cancellation is needed.
- Use **`async let`** or **`TaskGroup`** when coordinating 2+ concurrent operations.
- Use **`actor`** for thread-safe mutable shared state (caches, token managers).
- **Cancel tasks** when views disappear. The `task {}` modifier handles this automatically.
- Use `@Observable` with **`Observations`** (SE-0475) for streaming state changes as `AsyncSequence` in service layers.

```swift
// ViewModel pattern
@MainActor @Observable
final class BudgetViewModel {
    var budgets: [Budget] = []
    var isLoading = false

    private let service: BudgetService

    init(service: BudgetService) { self.service = service }

    func loadBudgets() async {
        isLoading = true
        defer { isLoading = false }
        do {
            budgets = try await service.fetchAll()
        } catch {
            // handle error
        }
    }
}

// Background work — opt out of MainActor
@concurrent
func processCSVExport(transactions: [Transaction]) -> Data { ... }
```

---

## 7. SwiftData

### Model Definition

Define `@Model` classes with explicit relationships and delete rules.

```swift
@Model
final class Transaction {
    var amount: Decimal
    var note: String
    var date: Date
    var type: TransactionType // enum: .income, .expense

    @Relationship(deleteRule: .nullify, inverse: \Category.transactions)
    var category: Category?

    @Relationship(deleteRule: .nullify, inverse: \Budget.transactions)
    var budget: Budget?

    init(amount: Decimal, note: String, date: Date, type: TransactionType) {
        self.amount = amount
        self.note = note
        self.date = date
        self.type = type
    }
}

@Model
final class Category {
    var name: String
    var icon: String        // SF Symbol name
    var colorHex: String
    var transactions: [Transaction]?

    init(name: String, icon: String, colorHex: String) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}

@Model
final class Budget {
    var name: String
    var limitAmount: Decimal
    var periodStart: Date
    var periodEnd: Date
    var transactions: [Transaction]?

    init(name: String, limitAmount: Decimal, periodStart: Date, periodEnd: Date) {
        self.name = name
        self.limitAmount = limitAmount
        self.periodStart = periodStart
        self.periodEnd = periodEnd
    }
}
```

### Querying

- Use **`@Query`** in views for reactive data fetching.
- Use **`#Predicate`** for type-safe filters.
- Use **`FetchDescriptor`** with `SortDescriptor` for complex queries.
- Use `fetchLimit` and `fetchOffset` for pagination with large datasets.

```swift
// In a View
@Query(
    filter: #Predicate<Transaction> { $0.type == .expense },
    sort: \Transaction.date,
    order: .reverse
)
private var expenses: [Transaction]

// In a ViewModel / Service
let descriptor = FetchDescriptor<Transaction>(
    predicate: #Predicate { $0.date >= startOfMonth && $0.date <= endOfMonth },
    sortBy: [SortDescriptor(\.date, order: .reverse)]
)
descriptor.fetchLimit = 50
let results = try modelContext.fetch(descriptor)
```

### Background Processing

Use **`@ModelActor`** for heavy operations off the main thread (batch imports, CSV processing, aggregation).

```swift
@ModelActor
actor TransactionImporter {
    func importFromCSV(_ data: Data) throws -> Int {
        let rows = parseCSV(data)
        for row in rows {
            let transaction = Transaction(amount: row.amount, note: row.note, date: row.date, type: row.type)
            modelContext.insert(transaction)
        }
        try modelContext.save()
        return rows.count
    }
}
```

### Migration

Define versioned schemas and migration plans for schema evolution.

```swift
enum TransactionSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [Transaction.self, Category.self] }
    // V1 model definitions...
}

enum TransactionSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] { [Transaction.self, Category.self, Budget.self] }
    // V2 model definitions with Budget added...
}

enum TransactionMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [TransactionSchemaV1.self, TransactionSchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    static let migrateV1toV2 = MigrationStage.lightweight(fromVersion: TransactionSchemaV1.self, toVersion: TransactionSchemaV2.self)
}
```

### CloudKit Sync

If enabled, all properties must be **optional or have defaults**. All relationships must be **optional**. No `.deny` delete rules.

```swift
let config = ModelConfiguration(
    "QuanLyChiTieu",
    cloudKitDatabase: .private("iCloud.com.app.quanlychitieu")
)
```

---

## 8. M3 Expressive Design System

### Core API

```swift
// Content cards — surface background + corner radius + elevation shadow
.m3Card(cornerRadius: Spacing.cornerExtraLarge, elevation: .level1, background: .surfaceContainerLow)

// Hero cards — prominent surface with level2 elevation
.m3HeroCard(cornerRadius: Spacing.cornerExtraExtraLarge, background: .surfaceContainerLow)

// Buttons — solid color fill
.background(Color.appPrimary, in: .capsule)    // Primary CTA
.background(Color.surfaceContainerHigh, in: .capsule)  // Secondary
```

### Elevation Levels

| Level    | Shadow Radius | Shadow Y | Opacity | Usage                        |
|----------|---------------|----------|---------|------------------------------|
| `level0` | 0             | 0        | 0       | Flat surfaces, disabled      |
| `level1` | 4             | 1        | 0.08    | Standard content cards       |
| `level2` | 8             | 2        | 0.10    | Hero cards, prominent        |
| `level3` | 12            | 4        | 0.15    | FABs, floating elements      |

### Shape Scale (Corner Radii)

| Token                  | Value | Usage                                    |
|------------------------|-------|------------------------------------------|
| `cornerExtraSmall`     | 4pt   | Tiny badges                              |
| `cornerSmall`          | 8pt   | Small chips, tags                        |
| `cornerMedium`         | 12pt  | Unselected chips, small cards            |
| `cornerLarge`          | 16pt  | Secondary cards, buttons                 |
| `cornerExtraLarge`     | 28pt  | Content cards (default)                  |
| `cornerExtraExtraLarge`| 48pt  | Hero cards, sheets, success overlays     |
| `cornerFull`           | 9999  | Capsule / pill shapes                    |

**Shape hierarchy principle:** Selected/primary states use larger corner radii than unselected.

### Typography (30 Styles)

15 baseline + 15 emphasized (bold weight). Use `Typography.*Emphasized` for:
- Selected states, active navigation, section headers, CTAs, hero amounts.

Use baseline `Typography.*` for body text, labels, descriptions, inactive states.

### Motion Tokens

All animations use spring physics via `Motion` enum. Never use `.easeInOut()` or duration-based animations.

```swift
Motion.spatialDefault   // .spring(response: 0.4, dampingFraction: 0.7) — bounce
Motion.spatialFast      // .spring(response: 0.25, dampingFraction: 0.7) — quick bounce
Motion.spatialSlow      // .spring(response: 0.6, dampingFraction: 0.7) — slow bounce
Motion.effectDefault    // .spring(response: 0.3, dampingFraction: 1.0) — no bounce
Motion.effectFast       // .spring(response: 0.15, dampingFraction: 1.0) — instant
```

- **Spatial** (position, size, shape): allows bounce. Use for layout animations, FAB morphing, chip selection.
- **Effect** (color, opacity): no bounce. Use for fade, color transitions, progress bars.

### Button Press Style

```swift
Button("Save") { }
    .buttonStyle(ExpressivePressStyle())  // Scale 0.92 + spatial spring bounce
```

### Practical Application in This App

| Component                  | Treatment                                                        |
|----------------------------|------------------------------------------------------------------|
| Tab bar                    | System default (no custom styling)                               |
| Floating "Add Expense" FAB | `GlassFAB` — `primaryContainer` fill + `level3` shadow + circle |
| Onboarding page dots       | `PageDotsView` — solid `appPrimary` fill for active              |
| Onboarding CTA             | `.background(Color.appPrimary, in: .capsule)` + press style      |
| Category filter chips      | Selected: filled `appPrimary` capsule. Unselected: outlined      |
| Hero balance card          | `.m3HeroCard()` — `cornerExtraExtraLarge` + `level2`             |
| Dashboard cards            | `.m3Card()` — `cornerExtraLarge` + `level1`                      |
| Budget progress cards      | `.m3Card(cornerRadius: ...)` — surface bg + `level1`             |
| Chart containers           | `.m3Card(cornerRadius: Spacing.cornerLarge)` + `level1`          |
| Settings section cards     | `.m3Card(cornerRadius: Spacing.cornerExtraLarge)` + `level1`     |
| Transaction list rows      | No card styling. Plain list cells.                               |
| Form fields                | No card styling. Standard input.                                 |
| Sheets                     | `.presentationBackground(Color.surfaceContainerLowest)`          |

### Text & Icons on Surfaces

Use `Color.onSurface` for primary text, `Color.onSurfaceVariant` for secondary. Use `Color.onPrimary` on primary-colored backgrounds. Never use `.foregroundStyle(.primary)` for vibrancy (no glass).

```swift
// FAB with M3E
Image(systemName: "plus")
    .font(.title2.weight(.semibold))
    .foregroundStyle(Color.onPrimaryContainer)
    .frame(width: 56, height: 56)
    .background(Color.primaryContainer, in: .circle)
    .shadow(color: .black.opacity(0.15), radius: 12, y: 4)

// Content card with M3E
VStack(alignment: .leading, spacing: Spacing.sm) {
    Text("Tổng chi tiêu")
        .font(Typography.bodySmall)
        .foregroundStyle(Color.onSurfaceVariant)
    Text(viewModel.formattedTotal)
        .font(Typography.titleLargeEmphasized)
        .foregroundStyle(Color.onSurface)
}
.padding(Spacing.lg)
.m3Card()
```

### Anti-Patterns

1. Never use `.glassEffect()`, `GlassEffectContainer`, or `.ultraThinMaterial`.
2. Never use `.easeInOut()` or duration-based animations — use `Motion` tokens.
3. Never use gray/monochrome for accent colors — use vibrant, high-chroma hues.
4. Never use `.foregroundStyle(.primary)` for vibrancy — use explicit semantic colors.
5. Never apply card styling to form fields or individual list rows.
6. Never use the same corner radius for all elements — use shape hierarchy.

### Dark Mode

M3E surface colors (`Color+Theme.swift`) are defined with adaptive light/dark hex values. Elevation shadows use `.black.opacity()` which works in both modes. No manual overrides needed.

---

## 9. Security (Financial App)

- **Never hardcode secrets** (API keys, tokens) in source. Use `.xcconfig` files excluded from git.
- **Keychain** for all credentials and tokens. `@AppStorage` is NOT secure.
- **`NSFileProtectionComplete`** on SwiftData database files. Add the Data Protection entitlement.
- **Certificate pinning** for all API calls. Implement via `URLSessionDelegate`.
- **ATS enforced.** `NSAllowsArbitraryLoads` must be `false`. Use `NSExceptionDomains` with justification for any exceptions.
- **Biometric auth** via `LAContext` for sensitive operations:
  - Use `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)` with passcode fallback.
  - Re-authenticate when app returns from background after 5+ minutes.
  - Handle `.biometryNotEnrolled`, `.biometryLockout`, `.userCancel` gracefully.
  - Use `kSecAccessControlBiometryCurrentSet` for Keychain items requiring biometrics.
- **Never log sensitive data.** Transaction amounts, account numbers, tokens — not even in DEBUG builds. Use `os.Logger` with privacy annotations: `logger.debug("Transaction: \(id, privacy: .public) amount: \(amount, privacy: .private)")`.
- **Clipboard protection.** When copying sensitive data (account numbers), use `UIPasteboard.general.setItems(_:options:)` with `.expirationDate` set to 60 seconds.
- **App switcher protection.** Overlay a branded splash view when the app enters background to hide sensitive data in the app switcher.

---

## 10. Networking

- **URLSession** with `async/await`. No third-party HTTP libraries.
- Centralize API calls in per-domain services (`TransactionService`, `BudgetService`, `AuthService`).
- Define API errors as a typed enum conforming to `LocalizedError`.
- Configure `JSONDecoder` once (`.convertFromSnakeCase`, ISO 8601 date strategy) and reuse.
- Never block the main actor with synchronous network calls.
- **Token refresh:** Implement a `TokenManager` actor that handles refresh transparently. Retry failed 401 requests once after refresh.

---

## 11. Error Handling

- Define `AppError` enum per domain. Never use generic `Error` for known failure modes.
- Always localize user-facing error messages. Never display raw server responses, error codes, or stack traces.
- Show `EmptyStateView` for empty data, `RetryView` for recoverable errors, cached data when offline.
- Log errors with `os.Logger`. Never `print()` in production code.

### Error State UI

```swift
// Standard empty state pattern
struct EmptyStateView: View {
    let icon: String      // SF Symbol
    let title: String
    let subtitle: String
    let action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(subtitle)
        } actions: {
            if let action {
                Button("Thử lại", action: action)
                    .buttonStyle(.glassProminent)
            }
        }
    }
}
```

---

## 12. Localization

- **String Catalogs** (`.xcstrings`). No legacy `.strings` files.
- All user-facing strings must be localized. Use `String(localized:)` or SwiftUI's automatic literal localization.
- **Vietnamese (`vi`)** is the primary locale. English (`en`) as fallback.
- **VND formatting:** Zero decimal places. Vietnamese uses `.` as thousands separator. Never hardcode separators.
  ```swift
  amount.formatted(.currency(code: "VND"))  // "1.500.000 ₫"
  ```
- **Compact notation** for large amounts: use custom formatter for "1,5tr" (triệu) style abbreviations in cards and charts.
- **Date formatting:** Use `FormatStyle`. Vietnamese months are "Tháng 1" through "Tháng 12". Use `RelativeDateTimeFormatter` for "Hôm nay", "Hôm qua".
  ```swift
  date.formatted(.dateTime.day().month(.wide))  // "15 Tháng 3"
  ```
- **Diacritical-insensitive search:** When searching transactions, use `.localizedStandardContains()` or `NSPredicate` with diacritic-insensitive option so "chi tieu" matches "chi tiêu".
- **Input composition:** Never validate or truncate text fields during Vietnamese telex/VNI input composition. Wait for `textFieldDidEndEditing` / committed text.

---

## 13. Testing

- Unit test ViewModels and Services. Test state transitions, not view rendering.
- Use **Swift Testing framework** (`@Test`, `#expect`) for all new tests. XCTest only for UI tests.
  ```swift
  // Swift Testing — no test_ prefix needed
  @Test func addExpense_validAmount_updatesBalance() {
      let vm = BudgetViewModel(service: MockBudgetService())
      // ...
      #expect(vm.totalSpent == 350_000)
  }
  ```
- Mock protocols, not classes. Define protocols for services, inject mocks in tests.
- No test logic in production code. No `#if DEBUG` flags for test paths. Use dependency injection.
- **SwiftData testing:** Use in-memory `ModelConfiguration(isStoredInMemoryOnly: true)` for all persistence tests.
- **Snapshot testing:** Use swift-snapshot-testing for visual regression of key screens and M3E components.
- **Accessibility audits:** Use `performAccessibilityAudit(for:)` in UI tests for every screen.

---

## 14. Performance

- Do not add performance optimizations unless the code processes more than 100 items or involves network/disk I/O. Profile with Instruments first.
- Keep `@State` granular. One property per piece of state — never a large struct in `@State`.
- Conform views to `Equatable` where body recomputation is expensive. SwiftUI uses it for smarter diffing.
- Keep view identity stable. Do not change `id` values unnecessarily in `ForEach` or `.id()` modifiers.
- Use `LazyVStack`, `LazyHStack`, lazy `navigationDestination` for scrollable/navigable content.
- Use SF Symbols for icons. Use `AsyncImage` with `NSCache`-based caching for remote images.
- Flat view hierarchies render faster than deeply nested stacks.
- **Launch optimization:** Do not perform heavy work in `App.init()`. Initialize `ModelContainer` lazily or in a `task {}` on the root view.
- **Memory:** Use `fetchLimit` on `FetchDescriptor` when loading transaction history. Batch-fetch months, not the entire database.

---

## 15. Widget & App Intents

### WidgetKit

- Provide widgets: **today's spending summary**, **budget progress**, **quick-add expense** (interactive).
- Share `ModelContainer` between app and widget via **App Group** container.
- Use `TimelineProvider` with `.atEnd` reloadPolicy for expense data that updates on each transaction.
- Apply M3E card styling for iOS 26 Home Screen widgets.

### App Intents & Shortcuts

- Implement `AppIntent` for: "Add expense", "Show today's spending", "Check budget status".
- Register intents for Siri and Spotlight.
- Use `AppShortcutsProvider` to surface default shortcuts.

---

## 16. Dependencies

- **Swift Package Manager** only. No CocoaPods, no Carthage.
- Prefer Apple frameworks. Only add a third-party dependency if Apple provides no equivalent AND the package has been updated within the last 6 months:
  - Charts → Swift Charts
  - Networking → URLSession
  - Persistence → SwiftData
  - Animation → SwiftUI animations
  - Image loading → AsyncImage + NSCache
  - Receipt scanning → VisionKit / `DataScannerViewController`
  - PDF export → Build with UIKit `UIGraphicsPDFRenderer`
  - CSV export → Build manually (trivial)
- Pin versions with `.upToNextMinor` to avoid surprise breakage.
- **Snapshot testing:** [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) is the one approved third-party test dependency.

---

## 17. Code Style

- Comments explain **why**, not what. No comments on self-explanatory code.
- Delete all dead code. No unused functions, no commented-out blocks, no unresolved TODOs.
- Use `// MARK: -` for logical sections in large files. Maximum 2 per file.
- **SwiftLint** enforced at build time.
- Maximum file length: **300 lines**. Maximum function length: **30 lines**.

---

## 18. Naming Conventions

- **Types:** `UpperCamelCase` — `TransactionModel`, `BudgetViewModel`, `OnboardingView`
- **Properties & methods:** `lowerCamelCase` — `totalExpense`, `fetchTransactions()`
- **Booleans:** Read as assertions — `isLoading`, `hasUnsavedChanges`, `canSubmit`
- **Protocols:** Noun for capabilities (`Identifiable`), adjective for behaviors (`Loadable`, `Refreshable`)
- **Files:** Match the primary type — `BudgetViewModel.swift` contains `BudgetViewModel`
- **Extensions:** `Type+Context.swift` — `Date+Formatting.swift`, `Color+Theme.swift`
- **No abbreviations** unless universally understood (`URL`, `ID`)

---

## 19. Dark Mode

The app supports both light and dark mode. Define all colors as adaptive `Color` assets in `Assets.xcassets` or via `Color+Theme.swift` extension with light/dark variants.

### Light Palette → Dark Palette Mapping (X.com-inspired)

| Token          | Light       | Dark        |
|----------------|-------------|-------------|
| `primary`      | `#1D9BF0`   | `#1D9BF0`   |
| `onPrimary`    | `#FFFFFF`   | `#FFFFFF`   |
| `primaryContainer` | `#D1E4FF` | `#004A77` |
| `surface`      | `#FFFFFF`   | `#000000`   |
| `onSurface`    | `#0F1419`   | `#E7E9EA`   |
| `onSurfaceVariant` | `#536471` | `#71767B` |
| `tertiary`     | `#00B87A`   | `#00B87A`   |
| `tertiaryContainer` | `#B4F5DC` | `#005140` |
| `error`        | `#F4212E`   | `#F4212E`   |
| `surfaceContainer` | `#EFF3F4` | `#202327` |
| `outlineVariant` | `#EFF3F4` | `#2F3336`  |

**Accent colors:** Blue `#1D9BF0`, Pink `#F91880`, Green `#00B87A`, Yellow `#FFD500`, Red `#F4212E`, Purple `#7857FF`, Orange `#FF7A00`.

Use `theme.json` as the source of truth for these values. M3E surface colors are adaptive (light/dark hex pairs in `Color+Theme.swift`).

---

## 20. Animations & Transitions

- Use `Motion` tokens for all animations (see Section 8). Never use `.easeInOut()` or duration-based animations.
- Use `withAnimation(Motion.spatialDefault) {}` for state-driven transitions. Prefer `.animation(_:value:)` on specific views for scoped animations.
- Use `matchedGeometryEffect` for hero transitions between views.
- Use `contentTransition(.numericText())` for animating number changes (amounts, percentages).
- Provide haptic feedback for significant actions: `UIImpactFeedbackGenerator(style: .medium)` for button presses, `.success` for completed transactions.
- Respect `@Environment(\.accessibilityReduceMotion)` — disable non-essential animations when true.
