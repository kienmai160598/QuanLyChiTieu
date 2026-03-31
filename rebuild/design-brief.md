# Creative Brief: Onboarding Rebuild
## "Quan Ly Chi Tieu" - Vietnamese Expense Tracker

**Version:** 2.0
**Date:** 2026-03-15
**Author:** UX Design Lead
**Status:** FINAL -- Ready for implementation

---

## Executive Summary

The current onboarding screens are *functional but forgettable*. They commit every generic fintech onboarding sin: off-center blob backgrounds, a lonely donut chart, flat bar charts, and scattered geometric shapes floating in space. The result is an app that looks like a template, not a product. Users swipe through without forming any emotional connection.

This brief defines the exact visual and structural direction for four rebuilt onboarding screens that will make a user stop and think: "This app takes money seriously, and it respects my time."

**The north star:** Revolut's confidence, N26's minimalism, Cleo's personality -- adapted for a Vietnamese audience that values clarity, trust, and sophistication.

---

## 1. Visual Direction

### 1.1 Color Palette

Keep the seed color `#006D3B`. It communicates financial growth, trust, and Vietnamese cultural familiarity (money, prosperity). But the current implementation uses it timidly. Here is the refined approach:

#### Primary Palette (use boldly)
| Role | Value | Usage |
|------|-------|-------|
| Primary | `#006D3B` | CTAs, key accents, active states |
| Primary Container | `#9AF6B2` | Background fills, illustration fills |
| On Primary Container | `#00210E` | Text on light green surfaces |
| Primary Fixed Dim | `#7ED998` | Secondary accents, chart fills |

#### Accent Palette (use for contrast and energy)
| Role | Value | Usage |
|------|-------|-------|
| Tertiary | `#3A6470` | Data visualization, secondary actions |
| Tertiary Container | `#BDE9F7` | Insight cards, chart backgrounds |
| Category Shopping | `#7D5260` | Warm accent for variety |
| Category Entertainment | `#6750A4` | Purple accent for premium moments |

#### Neutral Palette (the backbone)
| Role | Value | Usage |
|------|-------|-------|
| Surface | `#FBFDF8` | Primary background |
| Surface Container | `#EFF1EC` | Card backgrounds |
| On Surface | `#191C19` | Primary text |
| On Surface Variant | `#414941` | Secondary text |
| Outline Variant | `#C1C9BE` | Dividers, inactive dots |

#### NEW: Extended Onboarding Colors (not in current tokens)
| Role | Value | Usage |
|------|-------|-------|
| Gradient Start | `#004D29` | Dark green for rich gradients |
| Gradient End | `#00A650` | Bright green for gradient terminals |
| Warm Glow | `#F5E6D0` | Warm undertone for glass effects |
| Deep Surface | `#0A1F12` | Near-black green for Screen 4 |
| Gold Accent | `#C8A951` | Sparingly, for "premium" moments |

### 1.2 Gradient Strategy

**Rule: No flat color fills for hero backgrounds. Every hero section uses a gradient.**

- **Screen 1:** Radial gradient from `#9AF6B2` (center-right) to `#FBFDF8` (edges). Subtle. The gradient should feel like light is entering from the upper right.
- **Screen 2:** Linear gradient at 135 degrees from `#BDE9F7` to `#EFF1EC`. Cool and analytical.
- **Screen 3:** Multi-stop gradient: `#004D29` at top, `#006D3B` at 40%, transitioning to `#FBFDF8` at 60%. The chart card sits on the transition line.
- **Screen 4:** Radial gradient from `#006D3B` (center) to `#0A1F12` (corners). Deep, confident, immersive.

### 1.3 Glass / Frosted Effects

Use glassmorphism precisely, not everywhere. The rules:

- **Glass cards:** `background: rgba(255, 255, 255, 0.72); backdrop-filter: blur(24px); -webkit-backdrop-filter: blur(24px); border: 1px solid rgba(255, 255, 255, 0.25);`
- **Glass on dark (Screen 4):** `background: rgba(255, 255, 255, 0.08); backdrop-filter: blur(20px); border: 1px solid rgba(255, 255, 255, 0.12);`
- **Maximum 3 glass elements per screen.** Performance degrades with more on mid-range Android devices.
- Every glass element MUST sit over a colorful background (gradient or illustration). Glass on white is invisible and pointless.

### 1.4 Depth Layers

Every screen operates on exactly 4 depth layers:

1. **Background Layer** (z-0): Gradient fill, occupies full hero area
2. **Ambient Layer** (z-1): Large decorative SVG shapes, low opacity (0.08-0.15), no blur
3. **Content Layer** (z-2): Cards, charts, data elements -- these carry the visual payload
4. **Foreground Layer** (z-3): Small floating chips, badges, micro-elements that create parallax feeling

Each layer should have a distinct `box-shadow` or `filter` to reinforce separation. Never flatten two layers into the same visual plane.

---

## 2. Layout Strategy

### The Problem with the Current Layouts

The current screens use "blob in corner + content below" for every screen. This is the single most common pattern in generic onboarding templates. It reads as: "We downloaded a UI kit."

### The New Rule: Each Screen Has a Unique Compositional DNA

No two screens should share the same layout skeleton. Each screen must have a structural signature that is immediately distinguishable even as a blurred thumbnail.

### 2.1 Screen 1 -- Cascading Card Waterfall

**Composition:** Diagonal cascade from upper-right to lower-left.

```
+-----------------------------------+
|  status bar                       |
|                                   |
|              +--[Card 1]--------+ |
|             /    "Chi tieu"     | |
|            /                    | |
|     +--[Card 2]-------+        | |
|    /    "So du"       |         | |
|   /                   |    +----+ |
|  +--[Card 3]----+     |   /      |
|  |  "Tiet kiem"  |    +--/       |
|  +---------------+               |
|                                   |
|  Quan ly                          |
|  chi tieu                         |
|  thong minh.                      |
|                                   |
|  subtitle text here               |
|                                   |
|  [dots]            [FAB ->]       |
+-----------------------------------+
```

**Specifics:**
- Three glass cards arranged in a **staircase pattern**, each offset 40px down and 32px to the left from the previous one
- Cards are **rotated**: Card 1 at `-2deg`, Card 2 at `0deg`, Card 3 at `2deg` -- creating a fan effect
- Each card has a different width: 280px, 240px, 200px -- reinforcing the cascade
- Behind the cards: a single large SVG organic shape (not a circle, not a rectangle -- an amoeba form) filled with `primary-container` at 40% opacity
- The cascade implies motion: things are flowing, being tracked, being organized

**Why this works:** It shows the app's core value (tracking multiple financial streams) through layout alone. The user sees "this app handles complexity gracefully."

### 2.2 Screen 2 -- Split Diagonal Composition

**Composition:** The screen is divided by an invisible diagonal line from lower-left to upper-right. Data above. Explanation below.

```
+-----------------------------------+
|  status bar                       |
|          /                        |
|    [Budget Arc]     /  [Chip]     |
|        65%        /               |
|                 /    [Chip]       |
|    [Chip]     /                   |
|             /                     |
|           /   [Mini bar chart]    |
|         /     |||||| ||||||       |
|       / - - - - - - - - - - - -  |
|                                   |
|  Lap ngan sach                    |
|  thong minh                       |
|                                   |
|  subtitle text                    |
|                                   |
|  [dots]            [FAB ->]       |
+-----------------------------------+
```

**Specifics:**
- The hero area is split by a **diagonal SVG clip-path** (`polygon(0 0, 100% 0, 100% 65%, 0 95%)`) creating two zones
- Upper zone: filled with `tertiary-container` gradient
- The budget visualization is NOT a donut chart. It is a **semicircular arc gauge** (180 degrees) positioned at top-center, with the flat edge facing down. Think car speedometer, not pie chart.
- The arc has **three colored segments** with rounded caps, each segment a different category color
- Below the arc: a **compact horizontal bar chart** (3 bars, horizontal, stacked) showing budget allocation. This replaces the floating chips.
- Category chips are repositioned: they sit on the diagonal boundary line itself, half in one zone, half in the other. This creates visual tension and draws the eye along the diagonal.

**Why this works:** The diagonal split implies dynamism and intelligence. The speedometer arc says "you're in control." The layout is impossible to mistake for a template.

### 2.3 Screen 3 -- Layered Card Stack with Perspective

**Composition:** Three data cards stacked with perspective depth, like a deck of cards fanned toward the viewer.

```
+-----------------------------------+
|  status bar                       |
|                                   |
|  +-------------------------------+|
|  | [Back card - trend line]      ||
|  |   partially visible           ||
|  +---+---------------------------+|
|      |                           ||
|  +---+---------------------------+|
|  | [Middle card - breakdown]     ||
|  |   pie/category visual         ||
|  +---+---------------------------+|
|      |                           ||
|  +---+---------------------------+|
|  | [Front card - savings stat]   ||
|  |   big number + sparkline      ||
|  +-------------------------------+|
|                                   |
|  Phan tich                        |
|  chi tiet                         |
|                                   |
|  [dots]            [FAB ->]       |
+-----------------------------------+
```

**Specifics:**
- Three cards stacked with **3D perspective transforms**: `perspective(1200px)` on the container
- Back card: `translateZ(-60px) translateY(-16px) scale(0.92)` -- visible 30px at top, faded to 60% opacity. Shows a mini sparkline SVG.
- Middle card: `translateZ(-30px) translateY(-8px) scale(0.96)` -- visible 50px. Shows a compact category breakdown (horizontal segmented bar, not a pie chart).
- Front card: `translateZ(0)` -- full visibility. Shows a large savings number with an inline SVG area chart (smooth curve with gradient fill beneath).
- The entire stack has a subtle `rotateX(2deg)` tilt, making it feel like the user is looking down at their financial dashboard.
- Background: the `#006D3B` wave clip-path from the current design is kept but refined -- use `clip-path: path()` with a smooth cubic bezier curve, not an ellipse.

**Why this works:** It communicates depth of insight. Three layers of data = "this app sees what others don't." The perspective creates a sense of physical presence -- these are real documents, not flat graphics.

### 2.4 Screen 4 -- Immersive Radial Composition

**Composition:** Everything radiates from a central focal point. Concentric rings of content.

```
+-----------------------------------+
|  status bar                       |
|                                   |
|        [ring 3 - outer glow]      |
|     [ring 2 - feature chips       |
|        arranged in arc]           |
|                                   |
|        [ring 1 - logo mark]       |
|           [VND symbol]            |
|        [ring 1 completes]         |
|                                   |
|     [ring 2 - more chips]         |
|        [ring 3 fades out]         |
|                                   |
|  San sang kiem soat               |
|  tai chinh cua ban?               |
|                                   |
|  [===== Bat dau ngay =====]       |
|  Da co tai khoan? Dang nhap       |
+-----------------------------------+
```

**Specifics:**
- Background: deep radial gradient (`#006D3B` center to `#0A1F12` edges)
- Center: a **stylized Vietnamese Dong symbol** built from SVG paths, not a rocket icon. Size: 80x80px. Enclosed in a `border-radius: 28px` frosted glass container (120x120px).
- **Three concentric decorative rings** (SVG circles, stroke only, no fill):
  - Inner ring: `r="90px"`, stroke `rgba(255,255,255,0.12)`, stroke-width 1.5px, dashed (`stroke-dasharray: 8 6`)
  - Middle ring: `r="140px"`, stroke `rgba(255,255,255,0.06)`, stroke-width 1px, solid
  - Outer ring: `r="200px"`, stroke `rgba(255,255,255,0.03)`, stroke-width 1px, solid
- Feature chips are **positioned along the middle ring's circumference** using `transform: rotate(Xdeg) translateY(-140px) rotate(-Xdeg)` -- they sit on the orbit, evenly spaced at 45-degree intervals around the top half
- The bottom 40% of the screen is text + CTA on dark background. No visual elements -- let the typography breathe.

**Why this works:** Radial composition creates a gravitational center. The user's eye is pulled to the symbol of the app. The orbiting chips feel like a solar system of features. It is aspirational and confident.

---

## 3. Illustration Approach: Inline SVG Only

### The Constraint
No icon fonts. No external images. No PNGs. No CDN-hosted illustrations. Everything must be inline SVG that ships with the HTML/component code. This ensures zero network dependency, instant rendering, and pixel-perfect scaling.

### What to Build

#### 3.1 Abstract Financial Illustrations (per screen)

**Screen 1 -- "Flow" Illustration**
A set of 3-4 curved SVG paths that flow from upper-right to lower-left, passing through the card cascade. These paths represent money flow.

```svg
<svg viewBox="0 0 393 520" fill="none">
  <!-- Primary flow line -->
  <path d="M393 80 C 300 120, 200 100, 160 200 S 80 350, 20 520"
        stroke="url(#flowGradient)" stroke-width="2" stroke-opacity="0.15"/>
  <!-- Secondary flow line, offset -->
  <path d="M393 120 C 280 160, 220 140, 180 240 S 100 380, 40 520"
        stroke="url(#flowGradient)" stroke-width="1.5" stroke-opacity="0.08"/>
  <defs>
    <linearGradient id="flowGradient" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#006D3B"/>
      <stop offset="100%" stop-color="#3A6470"/>
    </linearGradient>
  </defs>
</svg>
```

These lines should be smooth cubic bezier curves, not straight. They create a sense of continuous tracking.

**Screen 2 -- "Allocation" Illustration**
An abstract representation of budget segments. NOT a pie chart. Instead: a set of **horizontal bands** of varying thickness and color that flow across the diagonal split, bending slightly as if being sorted by an invisible force.

Build with 4-5 `<rect>` elements with large `rx` values (fully rounded ends), rotated at the same angle as the diagonal split, with varying widths and `primary`, `tertiary`, and `category-shopping` fills at 20-40% opacity.

**Screen 3 -- "Pulse" Illustration**
Behind the card stack, a subtle **heartbeat/pulse line** SVG that suggests living, breathing data.

```svg
<svg viewBox="0 0 393 200" fill="none">
  <path d="M0 100 L80 100 L100 40 L120 160 L140 80 L160 120 L180 100 L393 100"
        stroke="#7ED998" stroke-width="2" stroke-opacity="0.12"
        stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

This sits at z-1 (ambient layer), barely visible but subconsciously communicating "data is alive."

**Screen 4 -- "Constellation" Illustration**
Small SVG dots (3-5px circles) scattered across the dark background, connected by thin lines (0.5px stroke), forming an abstract constellation pattern. Think: data points connected, insights discovered.

Use 12-15 `<circle>` elements with `fill="rgba(255,255,255,0.15)"` and `<line>` connections with `stroke="rgba(255,255,255,0.04)"`. Position them to avoid the center zone (occupied by the logo).

#### 3.2 Inline SVG Icon Construction Rules

For all functional icons within onboarding cards and chips:

- **Size:** 24x24px viewBox, rendered at 20-24px
- **Style:** Rounded line style, stroke-width 2px, stroke-linecap round. NOT filled Material icons.
- **Color:** Use `currentColor` so they inherit from parent
- **Complexity:** Maximum 3 path elements per icon. If it needs more, the icon is too complex for onboarding.

**Icons to build from scratch (inline SVG, no symbol references):**
1. Wallet: simple rectangle with a horizontal line and small circle
2. Chart-up: three ascending bars with a curved arrow overlay
3. Shield-check: rounded shield outline with a checkmark path
4. Lightning: simple zigzag bolt
5. Calendar-clock: circle with two clock hands and a small calendar corner
6. Vietnamese Dong sign: custom typographic VND symbol

Do NOT use the current `<symbol>` + `<use href>` pattern. It adds complexity without benefit for 4 static screens. Inline the paths directly.

---

## 4. Typography Hierarchy

### The Problem
The current headlines are all `32px / 700 weight`. Every screen screams at the same volume. There is no crescendo.

### The New Approach: Progressive Emphasis

Each screen's headline should be slightly different in treatment, building toward the final screen.

#### Screen 1 -- Understated Confidence
```css
.screen-1 h1 {
  font-size: 36px;
  font-weight: 400;        /* Light weight -- unexpected */
  line-height: 1.15;
  color: var(--md-sys-color-on-surface);
  letter-spacing: -0.5px;
}
.screen-1 h1 strong {
  font-weight: 700;
  color: var(--md-sys-color-primary);
}
```
The headline mixes weights. "Quan ly" in regular weight, "chi tieu" in bold + primary color. This creates a reading rhythm: soft-PUNCH-soft.

#### Screen 2 -- Technical Precision
```css
.screen-2 h1 {
  font-size: 34px;
  font-weight: 700;
  line-height: 1.15;
  color: var(--md-sys-color-on-surface);
}
.screen-2 h1 em {
  font-style: normal;
  color: var(--md-sys-color-tertiary);
  font-weight: 500;        /* Lighter accent word */
}
```
The accent word is tertiary color and lighter weight -- it suggests "smartness" without shouting.

#### Screen 3 -- Data Authority
```css
.screen-3 h1 {
  font-size: 38px;         /* Slightly bigger */
  font-weight: 700;
  line-height: 1.1;
  color: var(--md-sys-color-on-surface);
}
.screen-3 h1 span.accent {
  display: block;
  font-size: 28px;         /* Size contrast within headline */
  font-weight: 500;
  color: var(--md-sys-color-primary);
  margin-top: 4px;
}
```
A two-size headline: the main statement is large, the qualifier is smaller. Creates visual hierarchy within the headline itself.

#### Screen 4 -- Maximum Impact
```css
.screen-4 h1 {
  font-size: 42px;         /* Largest */
  font-weight: 700;
  line-height: 1.05;
  color: #FFFFFF;
  letter-spacing: -1px;    /* Tight tracking = premium */
}
```
Pure white, tightest tracking, largest size. The crescendo peak. No color tricks needed -- the dark background does the work.

#### Subtitle Treatment (All Screens)
```css
.screen p.subtitle {
  font-size: 16px;
  font-weight: 400;
  line-height: 1.6;           /* Generous line height */
  color: var(--md-sys-color-on-surface-variant);
  max-width: 300px;            /* Never full width */
  letter-spacing: 0.15px;
}
```

#### Font Choice
Keep **Inter** (currently used) or switch to **Be Vietnam Pro** for Vietnamese diacritical mark optimization. Be Vietnam Pro was designed specifically for Vietnamese text rendering and handles marks like `ả`, `ễ`, `ữ` with correct vertical spacing that Inter sometimes clips.

**Recommendation: Use Be Vietnam Pro.** Import weights 400, 500, 700 only.

```html
<link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:wght@400;500;700&display=swap" rel="stylesheet">
```

---

## 5. Micro-interaction Implications in Static Frames

Even though these are static onboarding screens (swiped horizontally), the **static layout should imply motion**. Here is how:

### 5.1 Staggered Element Positioning

On Screen 1, the three cascade cards should not be perfectly aligned to a grid. Instead:
- Card 1: exactly at its position
- Card 2: offset 2px extra to the left (beyond the expected 32px step)
- Card 3: offset 4px extra to the left

This irregularity implies they "just arrived" and haven't settled into place. When animated, they will stagger in with 80ms delays between cards.

### 5.2 Rotation for Implied Dynamism

- Screen 1 cards: `-2deg`, `0deg`, `+2deg` rotation
- Screen 2 category chips: each rotated `1-2deg` differently
- Screen 3 back card: `1deg` clockwise tilt
- Screen 4 feature chips: follow the ring's curvature

**Rule:** Nothing should be at exactly `0deg` if it's a floating element. Only grounded elements (text, CTAs) are perfectly horizontal.

### 5.3 Scale Variation for Depth

Elements farther from the "focal point" of each screen should be scaled down:
- Screen 1: Card 3 (farthest in cascade) at `scale(0.95)`
- Screen 3: Back card at `scale(0.92)`, middle at `scale(0.96)`
- Screen 4: Outer ring chips at `scale(0.9)` compared to inner ring chips

### 5.4 Opacity Gradients

Create atmospheric depth:
- Elements at the edges of the screen: `opacity: 0.6-0.8`
- Elements at the focal center: `opacity: 1.0`
- Decorative SVG background elements: `opacity: 0.08-0.20` -- never higher

### 5.5 Shadow Direction Consistency

All shadows on all screens point in the same direction: **down and slightly right**. This implies a single, consistent light source at the upper-left. Specific values:
- Floating cards: `box-shadow: 4px 8px 24px rgba(0, 0, 0, 0.08)`
- Elevated buttons: `box-shadow: 2px 4px 12px rgba(0, 109, 59, 0.25)`
- Glass elements: `box-shadow: 0px 2px 8px rgba(0, 0, 0, 0.04)` (softer, because glass diffuses light)

### 5.6 Animation Specifications (for when motion is implemented)

| Element | Entry | Duration | Delay | Easing |
|---------|-------|----------|-------|--------|
| Background gradient | Fade in | 600ms | 0ms | `ease-out` |
| Ambient SVG shapes | Scale 0.8 to 1.0 + fade | 800ms | 100ms | `cubic-bezier(0.05, 0.7, 0.1, 1)` |
| Content cards | Slide up 40px + fade | 500ms | 200ms | `cubic-bezier(0.2, 0, 0, 1)` |
| Card 2 | Same as above | 500ms | 280ms | Same |
| Card 3 | Same as above | 500ms | 360ms | Same |
| Headline | Slide up 24px + fade | 400ms | 400ms | Same |
| Subtitle | Fade in | 300ms | 500ms | `ease-out` |
| Dots + CTA | Fade in | 300ms | 550ms | `ease-out` |

Use the M3 motion tokens already in the design system: `--md-sys-motion-easing-emphasized-decelerate` for entries.

---

## 6. Screen-by-Screen Specification

### Screen 1: Welcome -- "First Impression"

**Emotional goal:** "This app is beautiful AND useful. I trust it immediately."

**Layout:** Cascading Card Waterfall (see Section 2.1)

**Hero Area (top 58% of screen):**
- Background: Radial gradient (#9AF6B2 at 70% opacity, centered at 75% 25%, fading to transparent)
- Ambient layer: Two organic SVG blob shapes. One large (300x340px) at upper-right, filled `primary-container` at 15% opacity, with `border-radius: 30% 70% 70% 30% / 30% 30% 70% 70%`. One small (120x120px) at mid-left, filled `tertiary-container` at 10% opacity.
- Flow lines SVG behind cards (see Section 3.1)
- Three glass cards in cascade:

**Card 1 (top of cascade):**
- Position: `right: 16px; top: 72px;`
- Size: `width: 280px; height: 80px;`
- Rotation: `rotate(-2deg)`
- Content: Wallet icon (inline SVG, 20x20, stroke `#006D3B`) + "Chi tieu hom nay" (label-medium) + "-350.000d" (title-large, weight 700, color `primary`)
- Glass treatment: yes

**Card 2 (middle of cascade):**
- Position: `right: 48px; top: 164px;`
- Size: `width: 240px; height: 72px;`
- Rotation: `rotate(0deg)`
- Content: Chart-up icon + "So du" (label-medium) + "12.500.000d" (title-large, weight 700, color `tertiary`)
- Glass treatment: yes

**Card 3 (bottom of cascade):**
- Position: `right: 80px; top: 248px;`
- Size: `width: 200px; height: 68px;`
- Rotation: `rotate(2deg)`
- Scale: `scale(0.95)`
- Content: Shield-check icon + "Tiet kiem" (label-medium) + "6.500.000d" (title-medium, weight 600, color `primary`)
- Glass treatment: yes, slightly more transparent (0.65 background alpha)

**Content Area (bottom 42% of screen):**
- Padding: `32px` left/right, `24px` top
- Headline: "Quan ly" (36px, weight 400, on-surface) + line break + "**chi tieu**" (36px, weight 700, primary) + line break + "thong minh." (36px, weight 400, on-surface)
- Subtitle: "Theo doi moi khoan thu chi de dang, moi luc moi noi." (16px, on-surface-variant, max-width 300px)
- Gap between headline and subtitle: 16px

**Bottom Bar:**
- Page dots: 4 dots. Active dot is `24px` wide with `primary` fill and `border-radius: full`. Inactive dots are `8px` circles with `outline-variant` fill.
- Skip button: left-aligned, "Bo qua", label-large, `on-surface-variant`
- FAB: right-aligned, 56x56px, `primary` fill, `corner-large` (16px) radius, contains arrow-forward SVG icon in white. Shadow: `2px 6px 16px rgba(0, 109, 59, 0.3)`

---

### Screen 2: Smart Budgeting -- "Intelligence on Display"

**Emotional goal:** "This app thinks for me. It's not just logging -- it's strategizing."

**Layout:** Split Diagonal Composition (see Section 2.2)

**Hero Area (top 55% of screen):**
- Background: Diagonal split via SVG clip-path. Upper zone: linear gradient 135deg from `#BDE9F7` to `#E9EBE6`. Lower zone: `surface`.
- The split line runs from `(0, 88%)` to `(100%, 42%)` of the hero area.

**Semicircular Arc Gauge:**
- Position: centered horizontally, `top: 56px`
- Size: 220px wide, 110px tall (half circle)
- Built with SVG `<path>` arcs, NOT circles:

```svg
<svg viewBox="0 0 220 120" width="220" height="120">
  <!-- Track -->
  <path d="M 15 110 A 95 95 0 0 1 205 110"
        fill="none" stroke="#E3E5E1" stroke-width="14" stroke-linecap="round"/>
  <!-- Segment 1: Thiet yeu (tertiary) -->
  <path d="M 15 110 A 95 95 0 0 1 70 22"
        fill="none" stroke="#3A6470" stroke-width="14" stroke-linecap="round"/>
  <!-- Segment 2: An uong (primary) -->
  <path d="M 74 20 A 95 95 0 0 1 160 30"
        fill="none" stroke="#006D3B" stroke-width="14" stroke-linecap="round"/>
  <!-- Segment 3: Mua sam (shopping) -->
  <path d="M 164 32 A 95 95 0 0 1 195 80"
        fill="none" stroke="#7D5260" stroke-width="14" stroke-linecap="round"/>
</svg>
```

- Center text (below the arc): "65%" in headline-large (32px, 700 weight, on-surface) + "da su dung" in label-small

**Budget Allocation Bars (below arc):**
- Three horizontal bars, full width of hero minus 48px padding
- Each bar: `height: 32px`, `border-radius: full`, with an icon (16x16) and label inside
- Bar 1: "An uong" -- `width: 55%`, primary fill
- Bar 2: "Di chuyen" -- `width: 25%`, tertiary fill
- Bar 3: "Mua sam" -- `width: 20%`, category-shopping fill
- Bars are stacked vertically with 8px gap

**Floating Category Chips (on the diagonal boundary):**
- 3 chips positioned along the diagonal line
- Each chip: glass card treatment, `border-radius: full`, `padding: 8px 16px`
- Each contains a small colored dot (8px) + category name + amount
- Chips are rotated 1-3 degrees to follow the diagonal angle

**Content Area:**
- Headline: "Lap ngan sach" (34px, 700, on-surface) + line break + "*thong minh*" (34px, 500, tertiary)
- Subtitle: "Tu dong phan bo chi tieu, canh bao khi gan vuot ngan sach." (16px)

**Bottom Bar:** Same pattern as Screen 1, dot 2 active.

---

### Screen 3: Insights -- "Data That Breathes"

**Emotional goal:** "I can actually *see* my financial future here. This isn't just numbers."

**Layout:** Layered Card Stack with Perspective (see Section 2.3)

**Hero Area (top 58% of screen):**
- Background: Multi-stop gradient. `#004D29` at top -> `#006D3B` at 35% -> `#FBFDF8` at 58%. The transition zone is where the front card sits, creating a natural bridge between dark and light.
- Status bar text: white (because background is dark at top)

**Pulse line SVG (ambient layer):**
- Full-width, positioned at `top: 60px`, `height: 80px`
- Heartbeat/ECG style path, `stroke: rgba(126, 217, 152, 0.15)`, `stroke-width: 2`
- Sits behind all cards

**Card Stack:**
- Container: `perspective: 1200px; perspective-origin: 50% 40%;`
- All cards have `border-radius: 24px` and consistent left/right margins of `20px`

**Back Card (partially visible, top 40px showing):**
- `transform: translateZ(-60px) translateY(0) scale(0.92); opacity: 0.5;`
- Position: `top: 80px`
- Content visible: a thin sparkline SVG (mini trend graph) + "Thu nhap 6 thang" label
- Background: white, `box-shadow: 0 4px 16px rgba(0,0,0,0.06)`

**Middle Card (60% visible):**
- `transform: translateZ(-30px) translateY(12px) scale(0.96); opacity: 0.8;`
- Position: `top: 104px`
- Content visible: a **horizontal segmented bar** (one bar, divided into 4 colored segments proportionally) representing spending breakdown + category legend below it
- Background: white

**Front Card (fully visible):**
- `transform: translateZ(0) translateY(24px); opacity: 1;`
- Position: `top: 128px`
- Size: full width minus 40px padding, `height: 220px`
- Content:
  - Header row: "Tong quan" (title-medium, 600 weight) + "Thang 3" chip (label-medium, `surface-container` bg, `corner-full`)
  - **Area chart SVG** (not bar chart):

```svg
<svg viewBox="0 0 300 120" width="100%" height="120" preserveAspectRatio="none">
  <defs>
    <linearGradient id="areaFill" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#006D3B" stop-opacity="0.25"/>
      <stop offset="100%" stop-color="#006D3B" stop-opacity="0.02"/>
    </linearGradient>
  </defs>
  <!-- Area fill -->
  <path d="M0 90 C30 80, 50 40, 80 55 S120 20, 160 35 S200 50, 240 25 S270 30, 300 15 L300 120 L0 120 Z"
        fill="url(#areaFill)"/>
  <!-- Line -->
  <path d="M0 90 C30 80, 50 40, 80 55 S120 20, 160 35 S200 50, 240 25 S270 30, 300 15"
        fill="none" stroke="#006D3B" stroke-width="2.5" stroke-linecap="round"/>
  <!-- Current point indicator -->
  <circle cx="300" cy="15" r="5" fill="#006D3B"/>
  <circle cx="300" cy="15" r="8" fill="#006D3B" opacity="0.2"/>
</svg>
```

  - Stat row below chart: three mini stat blocks in a row
    - "Thu nhap: 15.2M" with up-arrow in `primary`
    - "Chi tieu: 8.7M" with down-arrow in `error`
    - "Tiet kiem: 6.5M" with up-arrow in `primary`
  - Each stat: label (label-small, on-surface-variant) + value (title-small, 600 weight, on-surface) + change badge (label-small, colored)

**Content Area:**
- Headline: "Phan tich" (38px, 700, on-surface) + line break + "chi tiet" (28px, 500, primary)
- Subtitle: "Bieu do truc quan giup ban hieu ro xu huong chi tieu." (16px)

**Bottom Bar:** Same pattern, dot 3 active.

---

### Screen 4: Get Started -- "The Close"

**Emotional goal:** "I'm ready. This app is exactly what I need. Let me in."

**Layout:** Immersive Radial Composition (see Section 2.4)

**Full-screen dark treatment:**
- Background: radial gradient from `#006D3B` (center, 40% of radius) to `#0A1F12` (edges)
- Status bar text: white

**Constellation SVG (ambient layer):**
- 12-15 small dots and connecting lines (see Section 3.1 Screen 4 spec)
- Positioned to frame the center but avoid cluttering it
- Total SVG opacity: 0.12 -- barely visible, subconsciously atmospheric

**Concentric Rings:**
- All three rings centered at `(50%, 38%)` of the screen
- Inner ring (r=90px): `stroke: rgba(255,255,255,0.12); stroke-dasharray: 8 6;`
- Middle ring (r=140px): `stroke: rgba(255,255,255,0.06);`
- Outer ring (r=200px): `stroke: rgba(255,255,255,0.03);`

**Center Element:**
- Glass container: 120x120px, `border-radius: 28px`, `background: rgba(255,255,255,0.1)`, `backdrop-filter: blur(20px)`, `border: 1px solid rgba(255,255,255,0.15)`
- Inside: Custom SVG Vietnamese Dong symbol, 56x56px, `fill: white`

```svg
<svg viewBox="0 0 56 56" width="56" height="56">
  <text x="28" y="40" text-anchor="middle" font-family="'Be Vietnam Pro', sans-serif"
        font-size="36" font-weight="700" fill="white">d</text>
  <line x1="8" y1="18" x2="48" y2="18" stroke="white" stroke-width="2.5" stroke-linecap="round"/>
  <line x1="12" y1="10" x2="44" y2="10" stroke="white" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
</svg>
```

Or better -- a custom abstract mark combining a shield shape with a growth arrow, representing "protected growth."

**Feature Chips on Ring Orbit:**
- 5 chips positioned along the middle ring's upper arc (from 200deg to 340deg, every 35deg)
- Each chip: `background: rgba(255,255,255,0.08)`, `backdrop-filter: blur(12px)`, `border: 1px solid rgba(255,255,255,0.1)`, `border-radius: full`, `padding: 8px 16px`
- Content: small inline SVG icon (16x16, stroke white) + feature name (label-medium, `rgba(255,255,255,0.85)`)
- Features: "Ghi nhanh", "Ngan sach", "Bao cao", "Nhac nho", "Dong bo"
- Each chip has slight rotation to follow the ring curvature

**Content Area (bottom 38%):**
- Headline: "San sang" + line break + "kiem soat tai chinh?" (42px, 700, white, letter-spacing: -1px)
- Subtitle: "Bat dau hanh trinh quan ly chi tieu thong minh." (16px, `rgba(255,255,255,0.65)`)
- Gap: 16px between headline and subtitle

**CTA Section:**
- Primary button: full width, `height: 56px`, `border-radius: full`, `background: white`, `color: #006D3B`
  - Text: "Bat dau ngay" (label-large, 600 weight) + arrow-forward icon (20x20, `#006D3B`)
  - Shadow: `0 4px 20px rgba(0, 0, 0, 0.25)`
  - On the white button, add a subtle gradient: `linear-gradient(135deg, #FFFFFF 0%, #F0F7F2 100%)` -- this gives it a slight green tint that connects it to the brand.
- Secondary link: "Da co tai khoan? Dang nhap" (label-large, 500 weight, `rgba(255,255,255,0.7)`)
- Gap between button and link: 16px

**No page dots on this screen.** The conversion CTA replaces them. The user should feel they've arrived, not that they're still navigating.

---

## 7. Anti-Patterns to Avoid

These are the specific things that make the current screens -- and most fintech onboarding -- look cheap. Do not do any of these:

### 7.1 The Blob Background
**What it is:** A single large colored shape (`border-radius: 0 0 0 200px` or similar) placed in one corner of the hero area.
**Why it's bad:** It's the default of every UI kit on Dribbble since 2020. It communicates zero effort.
**What to do instead:** Use multi-shape compositions, gradient transitions, or clip-path geometries.

### 7.2 The Lonely Donut Chart
**What it is:** A single SVG circle with `stroke-dasharray` used as the sole visual on the budget screen.
**Why it's bad:** It's the most basic data visualization possible. It says "I know SVG exists" rather than "I understand your finances."
**What to do instead:** Semicircular gauge with segmented arcs + horizontal allocation bars + category chips. Layer three visualization types.

### 7.3 The Flat Bar Chart
**What it is:** Simple `<div>` bars of varying height lined up in a row.
**Why it's bad:** It looks like a tutorial project, not a shipped product. No chart in a premium finance app is just bars.
**What to do instead:** Area charts with gradient fills, smooth curves (`bezier` paths), animated data points, and contextual labels.

### 7.4 Generic Geometric Shapes on Dark Backgrounds
**What it is:** Random circles, squares, and organic blobs at low opacity floating on the CTA screen.
**Why it's bad:** It's decorative noise. It doesn't communicate anything about the product.
**What to do instead:** Purposeful geometric systems (concentric rings = focus, constellation dots = connection, orbital paths = features revolving around a core value).

### 7.5 Same-Weight Headlines
**What it is:** Every headline at `32px / 700 weight / black`. Every screen shouts equally.
**Why it's bad:** There's no narrative arc. Screen 1 should whisper-PUNCH. Screen 4 should be full authority.
**What to do instead:** Progressive emphasis (see Section 4). Vary size, weight, color accent, and letter-spacing across screens.

### 7.6 Material Icons as Illustration Substitutes
**What it is:** Using a single 72px Material icon (like the piggy bank on Screen 1 currently) as the hero illustration.
**Why it's bad:** Icons are meant for 24px. Scaling them to 72px reveals their simplicity. They're too thin, too generic, too clipart-like.
**What to do instead:** Build abstract compositions from multiple SVG elements. A "savings" visual should be a multi-element illustration (shield + arrow + chart line), not a blown-up piggy bank icon.

### 7.7 Inconsistent Spacing and Alignment
**What it is:** Content areas with inconsistent padding, dots and buttons at slightly different positions between screens.
**Why it's bad:** It subconsciously communicates "this was built piecemeal."
**What to do instead:** Lock these values:
- Content section horizontal padding: `32px`, always
- Bottom section: `position: absolute; bottom: 0; left: 0; right: 0; padding: 0 24px 48px;`, always
- Dots: `margin-bottom: 24px; padding-left: 8px;`, always
- Gap between headline and subtitle: `16px`, always
- Headline baseline to top of content area: `24px`, always

### 7.8 White-on-White Cards
**What it is:** White cards sitting on a white or near-white background (the current Screen 1 illustration circle, Screen 2 chips).
**Why it's bad:** Without sufficient contrast between the card and its background, the card loses its "floating" quality and just looks like a bordered rectangle.
**What to do instead:** Every card must sit over a colored/gradient zone. If the background is white, add a tinted surface (`surface-container` at minimum) behind the card cluster. The glass effect requires a visible background to diffuse.

---

## 8. Implementation Notes

### File Structure
```
rebuild/
  onboarding.html          # All 4 screens, self-contained
  design-brief.md          # This document
```

### Technical Constraints
- **Single HTML file** with inline CSS and inline SVGs
- **No external dependencies** except Google Fonts (Be Vietnam Pro)
- **No JavaScript** for visual rendering (JS only for font loading and potential swipe gesture later)
- **393 x 852px** phone frame (iPhone 14/15 viewport)
- All SVG must use `viewBox` for scaling, never fixed `width`/`height` on the `<svg>` element without viewBox
- Test on Chrome, Safari, and Samsung Internet (the three browsers that cover 90%+ of Vietnamese mobile users)

### Performance Budget
- Total HTML file size: under 50KB (including all inline SVGs and CSS)
- Maximum 3 `backdrop-filter: blur()` elements visible at any time
- No CSS `filter` on elements larger than 200x200px
- All SVG paths should be simplified (maximum 20 control points per path)

### Accessibility
- All decorative SVGs: `aria-hidden="true"` and `role="presentation"`
- Minimum contrast ratio 4.5:1 for body text, 3:1 for large text (18px+ bold or 24px+ regular)
- Page dots must have `aria-label="Trang X trong 4"`
- Skip button and FAB must be keyboard-focusable with visible focus ring
- Glass card text must remain readable without `backdrop-filter` (provide solid color fallback)

---

## 9. Quality Checklist

Before considering any screen "done," verify:

- [ ] Can you identify which screen it is from a 50px-tall thumbnail? (Structural uniqueness)
- [ ] Does the hero area use at least 3 depth layers?
- [ ] Is every floating element at a non-zero rotation?
- [ ] Are headlines using mixed weights or sizes within the line?
- [ ] Are all data visualizations more complex than a single chart type?
- [ ] Do all glass elements sit over colored backgrounds?
- [ ] Is the total SVG path count under 80 per screen?
- [ ] Does the screen work without `backdrop-filter`? (Fallback check)
- [ ] Is Vietnamese text rendering cleanly with all diacritical marks?
- [ ] Does the screen feel premium when placed next to Revolut/N26 screenshots?

---

*End of creative brief. Build it exactly as specified. When in doubt, choose the option that looks less like a template and more like a product that cost $2M to design.*
