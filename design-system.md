# Design System — Quản Lý Chi Tiêu

> Current implementation reference. Covers color tokens, typography, spacing, components, and patterns used across the iOS app.

---

## 1. Design Language

**Core philosophy:** Clean, warm, content-first design using iOS 26 native patterns. Liquid Glass for action buttons only. Flat surface backgrounds for all other elements. No shadows anywhere.

**Principles:**
- **Apple HIG first.** Native `TabView`, `NavigationStack`, large titles, standard safe areas.
- **Warm palette.** Terracotta accent on cream surfaces — financial app that feels approachable.
- **No shadows.** Zero `box-shadow` / `.shadow()` across the entire codebase.
- **Liquid Glass on buttons only.** Save/CTA buttons use `.glassEffect()`. Cards, chips, rows use flat `.background()`.
- **Content density over decoration.** Data is the hero — charts, amounts, transaction rows.

---

## 2. Color System

### 2.1 Palette Constants

| Name | Hex | Role |
|------|-----|------|
| Terracotta | `#C15F3C` | Primary accent, CTAs, active states |
| Warm Gray | `#B1ADA1` | Secondary, muted elements, outlines |
| Cream | `#F4F3EE` | Surface background |
| White | `#FFFFFF` | Card backgrounds, containers |

### 2.2 Primary (Terracotta)

| Token | Light | Dark |
|-------|-------|------|
| `appPrimary` | `#C15F3C` | `#D4795A` |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` |
| `primaryContainer` | `#F2DDD5` | `#4A2A1E` |
| `onPrimaryContainer` | `#2C2520` | `#F2DDD5` |

### 2.3 Secondary (Warm Gray)

| Token | Light | Dark |
|-------|-------|------|
| `appSecondary` | `#B1ADA1` | `#C8C4BA` |
| `onSecondary` | `#FFFFFF` | `#2C2520` |
| `secondaryContainer` | `#E8E6E0` | `#3A3835` |

### 2.4 Semantic Colors (Financial)

| Role | Light | Dark | Usage |
|------|-------|------|-------|
| Income | `#5A8A5A` | `#7AB87A` | Positive amounts, income indicators |
| Expense/Error | `#A84832` | `#E07A5E` | Negative amounts, expense indicators |
| Warning | `#D4923C` | `#E0A850` | Safe daily spending badge, alerts |

### 2.5 Surface Palette

| Token | Light | Dark |
|-------|-------|------|
| `appSurface` | `#F4F3EE` (cream) | `#1A1816` |
| `onSurface` | `#2C2520` | `#FAF9F6` |
| `onSurfaceVariant` | `#6E6960` | `#B5B0A8` |
| `surfaceContainerLowest` | `#FFFFFF` | `#0E0C0A` |
| `surfaceContainerLow` | `#F4F3EE` | `#1A1816` |
| `surfaceContainer` | `#EEEDEA` | `#252220` |
| `surfaceContainerHigh` | `#E8E6E0` | `#302C28` |
| `outlineVariant` | `#D5D2CC` | `#3A3835` |

### 2.6 Category Colors

| Category | Light | Dark |
|----------|-------|------|
| Food (Ăn uống) | `#C15F3C` | `#D4795A` |
| Transport (Di chuyển) | `#6B8FA3` | `#8DB3C7` |
| Shopping (Mua sắm) | `#D4923C` | `#E0A850` |
| Entertainment (Giải trí) | `#5A8A5A` | `#7AB87A` |
| Bills (Hóa đơn) | `#8A7098` | `#AE94BC` |
| Health (Sức khỏe) | `#6B8FA3` | `#8DB3C7` |

### 2.7 App Tint

Global app tint is `Color.appPrimary` (terracotta), applied via `.tint()` on the app root. This colors:
- Tab bar active icon
- Navigation back buttons
- Toggle switches
- DatePickers
- System links

---

## 3. Typography

**Font:** System (San Francisco) via SwiftUI. Vietnamese diacriticals render natively.

**Scale:** Defined in `Typography.swift` — 30 styles (15 baseline + 15 emphasized).

| Usage | Token | Weight |
|-------|-------|--------|
| Large display amounts | `.system(size: 40, weight: .bold)` | Bold |
| Section headers | `Typography.titleSmallEmphasized` | Semibold |
| Body text | `Typography.bodyMedium` | Regular |
| Labels | `Typography.labelMedium` | Medium |
| Small captions | `Typography.labelSmall` | Medium |
| Amounts (transaction rows) | `Typography.bodyMediumEmphasized` | Semibold |

**Rule:** Use `*Emphasized` variants for: selected states, headers, CTAs, hero amounts. Use baseline for body, descriptions, inactive states.

---

## 4. Spacing (Apple HIG 8pt Grid)

Defined in `Spacing.swift`. All spacing uses `@ScaledMetric` in views for Dynamic Type support.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4pt | Tight pairs |
| `sm` | 8pt | Compact groups |
| `md` | 12pt | Inner spacing |
| `lg` | 16pt | Standard padding (HIG compact margin) |
| `contentMargin` | 20pt | Apple HIG standard margin |
| `xl` | 24pt | Section-to-element |
| `sectionGap` | 32pt | Section-to-section |
| `minTouchTarget` | 44pt | Apple HIG minimum tap area |

**Horizontal content padding:** `.scenePadding(.horizontal)` — uses Apple's system-standard margins.

---

## 5. Corner Radii

| Token | Value | Usage |
|-------|-------|-------|
| `cornerExtraSmall` | 4pt | Badges |
| `cornerSmall` | 8pt | Chips, chart bars |
| `cornerMedium` | 12pt | Icon badges, buttons |
| `cornerLarge` | 16pt | Cards, inputs |
| `cornerExtraLarge` | 20pt | Prominent cards, transaction rows |
| `cornerHero` | 28pt | Hero cards |
| `cornerExtraExtraLarge` | 48pt | Modal sheets |

**Nested radius rule:** Outer Radius = Inner Radius + Padding.

---

## 6. Components

### 6.1 Cards (`.m3Card()`)

Flat background, no shadow. Defined in `M3CardModifier.swift`.

```swift
.m3Card(cornerRadius: Spacing.cornerExtraLarge, background: .white)
```

- Default background: `surfaceContainerLow`
- Hero cards: white background, `cornerExtraLarge` (20pt)
- No elevation, no shadow

### 6.2 Buttons

**Primary CTA (Liquid Glass):**
```swift
.glassEffect(.regular.interactive(), in: Capsule())
```
Used by: `GlassSaveButton`, save buttons in AddTransaction/QuickAdd.

**Selected chips/toggles:**
```swift
.background(Color.appPrimary, in: Capsule())
```
Solid terracotta fill, white text.

**Unselected chips:**
```swift
.background(Color.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: Spacing.cornerMedium))
```

### 6.3 Tab Bar

Native iOS `TabView` with 5 tabs:
- Tổng quan (`chart.pie`)
- Giao dịch (`creditcard`)
- Thêm (`plus`, `role: .search`) — intercepts tap → opens AddTransaction
- Ví (`banknote`)
- Cài đặt (`gearshape`)

### 6.4 Navigation

Apple native `NavigationStack` + `.navigationTitle()` + `.navigationBarTitleDisplayMode(.large)`.

### 6.5 Transaction Row

```
[Icon Badge 40pt] [VStack: title + category] [Amount]
```
- Icon: SF Symbol in category color, 40pt frame, 12pt corner radius, color.opacity(0.15) background
- Amount: colored by type (income green / expense red)
- Row: white background, `cornerExtraLarge`, 16pt padding

### 6.6 Spending Chart (Dashboard)

Yearly bar chart (Swift Charts `BarMark`):
- "Tổng chi tiêu" label + large amount
- Current year bar: solid `appPrimary`, past years: 15% opacity
- Y-axis on trailing side with grid lines
- X-axis: year labels

### 6.7 Safe Daily Badge

```
[Warning Icon 24pt] [VStack: label + amount]
```
- White card background, `cornerExtraLarge`
- Warning color for icon and amount

---

## 7. Patterns

### No Shadows
Zero `.shadow()` calls anywhere. Depth is communicated through background color contrast (cream surface → white cards).

### Liquid Glass — Buttons Only
`.glassEffect()` is used exclusively on save/CTA buttons. Never on cards, chips, rows, or containers.

### Dynamic Type
All spacing values support `@ScaledMetric`. Use `.scenePadding()` for system-standard margins.

### Vietnamese Locale
- Primary: Vietnamese (`vi`). Fallback: English (`en`).
- Currency: `amount.formatted(.currency(code: "VND"))` — zero decimals, dot thousands separator.
- All user-facing strings: `String(localized:)`.

---

## 8. File References

| File | Contents |
|------|----------|
| `Color+Theme.swift` | All color definitions |
| `Typography.swift` | Type scale tokens |
| `Spacing.swift` | Spacing + corner radii + `ScaledSpacing` |
| `M3CardModifier.swift` | `.m3Card()` modifier |
| `GlassSaveButton.swift` | Liquid Glass CTA button |
| `ExpressivePressStyle.swift` | Spring bounce button style |
| `Motion.swift` | Spring animation tokens |
