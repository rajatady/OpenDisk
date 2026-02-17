# OpenDisk Design System

> The single source of truth for visual design, interaction patterns, and component usage in OpenDisk.
> Follow this document when building new features, modifying existing views, or reviewing pull requests.

---

## Table of Contents

1. [Philosophy](#philosophy)
2. [Color Tokens](#color-tokens)
3. [Typography](#typography)
4. [Spacing & Radii](#spacing--radii)
5. [Glass & Materials](#glass--materials)
6. [Shadows](#shadows)
7. [Animation & Motion](#animation--motion)
8. [Components](#components)
9. [Layout Patterns](#layout-patterns)
10. [Interaction Patterns](#interaction-patterns)
11. [View Architecture](#view-architecture)
12. [Accessibility](#accessibility)
13. [Rules & Constraints](#rules--constraints)
14. [Adding New Features](#adding-new-features)

---

## Philosophy

OpenDisk's visual design follows three principles:

1. **Native-first.** The app should feel like it belongs on macOS. We use system materials, SF Symbols, and platform conventions. No custom icon packs, no web-style UI patterns.

2. **Depth through materials, not decoration.** Visual hierarchy comes from layered glass surfaces, shadows, and subtle highlights — not borders, dividers, or color blocks. Every surface has physical plausibility: glass refracts light at its top edge, shadows grow when elements lift on hover, and objects scale when pressed.

3. **Motion communicates state.** Animations are never decorative. A staggered entrance tells you the list just loaded. A breathing pulse tells you something needs attention. A sliding pill indicator tells you where you are in the sidebar. If removing an animation would lose information, it belongs.

---

## Color Tokens

All colors live in `ODColors` (`DesignTokens.swift`). Every color is dynamic — it adapts to light and dark appearance automatically.

### Canvas (background layer)

| Token | Purpose |
|---|---|
| `canvasTop` / `canvasBottom` | Full-window gradient endpoints |
| `canvasGlow` | Blue radial glow, top-right |
| `canvasAmberGlow` | Warm amber radial glow, bottom-left |
| `canvasMintGlow` | Mint radial glow, mid-bottom area |

The canvas is applied via `.odCanvasBackground()`. It creates a rich, living background with three overlapping radial gradients on top of a linear gradient. Every full-screen content view uses this.

### Glass surfaces

| Token | Opacity (light / dark) | Use |
|---|---|---|
| `glass` | 55% / 58% | Standard card surfaces |
| `glassStrong` | 75% / 78% | Elevated panels, modals |
| `glassThin` | 35% / 40% | Sidebar, inset containers |
| `glassBorder` | 55% / 18% | Primary panel borders |
| `glassBorderSubtle` | 30% / 10% | Secondary/inner borders |
| `glassHighlight` | 80% / 12% | 1px top-edge refraction line |
| `insetSurface` | 50% / 62% | Inner surface fills (cards, inputs) |
| `insetSurfaceSelected` | tinted blue | Selected state surface |

### Semantic colors

| Token | Hex (approx) | Use |
|---|---|---|
| `accent` | `#1580F0` | Primary actions, selection, links |
| `accentSecondary` | `#03B8E0` | Gradient companion to accent |
| `safe` | green | Safe operations, authorized states |
| `review` | amber | Needs review, warnings |
| `risky` | red | Dangerous operations, errors |

The **safe/review/risky** trio is the only semantic color system. No one-off custom colors for state. If something needs a status color, it maps to one of these three.

### Shadows

| Token | Use |
|---|---|
| `shadow` | Standard card shadows |
| `shadowDeep` | Elevated/modal shadows |
| `shadowSubtle` | Tight inset shadows |
| `hoverOverlay` | Faint overlay for hover states |

### Using colors

Never use `Color(red:green:blue:)` or `Color("name")` in feature views. Always reference `ODColors.*` or use the typed `ODColorToken` enum with `.odForeground()`.

```swift
// Correct
Text("Hello").odTextStyle(.body, color: .textSecondary)
Image(systemName: "star").odForeground(.accent)

// Wrong — will fail the compliance test
Text("Hello").foregroundStyle(Color(red: 0.5, green: 0.5, blue: 0.5))
```

---

## Typography

All fonts live in `ODTypography` (`DesignTokens.swift`). The design uses `.rounded` for all text and platform-default weight for icons.

### Text fonts

| Token | Size | Weight | Design |
|---|---|---|---|
| `display` | 38pt | bold | rounded |
| `title` | 22pt | semibold | rounded |
| `heading` | 16pt | semibold | rounded |
| `body` | 13pt | regular | rounded |
| `caption` | 11pt | medium | rounded |
| `mono` | 11pt | regular | monospaced |

### Icon fonts

| Token | Size | Weight | Typical use |
|---|---|---|---|
| `iconHero` | 44pt | light | Welcome screen app icon |
| `iconLarge` | 24pt | medium | Step header icons (onboarding) |
| `iconMedium` | 18pt | medium | Sheet header icons |
| `iconDefault` | 16pt | semibold | Sidebar app logo, section icons |
| `iconBody` | 14pt | medium | Feature row icons |
| `iconSmall` | 12pt | semibold | List row icons, artifact icons |
| `iconCaption` | 10pt | medium | Meta row icons |
| `iconTiny` | 9pt | medium | Status footer icons |
| `iconCheckmark` | 20pt | default | Selection checkmarks |

### Using typography

Never use `.font(.system(size:))` in feature views. Use the modifier API:

```swift
// For text
Text("Title").odTextStyle(.title)
Text("Subtitle").odTextStyle(.body, color: .textSecondary)

// For icons
Image(systemName: "star.fill").odIcon(.small)
```

For display titles with gradient text (hero banners only):

```swift
Text("Disk Command Center")
    .odTextStyle(.display)
    .foregroundStyle(
        LinearGradient(
            colors: [ODColors.textPrimary, ODColors.textPrimary.opacity(0.7)],
            startPoint: .leading,
            endPoint: .trailing
        )
    )
```

---

## Spacing & Radii

### Spacing (`ODSpacing`)

| Token | Value | Use |
|---|---|---|
| `xs` | 4pt | Tight inline gaps |
| `sm` | 8pt | Related element spacing |
| `md` | 12pt | Standard content spacing |
| `lg` | 20pt | Section-level spacing, card padding |
| `xl` | 28pt | Elevated panel padding |
| `xxl` | 36pt | Page-level outer padding |

### Corner radii (`ODRadius`)

| Token | Value | Use |
|---|---|---|
| `sm` | 8pt | Buttons, small badges, input fields |
| `md` | 14pt | Cards, inset surfaces |
| `lg` | 20pt | Standard glass panels |
| `xl` | 28pt | Elevated panels, hero panels |

---

## Glass & Materials

Glass is the primary surface material. There are four tiers, each mapping to an `ODMaterial` case and a `GlassPanel.Style`:

| Material | Style | Blur | Tint opacity | NSVisualEffectView fallback |
|---|---|---|---|---|
| `thinGlass` | `.inset` | 20pt | 3% accent | `.headerView` |
| `regularGlass` | `.card` | 30pt | 6% accent | `.hudWindow` |
| `thickGlass` | `.elevated` / `.hero` | 50pt | 10% accent | `.fullScreenUI` |
| `sidebarGlass` | (sidebar only) | 25pt | 4% accent | `.sidebar` |

On macOS 26+, glass surfaces use `NSGlassEffectView`. On macOS 14-15, they fall back to `NSVisualEffectView` with equivalent materials.

### Glass anatomy

Every `GlassPanel` renders four layers:

1. **Glass background** — `NativeGlassSurface` (AppKit bridge) clipped to rounded rect
2. **Top-edge highlight** — 1px `LinearGradient` from `glassHighlight` to clear, simulating light refraction
3. **Border** — `glassBorder` or `glassBorderSubtle` stroke
4. **Shadow** — Preset from `ODShadow` matching the panel style

```swift
// Standard card
GlassPanel {
    Text("Content")
}

// Elevated panel (onboarding steps, modals)
GlassPanel(style: .elevated) {
    Text("Content")
}

// Hero banner (top of feature views)
GlassPanel(style: .hero) {
    Text("Content")
}
```

---

## Shadows

Shadows use the `ODShadow` preset system. Never use raw `.shadow()` with arbitrary values.

| Preset | Radius | Y offset | Color | Use |
|---|---|---|---|---|
| `subtle` | 4pt | 2pt | `shadowSubtle` | Inset elements, app icons |
| `card` | 16pt | 8pt | `shadow` | Standard glass panels |
| `elevated` | 28pt | 16pt | `shadowDeep` | Modals, hero panels |
| `glow(color)` | 20pt | 4pt | color @ 35% | Accent glow on hover (buttons, cards) |

```swift
// Apply a preset
someView.odShadow(ODShadow.card)

// Colored glow (e.g., on a button hover)
.shadow(color: ODColors.accent.opacity(0.35), radius: 12, y: 4)
```

---

## Animation & Motion

All animations use `ODAnimation` tokens. Never use raw `Animation.spring(...)` or `.easeInOut(...)` in feature views.

### Token reference

| Token | Config | Use |
|---|---|---|
| `snappy` | spring(0.3, 0.7) | Selection changes, toggles, hover states |
| `smooth` | spring(0.5, 0.8) | Value transitions, number ticks |
| `bouncy` | spring(0.4, 0.6) | Permission status changes, playful feedback |
| `microInteraction` | spring(0.15, 0.8) | Hover background, tiny state changes |
| `pageTransition` | spring(0.45, 0.82) | Tab switches, onboarding steps, route changes |
| `breathe` | easeInOut(1.8s), repeat | Attention pulse (denied state, indeterminate loading) |
| `staggerDelay(index:)` | spring(0.4, 0.78) + 0.05s * index | List entrance animations |

### Motion patterns

**Page transitions** use asymmetric transitions — insertion reveals from the natural direction, removal is simpler:

```swift
// Sidebar section switch (vertical reveal)
.transition(.asymmetric(
    insertion: .opacity.combined(with: .offset(x: 0, y: 8)),
    removal: .opacity
))
.animation(ODAnimation.pageTransition, value: selectedSection)

// Onboarding steps (horizontal slide)
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
.animation(ODAnimation.pageTransition, value: currentStep)
```

**Selection changes** always use `snappy`:

```swift
withAnimation(ODAnimation.snappy) {
    selectedItem = newItem
}
```

**Stagger entrance** for lists — wrap items in `AnimatedListRow`:

```swift
ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
    AnimatedListRow(index: index) {
        // row content
    }
}
```

**Hover lift** for cards — wrap in `HoverCard`:

```swift
HoverCard {
    GlassPanel {
        // card content
    }
}
```

**Numeric transitions** — use `AnimatedNumber` or `.contentTransition(.numericText())`:

```swift
AnimatedNumber("\(count)", font: ODTypography.title, color: ODColors.textPrimary)
```

**Breathing pulse** for attention states:

```swift
.scaleEffect(needsAttention ? 1.08 : 1.0)
.animation(needsAttention ? ODAnimation.breathe : .default, value: needsAttention)
```

---

## Components

### `GlassPanel`

The primary surface container. Four styles: `.card` (default), `.elevated`, `.inset`, `.hero`. See [Glass & Materials](#glass--materials).

### `StatCard`

Displays a metric with title, animated value, subtitle, and optional icon with colored circle background. Lifts slightly on hover.

```swift
StatCard(
    title: "Installed Apps",
    value: "\(count)",
    subtitle: "With true-size calculation",
    icon: "square.grid.2x2.fill",
    iconColor: ODColors.accent
)
```

### `SizeBadge`

Compact capsule showing a byte size. Optionally tinted by safety level.

```swift
SizeBadge(bytes: app.trueSizeBytes)
SizeBadge(bytes: artifact.sizeBytes, level: .risky)
```

### `SafetyLabel`

Traffic-light pill with icon: `checkmark.shield.fill` (safe), `exclamationmark.triangle.fill` (review), `xmark.shield.fill` (risky). Has a subtle color-matched glow shadow.

```swift
SafetyLabel(level: .safe)
```

### `ActionButtonStyle`

Three variants: `.primary` (accent gradient), `.secondary` (inset surface), `.destructive` (risky gradient). All have top-edge highlight, scale on press (0.96), scale on hover (1.03), glow on hover.

```swift
Button("Save") { ... }
    .buttonStyle(ActionButtonStyle(variant: .primary))
```

### `SectionHeader`

Consistent section headers with icon, title, optional subtitle, optional trailing action.

```swift
SectionHeader(
    icon: "folder.fill",
    title: "Artifact Breakdown",
    subtitle: "\(count) items found",
    trailing: AnyView(someButton)
)
```

### `EmptyState`

Large floating icon with bounce animation + message + optional action. Used for "Select an App", "No Results", etc.

```swift
EmptyState(
    icon: "square.grid.2x2",
    message: "Select an App",
    detail: "Choose an app to inspect.",
    actionTitle: "Scan Now",
    action: { ... }
)
```

### `ProgressRing`

Circular progress indicator. Determinate (pass a `Double`) or indeterminate (pass `nil`). Uses accent-to-accentSecondary angular gradient.

```swift
ProgressRing(progress: 0.65, lineWidth: 5, size: 60)
ProgressRing(progress: nil, lineWidth: 4, size: 48)  // spinning
```

### `AnimatedNumber`

Text that smoothly transitions between numeric values using `.contentTransition(.numericText())`.

```swift
AnimatedNumber("42", font: ODTypography.title, color: ODColors.textPrimary)
```

### `AnimatedListRow`

Wraps a row with stagger-entrance animation and hover highlight. Pass the `index` from your `ForEach` enumeration.

### `HoverCard`

Wraps any content with hover-lift effect (scale 1.015 + shadow deepening). Used for grid cards and recommendation cards.

### `ShimmerLoader`

Skeleton placeholder with animated gradient sweep. Pass number of rows.

---

## Layout Patterns

### Page structure

Every feature view follows this structure:

```
VStack(spacing: ODSpacing.md) {
    Hero banner (GlassPanel .hero)
    Stats row (HStack of StatCards)
    Content area (GlassPanel .card, ScrollView, etc.)
}
.padding(ODSpacing.lg)
.odCanvasBackground()
```

### Two-panel layout

The app manager uses a horizontal split:

```
HStack(spacing: ODSpacing.md) {
    GlassPanel { list panel }
    GlassPanel { detail panel }
}
```

### Shell layout

The main shell is a horizontal stack with a custom sidebar:

```
HStack(spacing: 0) {
    sidebar (240pt, NativeGlassSurface background)
    Divider().opacity(0.3)
    detail area (ZStack with animated transitions)
}
```

### Floating footer

The status bar is a `.overlay(alignment: .bottom)` capsule with `.ultraThinMaterial` fill.

---

## Interaction Patterns

### Icon + tinted circle badge

Used consistently for sidebar items, step headers, stat cards, and sheet headers:

```swift
ZStack {
    Circle()
        .fill(tintColor.opacity(0.12))
        .frame(width: size, height: size)
    Image(systemName: iconName)
        .odIcon(.small)
        .foregroundStyle(tintColor)
}
```

Sizes: 28pt (sidebar), 38pt (stat cards), 44pt (sheet headers), 56pt (onboarding step headers).

### Matched geometry selection indicator

The sidebar uses `@Namespace` + `.matchedGeometryEffect` to smoothly slide the active indicator between nav items:

```swift
@Namespace private var sidebarAnimation

// On the selected item's background:
.matchedGeometryEffect(id: "sidebar_selection", in: sidebarAnimation)
```

### Disclosure groups for artifact breakdown

Expandable sections use SwiftUI `DisclosureGroup` with an `insetSurface` background:

```swift
DisclosureGroup {
    // expanded content
} label: {
    // summary row
}
.padding(ODSpacing.sm)
.background(ODColors.insetSurface.opacity(0.4), in: RoundedRectangle(...))
```

### Size breakdown bar

A horizontal stacked bar showing proportional sizes with colored segments and legend dots below.

### Progress dots

Onboarding progress uses capsules that expand when active:

```swift
Capsule()
    .fill(isActive ? ODColors.accent : ODColors.insetSurface)
    .frame(width: isActive ? 24 : 8, height: 8)
    .animation(ODAnimation.snappy, value: currentStep)
```

---

## View Architecture

### Modifier usage order

Apply modifiers in this order:

1. `.odTextStyle()` or `.odIcon()` — typography
2. `.foregroundStyle()` — only if overriding the token color (e.g., gradients)
3. `.padding()` — using `ODSpacing` tokens
4. `.background()` — using `ODColors` or `GlassPanel`
5. `.overlay()` — borders, highlights
6. `.shadow()` or `.odShadow()` — depth
7. `.animation()` — motion
8. `.accessibilityIdentifier()` — testing hooks

### View modifier API

| Modifier | Purpose |
|---|---|
| `.odTextStyle(.token, color:)` | Sets font + foreground color |
| `.odIcon(.token)` | Sets icon font only |
| `.odForeground(.token)` | Sets foreground color only |
| `.odSurfaceCard(selected:)` | Applies inset surface card style |
| `.odCanvasBackground()` | Applies the full gradient canvas |
| `.odShadow(preset)` | Applies a shadow preset |

---

## Accessibility

### Identifiers

All interactive elements and testable containers must have `.accessibilityIdentifier()`. Use descriptive snake_case:

- `app_row_{bundleID}` for app list rows
- `sidebar_{sectionRawValue}` for sidebar items
- `onboarding_next_button`, `onboarding_back_button`, `onboarding_finish_button`
- `quickscan_start_button`, `uninstall_button`, `confirm_uninstall_button`

### NSViewRepresentable and accessibility

`GlassPanel` uses `NativeGlassSurface` (an `NSViewRepresentable`) which creates an accessibility barrier. Accessibility identifiers placed on views inside a `GlassPanel` may not be reachable from XCUITest. If you need a testable element inside a `GlassPanel`, place the identifier on a SwiftUI view outside the panel, or use `.overlay(Color.clear.accessibilityElement().accessibilityIdentifier("id"))`.

### Dynamic type

All typography uses the system font at fixed sizes (not `.largeTitle`, `.body` etc.). This is intentional for a utility app with dense information layout. If Apple's accessibility scaling is needed in the future, replace `ODTypography` values with scalable equivalents.

---

## Rules & Constraints

These rules are enforced by `DesignSystemComplianceTests`:

1. **No `.font()` in feature views.** Use `.odTextStyle()` for text, `.odIcon()` for SF Symbols.
2. **No `Color()` constructors in feature views.** All colors come from `ODColors` tokens. If you need a new color, add it to `ODColors`. If you need a function that returns a color, avoid having `Color(` as a substring in the function name — use "tint" instead (e.g., `sectionTint`, `priorityTint`).
3. **No raw `.shadow()` values.** Use `ODShadow` presets or `.odShadow()`.
4. **No raw `Animation.spring()` in feature views.** Use `ODAnimation` tokens.
5. **No external dependencies.** Pure Apple frameworks only.
6. **Always move to Trash.** Never `rm`, never permanent delete, always confirm.
7. **macOS 14.0 minimum.** Use `#available(macOS 26.0, *)` for liquid glass; always provide a `NSVisualEffectView` fallback.

---

## Adding New Features

When building a new feature view, follow this checklist:

### 1. File structure

Create a new directory under `OpenDisk/Features/{FeatureName}/` with:
- `{FeatureName}View.swift` — the SwiftUI view
- `{FeatureName}ViewModel.swift` — the `@MainActor ObservableObject`

### 2. View skeleton

```swift
import SwiftUI

struct NewFeatureView: View {
    @ObservedObject var viewModel: NewFeatureViewModel

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            heroBanner
            content
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
    }

    private var heroBanner: some View {
        GlassPanel(style: .hero) {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Feature Title")
                    .odTextStyle(.display)
                Text("Description of what this feature does.")
                    .odTextStyle(.body, color: .textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var content: some View {
        GlassPanel {
            // your content here
        }
    }
}
```

### 3. Loading states

Use `ProgressRing` for loading, `EmptyState` for empty/error states, `ShimmerLoader` for skeleton placeholders.

### 4. Lists

For any scrollable list of items:
- Use `AnimatedListRow(index:)` for stagger-entrance
- Use `HoverCard` for grid layouts
- Include `.accessibilityIdentifier()` on each interactive row

### 5. Navigation

If adding a new sidebar section:
1. Add a case to `AppSection`
2. Provide `title`, `systemImage`, and a tint color in `MainShellView.sectionTint()`
3. Add the detail view in `MainShellView.detailView`

### 6. Testing

- Preserve all existing accessibility identifiers
- Add identifiers for new interactive elements
- Run the design system compliance test to verify no token violations
- Run all UI tests to verify nothing broke

### 7. Final check

Before submitting, verify:
- [ ] No `.font()` calls in the feature view
- [ ] No `Color()` constructors in the feature view
- [ ] All spacing uses `ODSpacing` tokens
- [ ] All corner radii use `ODRadius` tokens
- [ ] All animations use `ODAnimation` tokens
- [ ] Glass surfaces use `GlassPanel`, not raw backgrounds
- [ ] Interactive elements have accessibility identifiers
- [ ] Build succeeds, all tests pass
