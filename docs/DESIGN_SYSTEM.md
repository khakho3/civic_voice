# Civic Glass Design System

## Purpose

Civic Glass is the **only** approved visual language for CivicVoice. Every screen — whether built by a human contributor or an AI coding assistant — must be composed entirely from the tokens documented here.

- No screen may declare a raw `Color`, font size, spacing, radius, duration, or icon library value. Every visual property must resolve to a token from `lib/core/theme/` or `lib/core/constants/`.
- No screen may introduce a competing style system, a second icon library, a second font, or a bespoke color palette.
- This document is the single source of truth for design decisions in this repository. If code and this document disagree, that is a bug — fix the code, or open a change log entry to update this document. Never quietly diverge from it.
- One import gives access to the entire system:

  ```dart
  import 'package:civic_voice/core/theme/app_theme.dart';
  ```

This document is derived from the approved *CivicVoice Design System Requirements*, the *Design Review & Screen Acceptance Framework*, the *Screen Specifications Standard*, and the *CL-001 Civic Glass Specification Enhancement* change log — reconciled against what is actually implemented in `lib/core/`. Where the source documents left a value formally undefined (flagged in CL-001), that is called out explicitly below rather than silently invented.

---

## Design Principles

| Principle | What it means in practice |
|---|---|
| **Clarity** | A user must always understand what happened, what is happening, and what to do next. No screen should require guessing. |
| **Consistency** | The same interaction behaves the same way everywhere. Consistency is prioritized over one-off creative flourishes. |
| **Accessibility** | WCAG 2.2 AA is mandatory, never optional and never traded away for aesthetics. AAA is the target wherever practical. |
| **Professional Government UX** | CivicVoice combines Material usability, Apple-inspired softness, Fluent-inspired translucency, and government-grade clarity. The result should feel trustworthy, calm, modern, and efficient — never playful or decorative. |
| **Mobile-first** | Every interface is designed for mobile first, then adapted upward. |
| **Minimal visual noise** | Reduce cognitive load: minimize unnecessary choices, decoration, and competing focal points. Elevation and glass effects stay subtle by design. |
| **Civic trust** | Users must always be able to see current status, progress, outcomes, and system feedback. Transparency is a design requirement, not a nice-to-have. |

---

## Brand

### CivicVoice logo

The mark is a speech bubble enclosing a civic column (representing government/institutional trust combined with citizen voice). The logo's artwork colors (`#2766E0` mark, `#DFDEDE` detailing) are fixed brand-asset colors baked into the SVG/PNG files — they are **not** the same token as `AppColors.primary` (`#2563EB`), which drives UI chrome. Do not recolor the logo to match UI tokens, and do not sample colors out of the logo file for use elsewhere in the app.

### Logo usage

| File | Purpose |
|---|---|
| `assets/branding/logo.svg` | Master source of truth. Vector, 1024×1024 viewBox. Use for any context that can render SVG, or as the source for regenerating raster sizes. |
| `assets/branding/logo.png` | 1024×1024 raster master, rendered from `logo.svg`. Use for high-resolution contexts (app store listings, print, marketing). |
| `assets/branding/logo_app.png` | In-app usage (splash screen, app bar mark, empty-state branding). |
| `assets/branding/favicon.png` | 512×512, for web/browser-tab and manifest icon contexts. |

Reference these exclusively through `AppAssets` (`lib/core/constants/app_assets.dart`) — never a raw asset string.

### Clear space

No formal clear-space value has been published in the approved design documents. Until one is ratified, maintain a minimum clear space around the logo equal to `AppSpacing.lg` (24px) on all sides so it stays token-driven rather than arbitrary.

### Branding rules

- Do not stretch, skew, recolor, rotate, or apply filters/effects to the logo.
- Do not recreate the mark in code (e.g. as a `CustomPainter`) — always use the provided asset files.
- Do not place the logo on a background that fails AA contrast against its surrounding chrome.
- Do not generate additional raster sizes ad hoc — regenerate from `logo.svg` and add the result to `assets/branding/` plus `AppAssets` so it stays centralized.

---

## Typography

**File:** `lib/core/theme/app_typography.dart` · **Class:** `AppTypography`, `AppFontWeight`, `AppFontSize`, `AppLineHeight`

### Font family

**Inter**, loaded via the `google_fonts` package (no bundled font files to maintain). Decorative or secondary fonts are prohibited anywhere in the app.

### Font weights

| Token | Weight |
|---|---|
| `AppFontWeight.regular` | 400 |
| `AppFontWeight.medium` | 500 |
| `AppFontWeight.semiBold` | 600 |
| `AppFontWeight.bold` | 700 |

### Type scale

| Token | Size | Default weight | Line height |
|---|---|---|---|
| `AppTypography.display` | 40px | Bold | 1.4× |
| `AppTypography.h1` | 32px | Bold | 1.4× |
| `AppTypography.h2` | 24px | SemiBold | 1.4× |
| `AppTypography.h3` | 20px | SemiBold | 1.5× |
| `AppTypography.body` | 16px | Regular | 1.5× |
| `AppTypography.bodySmall` | 14px | Regular | 1.5× |
| `AppTypography.caption` | 12px | Medium | 1.6× |

### Letter spacing

No custom letter-spacing is applied anywhere in the scale — Inter's native metrics are used as-is. Do not add manual `letterSpacing` overrides unless a specific, documented accessibility or legibility need arises.

### Usage guidance

- Body text defaults to 16px (`AppTypography.body`). 14px (`bodySmall`) is the **minimum** permitted size for body copy.
- `caption` (12px) is reserved for non-body microcopy — timestamps, metadata, helper text — not for paragraphs.
- Text is left-aligned by default. Large blocks of centered text are prohibited.
- Dynamic text scaling must keep working — never wrap text in `MediaQuery(textScaler: TextScaler.noScaling)` or similar.
- Prefer reading styles off `Theme.of(context).textTheme` (populated by `AppTypography.textTheme(...)`) over calling `AppTypography.body` etc. directly, so text automatically re-themes with light/dark mode.

---

## Color System

**File:** `lib/core/theme/app_colors.dart` · **Classes:** `AppColors`, `AppColorsLight`, `AppColorsDark`, `AppSemanticColors`, `AppGlassBlur`

### Brand colors

| Token | Hex | Usage |
|---|---|---|
| `AppColors.primary` | `#2563EB` | Primary CTAs, links, selected states, active navigation. |
| `AppColors.primaryHover` | `#1D4ED8` | Hover feedback (desktop/web pointer contexts) only. |
| `AppColors.primaryPressed` | `#1E40AF` | Pressed/active feedback only — never a static fill. |

No **Secondary Brand** color has been formally approved yet (tracked pending in CL-001). Until one is ratified, `ColorScheme.secondary` falls back to the neutral `secondaryText` token rather than an invented hue — see [Light Theme](#light-theme) / [Dark Theme](#dark-theme).

### Neutral, surface & border colors

These are theme-dependent — see the full tables under [Light Theme](#light-theme) and [Dark Theme](#dark-theme). In both themes the roles are: **canvas** (app background), **primary/secondary surface** (cards, sheets, chrome), **primary/secondary text** (the neutral scale), and **border** (hairlines, dividers, outlines).

> Pure white (`#FFFFFF`) is never used as the app's primary background in either theme — only as a surface color.

### Semantic colors

| Token | Hex | Usage |
|---|---|---|
| `AppColors.success` | `#16A34A` | Confirmations, resolved states, positive feedback. |
| `AppColors.warning` | `#F59E0B` | Caution states, pending review, non-blocking issues. |
| `AppColors.error` | `#DC2626` | Failures, destructive actions, blocking validation errors. |
| `AppColors.info` | `#2563EB` | Neutral informational messaging (shares the brand primary hue). |

### Status colors

| Token | Hex | Report status |
|---|---|---|
| `AppColors.statusSubmitted` | `#2563EB` | Submitted |
| `AppColors.statusUnderReview` | `#F59E0B` | Under Review |
| `AppColors.statusAssigned` | `#8B5CF6` | Assigned |
| `AppColors.statusInProgress` | `#0EA5E9` | In Progress |
| `AppColors.statusResolved` | `#16A34A` | Resolved |
| `AppColors.statusRejected` | `#DC2626` | Rejected |

**Hard rule:** color must never be the sole indicator of status. Every status color must be paired with a matching icon (see [Iconography](#iconography)) and a text label.

### Glass surfaces

| Token | Value |
|---|---|
| `AppColorsLight.glassSurface` | `rgba(255,255,255,0.65)` |
| `AppColorsDark.glassSurface` | `rgba(15,23,42,0.75)` |
| `AppGlassBlur.small` / `.medium` / `.large` | 10 / 20 / 30 sigma |

Blur sigma values are not yet formally ratified (pending in CL-001); treat them as the working default until superseded.

**Glass is permitted on:** navigation panels, cards, dialogs, bottom sheets, filters, search containers.
**Glass is prohibited on:** long-form content, input-heavy forms, analytics charts, large text sections — legibility comes first.

### Accessing semantic colors in a theme-aware way

Success/warning/info/status colors aren't part of Material's `ColorScheme`, so they're published as a `ThemeExtension`:

```dart
final semantic = Theme.of(context).extension<AppSemanticColors>()!;
Icon(AppIcons.statusResolved, color: semantic.statusResolved);
```

---

## Light Theme

**File:** `lib/core/theme/app_light_theme.dart` · **Class:** `AppLightTheme.theme` (exposed as `AppTheme.light`)

| Role | Token | Hex |
|---|---|---|
| Application canvas | `AppColorsLight.canvas` | `#F8FAFC` |
| Primary surface | `AppColorsLight.primarySurface` | `#FFFFFF` |
| Secondary surface | `AppColorsLight.secondarySurface` | `#F1F5F9` |
| Glass surface | `AppColorsLight.glassSurface` | `rgba(255,255,255,0.65)` |
| Primary text | `AppColorsLight.primaryText` | `#0F172A` |
| Secondary text | `AppColorsLight.secondaryText` | `#475569` |
| Border | `AppColorsLight.border` | `#E2E8F0` |

Implementation notes:

- Built from `ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light)`, then every role the design system actually specifies (`primary`, `error`, `surface`, `onSurface`, `outline`, canvas/container tiers) is explicitly overridden with the approved hex. Only *unspecified* Material roles (e.g. `tertiary`) are left to the seed algorithm.
- `surfaceTintColor` is pinned to `Colors.transparent` across every component sub-theme. Material 3 otherwise auto-tints elevated surfaces toward `colorScheme.primary`, which would silently drift the approved surface hexes away from spec as elevation increases. Hierarchy is communicated through [Elevation](#elevation) alone instead.
- `scaffoldBackgroundColor` is the **canvas** token, kept distinct from `colorScheme.surface` (**primary surface**) — this preserves the design system's explicit distinction between page background and component surface.

## Dark Theme

**File:** `lib/core/theme/app_dark_theme.dart` · **Class:** `AppDarkTheme.theme` (exposed as `AppTheme.dark`)

| Role | Token | Hex |
|---|---|---|
| Application canvas | `AppColorsDark.canvas` | `#0F172A` |
| Primary surface | `AppColorsDark.primarySurface` | `#111827` |
| Secondary surface | `AppColorsDark.secondarySurface` | `#1E293B` |
| Glass surface | `AppColorsDark.glassSurface` | `rgba(15,23,42,0.75)` |
| Primary text | `AppColorsDark.primaryText` | `#F8FAFC` |
| Secondary text | `AppColorsDark.secondaryText` | `#CBD5E1` |
| Border | `AppColorsDark.border` | `#334155` |

Structurally, `AppDarkTheme` mirrors `AppLightTheme` section-for-section (same component sub-themes, same `surfaceTintColor: transparent` rationale) so the two never drift apart. The one deliberate difference: card/dialog/sheet `shadowColor` uses `AppColorsDark.border` rather than a black tone, since a black shadow is imperceptible against an already-dark canvas — a lighter, token-sourced tint reads better while staying subtle.

Every screen must be verified in **both** themes before it can pass design review (§19.20 Governance Rule 7).

---

## Spacing System

**File:** `lib/core/theme/app_spacing.dart` · **Class:** `AppSpacing`

| Token | Value |
|---|---|
| `AppSpacing.xs` | 4px |
| `AppSpacing.sm` | 8px |
| `AppSpacing.md` | 16px |
| `AppSpacing.lg` | 24px |
| `AppSpacing.xl` | 32px |
| `AppSpacing.xxl` | 40px |
| `AppSpacing.xxxl` | 48px |
| `AppSpacing.xxxxl` | 64px |

The platform runs on a strict 8-point grid — every gap, padding, and margin must resolve to one of these eight values. Arbitrary spacing (e.g. `12.5`, `18`) is prohibited, even if it "looks right" in one spot; the grid is what keeps vertical rhythm consistent as screens are built by different contributors. Compose larger layout dimensions (button heights, section gaps) from this scale rather than introducing new numbers — see [Flutter Architecture](#flutter-architecture) → `app_dimensions.dart`.

---

## Border Radius

**File:** `lib/core/theme/app_radius.dart` · **Classes:** `AppRadius`, `AppComponentRadius`

| Token | Value |
|---|---|
| `AppRadius.xs` | 8px |
| `AppRadius.sm` | 12px |
| `AppRadius.md` | 16px |
| `AppRadius.lg` | 20px |
| `AppRadius.xl` | 24px |

### Component mapping (`AppComponentRadius`)

| Component | Radius |
|---|---|
| Buttons | 12px (`sm`) |
| Input fields | 12px (`sm`) |
| Cards | 16px (`md`) |
| Dialogs | 20px (`lg`) |
| Bottom sheets | 24px (`xl`), top corners only |

```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: AppComponentRadius.card,
  ),
)
```

Rounded corners are core to Civic Glass's "soft and approachable" feel — never use a sharp (`BorderRadius.zero`) corner or an unlisted radius value.

---

## Elevation

**File:** `lib/core/theme/app_elevation.dart` · **Classes:** `AppElevation`, `AppShadow`

| Level | Material dp | Usage |
|---|---|---|
| 0 | 0 | Background surfaces — flat, no shadow. |
| 1 | 1 | Standard cards. |
| 2 | 3 | Dialogs, bottom sheets. |
| 3 | 6 | Floating action buttons, critical overlays. |

`AppShadow.level0` – `.level3` provide matching `BoxShadow` lists (subtle, low-opacity, derived from the approved ink color) for custom `Container`/`DecoratedBox` surfaces that fall outside Material's built-in elevation system.

**When to use elevation:** only to communicate real hierarchy — "this surface floats above that one." A dialog is elevated because it interrupts the flow; a FAB is elevated because it's a priority action.

**When not to use elevation:** as decoration. Heavy or decorative shadows are explicitly prohibited — if a shadow is there to "make it pop" rather than to signal stacking order, remove it. Glass surfaces must keep their elevation subtle too; don't compensate for a busy glass background with a heavier shadow.

> Exact shadow blur/opacity values are not yet formally ratified (CL-001 "Shadow Tokens" is pending) — `AppShadow` implements the documented "subtle, not heavy or decorative" principle as the working default.

---

## Motion

**File:** `lib/core/theme/app_motion.dart` · **Classes:** `AppMotionDuration`, `AppMotionCurve`, `AppMotion`

### Durations

| Token | Value | Usage |
|---|---|---|
| `AppMotionDuration.fast` | 100ms | Micro-interactions (ripple, icon toggle). |
| `AppMotionDuration.standard` | 200ms | Control state changes (button press, chip select). |
| `AppMotionDuration.moderate` | 300ms | Small surface transitions (card expand, snackbar). |
| `AppMotionDuration.emphasized` | 400ms | Large surface transitions (dialogs, bottom sheets). |
| `AppMotionDuration.pageTransition` | 500ms | Full-screen route transitions. |

### Curves

| Token | Curve |
|---|---|
| `AppMotionCurve.standard` | `Curves.easeInOut` |
| `AppMotionCurve.decelerate` | `Curves.easeOut` |
| `AppMotionCurve.accelerate` | `Curves.easeIn` |
| `AppMotionCurve.emphasized` | `Curves.easeInOutCubicEmphasized` |

> No explicit millisecond values exist yet in the approved design documents — CL-001 lists "Motion Guidelines" as pending. Civic Glass is explicitly benchmarked against Material Design, so these durations/curves follow the standard Material 3 motion scale until an approved change log supersedes them.

### Reduced motion

Accessibility requires respecting the platform's reduced-motion setting. Never animate with a raw `Duration` literal — wrap it:

```dart
AnimatedContainer(
  duration: AppMotion.duration(context, AppMotionDuration.standard),
  curve: AppMotionCurve.standard,
  // ...
)
```

`AppMotion.duration` returns `Duration.zero` automatically when `MediaQuery.disableAnimations` is set, satisfying the platform's Reduced Motion requirement without every screen re-implementing the check.

---

## Iconography

**File:** `lib/core/theme/app_icons.dart` · **Classes:** `AppIcons`, `AppIconSize`

- **Lucide is the only approved icon library**, via the `lucide_icons_flutter` package. Mixing in `Icons.*` (Material Icons), `CupertinoIcons.*`, or any other icon package is prohibited.
- Always reference icons through `AppIcons.<name>`, not `LucideIcons.<name>` directly — this keeps the icon vocabulary centralized and lets it be audited/swapped from one file.

### Approved sizes

| Token | Value |
|---|---|
| `AppIconSize.sm` | 16px |
| `AppIconSize.md` | 20px |
| `AppIconSize.standard` | 24px |
| `AppIconSize.lg` | 32px |
| `AppIconSize.xl` | 48px |

Arbitrary icon sizes (e.g. `22`, `26`) are prohibited — pick the nearest approved size.

### Icon color rules

Icons inherit color from context, they don't carry a hardcoded color:

- Default/neutral icons → `primaryText` (via the theme's `iconTheme`).
- Inactive/secondary icons → `secondaryText`.
- Status icons → the matching `AppColors.status*` / `AppSemanticColors` token, always paired with a label.
- Icons on a filled primary surface (e.g. inside a primary button) → white (`onPrimary`), via `primaryIconTheme`.

### Icon usage rules

- An icon must always support the meaning of the label or action next to it — never use an icon as pure decoration.
- An icon is never the *sole* indicator of meaning; pair it with a text label wherever the meaning must be unambiguous (this is mandatory for status).
- Don't invent new icon meanings per-screen — check `AppIcons` for an existing semantic token before adding a new one.

---

## Responsive Design

**File:** `lib/core/theme/app_breakpoints.dart` · **Class:** `AppBreakpoints`

| Token | Width |
|---|---|
| `AppBreakpoints.smallMobile` | 320px+ |
| `AppBreakpoints.standardMobile` | 375px+ |
| `AppBreakpoints.largeMobile` | 428px+ |

CivicVoice is designed **mobile-first**: build and test the layout at 320px first, then confirm it scales gracefully up through 375px and 428px — never the reverse.

- Vertical scrolling is preferred; horizontal scrolling should be avoided.
- Content must never clip or overflow at any of the three supported widths.
- Touch targets must stay accessible (see [Accessibility](#accessibility)) at every width — don't shrink controls to fit a smaller screen.
- Critical actions (submit, confirm) must remain reachable without excessive scrolling.

Tablet and desktop layouts are intentionally out of scope for this document — see [Future Expansion](#future-expansion).

---

## Accessibility

**File:** `lib/core/constants/app_semantics.dart` · **Class:** `AppAccessibility`

| Requirement | Token / Value |
|---|---|
| Minimum compliance | `AppAccessibility.complianceMinimum` — WCAG 2.2 AA (mandatory, never optional) |
| Target compliance | `AppAccessibility.complianceTarget` — WCAG 2.2 AAA (wherever practical) |
| Minimum touch target | `AppAccessibility.touchTargetMinimum` — 48×48px |
| Contrast, normal text | `AppAccessibility.contrastRatioNormalText` — 4.5:1 |
| Contrast, large text/UI graphics | `AppAccessibility.contrastRatioLargeText` — 3.0:1 |
| Minimum body text size | `AppAccessibility.minBodyTextSize` — 14px |

Additional rules:

- **Reduced motion:** honored automatically via `AppMotion.duration` (see [Motion](#motion)) — don't bypass it with a raw `Duration`.
- **Semantic labels:** every icon-only control needs a `Semantics`/`tooltip`/`label` so screen readers can announce it. Color and icon together are still not sufficient without a text label for status.
- **Dynamic text scaling** must keep working on every screen — don't disable the system font-scale setting.
- **Keyboard accessibility:** applies wherever CivicVoice runs on Flutter Web — all interactive controls must be reachable and operable via keyboard focus/`Tab` order. Not applicable to the Android/iOS mobile targets, which use touch/screen-reader (TalkBack/VoiceOver) navigation instead.

---

## Component Guidelines

Status legend: **Themed** = a Material widget already picks this up automatically from `AppTheme`. **Tokens only** = the colors/type/spacing exist, but no reusable `AppXxx` widget has been built yet (see [Future Expansion](#future-expansion)) — compose it manually from tokens until one lands.

| Component | Status | Notes |
|---|---|---|
| **Buttons** | Themed (Primary/Secondary/Ghost) | `ElevatedButton`/`FilledButton` = Primary, `OutlinedButton` = Secondary, `TextButton` = Ghost — all themed via `app_light_theme.dart` / `app_dark_theme.dart`. **Danger** and **Icon Button** are not separately themed yet (`ThemeData` supports only one default style per button type); override explicitly: `ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.error), ...)`. **FAB** currently falls back to Material 3 defaults — no `floatingActionButtonTheme` is set yet. |
| **Text Fields** | Themed | `InputDecorationThemeData` covers default/filled/focused/error/disabled out of the box — just use `TextField`/`TextFormField` with no manual `InputDecoration` styling. |
| **Cards** | Themed | `CardThemeData`: `AppComponentRadius.card`, `AppElevation.level1`, `surfaceTintColor: transparent`. Use `Card`, not a hand-rolled `Container` + `BoxShadow`. |
| **Chips** | Themed (generic) | `ChipThemeData` styles all chip widgets uniformly. Filter/Choice/Status *chip* variants aren't visually differentiated by the theme yet — a Status Chip should combine the base chip styling with the relevant `AppColors.status*` + `AppIcons.status*` manually. |
| **Status Badges** | Tokens only | Do **not** confuse this with Flutter's built-in `Badge` widget (a small counter/dot, covered by `badgeTheme`) — the design system's "Status Badge" is a labeled pill (icon + label + color) per §19.14 and has no widget yet. Compose from `AppColors.status*`, `AppIcons.status*`, `AppTypography.labelMedium`, and `AppComponentRadius` (stadium/pill shape) until `AppStatusBadge` exists. |
| **Dialogs** | Themed | `DialogThemeData`: `AppComponentRadius.dialog`, `AppElevation.level2`. Use `AlertDialog`/`Dialog`. |
| **Bottom Sheets** | Themed | `BottomSheetThemeData`: top-corner `AppComponentRadius.bottomSheet`, drag handle enabled, `AppElevation.level2`. Use `showModalBottomSheet`. |
| **Navigation Bars** | Themed | `NavigationBarThemeData` (Material 3 `NavigationBar`, not the legacy `BottomNavigationBar`). Cap destinations at `AppNavigationSemantics.bottomNavMaxItems` (5) — this is a documented convention, not a compile-time guard. |
| **App Bars** | Themed | `AppBarTheme`: flat by default (`AppElevation.level0`), elevates on scroll, left-aligned title per the typography left-alignment rule. |
| **Snackbars** | Themed | `SnackBarThemeData`: floating behavior, `AppComponentRadius.inputField`, `AppElevation.level2`. |
| **Skeleton Loaders** | Tokens only | No shimmer package/widget is wired up yet. Interim guidance: base = `secondarySurface`, highlight = `primarySurface`, cycle duration ≈ `AppMotionDuration.moderate`. Blank loading screens are prohibited — always show a loading state. |
| **Empty States** | Tokens only | Compose from `AppIcons.empty`, `AppTypography.h3` message, `AppTypography.body` supporting copy, and a recommended action button — per §19.18 required structure (illustration/icon + message + action). |
| **Error States** | Tokens only | Compose from `AppIcons.error` / `AppColors.error`, an error message, and a retry/recovery action — per §19.18 required structure. |

---

## Naming Conventions

| Category | Convention | Example |
|---|---|---|
| **Colors** | `AppColors`/`AppColorsLight`/`AppColorsDark` + lowerCamelCase, named by *role*, never by literal value | `AppColors.statusResolved`, not `AppColors.green` |
| **Widgets (future component library)** | `App` prefix for shared design-system widgets, to distinguish from raw Material widgets and feature-specific widgets | `AppButton`, `AppStatusBadge`, `AppEmptyState` |
| **Assets** | `snake_case` file names, grouped by category folder, referenced only via `AppAssets` | `assets/branding/logo_app.png` → `AppAssets.logoApp` |
| **Screens** | `<ROLE>-<NNN>` Screen ID per the Screen Specifications Standard, role prefix matches the primary user role | `CIT-001` (Citizen), `MUN-004` (Municipal Officer), `MNT` (Maintenance Team), `MIN` (Ministry Supervisor), `ADM` (System Administrator), `AUTH` (Authentication) |
| **Constants** | `AppXxx` PascalCase `abstract final class` holding `static const` lowerCamelCase fields, one token category per file | `AppSpacing.md`, `AppRadius.lg` |

---

## Flutter Architecture

```text
lib/core/
├── theme/
│   ├── app_colors.dart        # Brand/semantic/status colors, light/dark surface tokens, AppSemanticColors ThemeExtension, glass blur
│   ├── app_typography.dart    # Inter type scale, font weights/line heights, Material 3 TextTheme builder
│   ├── app_spacing.dart       # 8-point spacing scale
│   ├── app_radius.dart        # Corner radius scale + component-to-radius mapping
│   ├── app_elevation.dart     # Elevation levels (Material dp) + BoxShadow tokens
│   ├── app_icons.dart         # Lucide icon vocabulary (AppIcons) + approved sizes (AppIconSize)
│   ├── app_motion.dart        # Animation durations, curves, reduced-motion helper
│   ├── app_breakpoints.dart   # Responsive breakpoints + AppDeviceType/BuildContext helpers
│   ├── app_light_theme.dart   # Full Material 3 ThemeData — light
│   ├── app_dark_theme.dart    # Full Material 3 ThemeData — dark
│   └── app_theme.dart         # Entry point: AppTheme.light/dark/themeMode + re-exports every token file
└── constants/
    ├── app_assets.dart        # Centralized asset path constants (AppAssets)
    ├── app_dimensions.dart    # Concrete component/layout geometry, composed from AppSpacing/AppBreakpoints
    └── app_semantics.dart     # Accessibility policy tokens (AppAccessibility) + AppScreenState enum
```

CivicVoice's broader structure follows a feature-first layout (`lib/features/<module>/{screens,widgets,models,services}/`, per the project README) — `lib/core/` is the shared foundation every feature module imports, and nothing in `lib/core/theme` or `lib/core/constants` should depend on feature code in the other direction.

---

## Usage Examples

**Colors**

```dart
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Icon(AppIcons.statusResolved, color: AppColors.statusResolved),
)
```

**Typography**

```dart
Text('Report submitted', style: Theme.of(context).textTheme.headlineSmall);
Text('We will notify you when a Municipal Officer reviews this.',
    style: Theme.of(context).textTheme.bodyMedium);
```

**Spacing**

```dart
Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
  child: Column(
    children: [
      const SizedBox(height: AppSpacing.lg),
      // ...
    ],
  ),
)
```

**Radius**

```dart
DecoratedBox(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface,
    borderRadius: AppComponentRadius.card,
  ),
)
```

**Theme (app root)**

```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: AppTheme.themeMode, // ThemeMode.system
  home: const CivicVoiceHome(),
)
```

**Icons**

```dart
Icon(AppIcons.location, size: AppIconSize.standard, color: Theme.of(context).colorScheme.onSurface)
```

Never hardcode a design value — every one of the snippets above resolves through a centralized token, not a literal.

---

## Do

- Import `package:civic_voice/core/theme/app_theme.dart` and build every screen from its tokens.
- Verify every screen in **both** light and dark theme before calling it done.
- Pair every status color with an icon and a text label.
- Respect the 48×48px minimum touch target on every interactive control.
- Compose new spacing/sizing values out of `AppSpacing` rather than introducing a new number.
- Use `AppMotion.duration(context, ...)` instead of a raw `Duration` so reduced-motion users are respected automatically.
- Flag a token gap (see the "Tokens only" rows in [Component Guidelines](#component-guidelines)) instead of quietly inventing a one-off style.

## Don't

- No hardcoded colors — always `AppColors`/`AppColorsLight`/`AppColorsDark`/`Theme.of(context).colorScheme`.
- No hardcoded spacing — always `AppSpacing`.
- No hardcoded radius — always `AppRadius` / `AppComponentRadius`.
- No hardcoded animation durations — always `AppMotionDuration` (wrapped in `AppMotion.duration`).
- No random icon packs — Lucide via `AppIcons` only. No `Icons.*`, no `CupertinoIcons.*`.
- No custom fonts — Inter only, via `AppTypography`.
- No duplicate components — check [Component Guidelines](#component-guidelines) before building a new one-off widget that already has a themed equivalent.
- No inline styling when a design token exists for that value.
- No pure-white primary background (`AppColorsLight.canvas` is `#F8FAFC`, not `#FFFFFF`).
- No color-only status indicators — icon + label are mandatory alongside color.

---

## Future Expansion

The following are intentionally out of scope for this foundation pass and reserved for later work:

- **Component library** — `AppButton` (incl. Danger/Icon/FAB variants), `AppStatusBadge`, `AppEmptyState`, `AppErrorState`, `AppSkeletonLoader`, and the rest of the "Tokens only" rows in [Component Guidelines](#component-guidelines).
- **Animation library** — shared route-transition builders and reusable motion widgets built on top of `app_motion.dart`.
- **Charts / data visualization** — for Ministry Supervisor analytics screens.
- **Maps** — location picker and report-map styling, layered on Google Maps Flutter.
- **Advanced accessibility** — a full screen-reader audit pass and Flutter Web keyboard-navigation coverage.
- **Tablet & desktop layouts** — `AppBreakpoints.tablet` (768px) and sidebar navigation already exist as tokens in `app_breakpoints.dart`, but formal tablet/desktop UX guidance is deferred until the mobile experience is fully built out.
- **Secondary/Tertiary brand colors, exact blur/shadow/motion specs** — pending formal ratification per the CL-001 change log; current values are documented working defaults, not final approved tokens.
