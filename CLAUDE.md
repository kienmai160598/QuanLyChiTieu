# Quản Lý Chi Tiêu — Claude Code Instructions

## Platform

- **iOS 26+ only.** No Android. No cross-platform.
- **Swift 6.2** (Xcode 26 toolchain).
- **SwiftUI first.** UIKit only for: camera/photo picker if `PhotosPicker` is insufficient, `WKWebView`, or MapKit when `Map` view lacks a needed feature. Document UIKit usage with `// UIKit: <reason>`.
- **M3 Expressive** is the primary visual language. Use `.m3Card()` for content surfaces, solid `Color` backgrounds for buttons/chips, and `M3Elevation` shadows. Never use `.glassEffect()` or `GlassEffectContainer`.

## Rule Priority (when rules conflict)

1. **Security** — always wins. Never log sensitive data, never hardcode secrets.
2. **Accessibility** — second. Ensure sufficient color contrast on solid surfaces and use semantic colors (`Color.onSurface`, `Color.onPrimary`).
3. **Swift language safety** — third. No force unwraps, no force try, no `Any`.
4. **Architecture & structure** — fourth. MVVM, single responsibility, unidirectional data flow.
5. **Design aesthetics** — lowest. Visual polish never justifies violating the above.

## Critical Rules (always enforce)

### Swift
- `@Observable` for all ViewModels. Never use `ObservableObject` / `@Published`.
- `@MainActor` on all ViewModels. All UI state mutations on the main thread.
- `let` over `var`. Immutable by default.
- No `!` (force unwrap) in production code. Use `guard let`, `if let`, or `??`.
- No `try!` in production code. Use `do-catch` or propagate with `throws`.
- No `Any` / `AnyObject` unless interfacing with Objective-C.
- `async/await` only. No completion handlers. No Combine for new code.
- `Sendable` conformance required for all types crossing isolation boundaries.
- Every type and method must have an explicit access modifier (`private`, `internal`, `public`).
- Maximum file length: 300 lines. Maximum function length: 30 lines.

### Icons
- Prefer **base SF Symbol names** (e.g. `person`, `bell`, `house`) in system containers (tab bar, navigation bar, toolbar) — the platform auto-selects filled or outline per context.
- Use **filled variants explicitly** (e.g. `person.fill`) only in custom views outside system containers, or when toggling filled/unfilled to indicate selection state.

### M3 Expressive Design System
- **Cards**: Use `.m3Card(cornerRadius:elevation:background:)` for content surfaces. Default: `surfaceContainerLow` background + `level1` shadow + `cornerExtraLarge` (28pt).
- **Hero cards**: Use `.m3HeroCard()` for prominent surfaces. Uses `cornerExtraExtraLarge` (48pt) + `level2` shadow.
- **Buttons (primary CTA)**: Solid fill with `.background(Color.appPrimary, in: .capsule)`. Use `ExpressivePressStyle()` for spring-bounce feedback. Height: 56pt minimum.
- **Buttons (secondary)**: `.background(Color.surfaceContainerHigh, in: .capsule)` with outline: `.overlay { Capsule().strokeBorder(Color.outlineVariant, lineWidth: 1) }`.
- **Chips (selected)**: `.background(Color.appPrimary, in: .capsule)` with `Typography.*Emphasized` font.
- **Chips (unselected)**: `.background(Color.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: Spacing.cornerMedium))` with outline.
- **Icon buttons**: Use `M3IconButton` from `SharedUI/M3IconButton.swift` for all icon-only buttons (toolbar, navigation, actions). Three styles: `.filled` (soft `surfaceContainerHigh` bg — default), `.filledTonal` (`primaryContainer` bg), `.primary` (`appPrimary` bg + white icon). Never hand-build icon button styling inline.
- **FABs**: `GlassFAB` with `primaryContainer` background, `level3` shadow. Three sizes: regular (56pt), medium (80pt), large (96pt).
- **Sheets**: `.presentationBackground(Color.surfaceContainerLowest)` + `.presentationCornerRadius(Spacing.cornerExtraExtraLarge)`.
- **NEVER** use `.glassEffect()`, `GlassEffectContainer`, or `.ultraThinMaterial`. These are removed from the project.
- **Text on surfaces**: Use `Color.onSurface` for primary text, `Color.onSurfaceVariant` for secondary text. Never rely on `.foregroundStyle(.primary)` for vibrancy.
- **Shape hierarchy** (M3E principle): Selected/primary states use larger corner radii than unselected states. Example: selected chip = capsule, unselected = `cornerMedium`.
- **Elevation hierarchy**: `level0` (flat) → `level1` (cards) → `level2` (hero) → `level3` (FABs/floating).

### M3 Expressive Typography
- 30-style type scale: 15 baseline + 15 emphasized (bold weight).
- Use `Typography.*Emphasized` variants for: selected states, active navigation, section headers, CTAs, hero amounts.
- Use baseline `Typography.*` for: body text, labels, descriptions, inactive states.

### M3 Expressive Motion
- **All animations use spring physics** via `Motion` tokens. Never use `.easeInOut()`, `.easeOut()`, or duration-based animations.
- **Spatial springs** (position, size, shape — allows bounce): `Motion.spatialDefault`, `Motion.spatialFast`, `Motion.spatialSlow`.
- **Effect springs** (color, opacity — no bounce): `Motion.effectDefault`, `Motion.effectFast`.
- `ExpressivePressStyle()` for button press feedback (scale 0.92 + spatial spring).

### Color System
- **Primary = Black/White**: `appPrimary` is `#1C1C1E` (light) / `#F5F5F7` (dark). `onPrimary` is white/black. Clean, high-contrast, monochrome primary.
- **Secondary = Baby Blue** (`#A4B1BA`): Supporting accent for secondary actions and containers.
- **Semantic colors**: `appIncome` (sage green), `appError` (rose), `appWarning` (warm nude) remain distinct for financial context.
- **Category colors**: Each category gets a distinct hue (defined in `Color+Theme.swift`).
- `Color.onPrimary` / `Color.onPrimaryContainer` for text on colored surfaces.
- **No shadows**. Use flat backgrounds or Liquid Glass (buttons only).

### Security (financial app)
- Keychain for all credentials and tokens. Never `@AppStorage` for sensitive data.
- `NSFileProtectionComplete` on SwiftData database files.
- Certificate pinning for all API calls.
- Biometric auth (Face ID) via `LAContext` for sensitive operations.
- Never log transaction amounts, account numbers, or tokens — even in DEBUG.
- ATS enforced. `NSAllowsArbitraryLoads` must be `false`.

### Persistence
- **SwiftData** as primary persistence. Define `@Model` classes with explicit `@Relationship` and delete rules.
- Use `@Query` in views, `#Predicate` for filtering, `FetchDescriptor` for complex queries.
- Use `@ModelActor` for background processing (batch imports, calculations).
- All properties optional or with defaults if CloudKit sync is enabled.

### Localization
- Vietnamese (`vi`) is the primary locale. English (`en`) as fallback.
- Use String Catalogs (`.xcstrings`). All user-facing strings must be localized.
- Format currency: `amount.formatted(.currency(code: "VND"))` — never hardcode separators.
- VND has zero decimal places. Vietnamese uses `.` as thousands separator.

## Detailed References

For full rules with code examples, read these files:

| File | Contents |
|------|----------|
| `rule.md` | Swift/iOS best practices, M3E design tokens, SwiftData, concurrency, security, testing, architecture |
| `design-system.md` | HTML/CSS design mockup rules (M3 Asymmetric). **Ignore when writing Swift code.** |
| `rebuild/design-brief.md` | Creative brief for onboarding rebuild (HTML mockups only) |
| `design-system/theme.json` | M3 color/typography/spacing token definitions |

## Context Boundaries

- **When generating Swift/SwiftUI code:** Follow `CLAUDE.md` and `rule.md`. Ignore `design-system.md` and all CSS/HTML specifications.
- **When generating HTML/CSS mockups:** Follow `design-system.md`. Ignore Swift/SwiftUI rules.
- **When converting design mockups to Swift:** Use `design-system.md` hex values to define `Color+Theme.swift` extensions. Use SwiftUI's native type system (`.font(.title)`, `.headline`), NOT px values. Use `.m3Card()` for cards, solid `Color` backgrounds for buttons.
