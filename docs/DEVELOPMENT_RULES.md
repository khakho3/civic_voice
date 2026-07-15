# CivicVoice Development Rules

## Purpose

This document defines the required development workflow and coding standards for CivicVoice.

These rules apply equally to **human contributors** and **AI coding assistants**. Neither is exempt from any rule below. If an AI assistant is generating code for this repository, it must follow this document exactly as a human contributor would.

For visual/design tokens (colors, typography, spacing, radius, motion, elevation, icons), see [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) — this document does not repeat that content, it explains how you must work.

---

## Before You Start

Every contributor must, at the start of every work session:

1. Switch to `main`.
2. Pull the latest `origin/main`.
3. Confirm the Design System foundation (`lib/core/theme/`, `lib/core/constants/`) is present and unchanged from what's approved.
4. Read [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md).
5. Read this document.
6. Switch back to your assigned `feature/<module>` branch.

**Never begin development without first updating from `main`.** Working from a stale baseline is the most common source of avoidable merge conflicts and design-system drift.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, reviewed releases only. |
| `test` | Integration and QA testing. |
| `feature/<module>` | Individual feature development, one branch per module. |

- Work happens **only** on your assigned `feature/<module>` branch.
- **No direct commits to `main`.**
- **No direct commits to `test`.**
- Feature branches are merged into `test` via reviewed pull request; `test` is later promoted to `main`. See [Pull Requests](#pull-requests) and [Definition of Done](#definition-of-done).

---

## Module Ownership

CivicVoice is split into six modules (Authentication, Citizen Reporting, Municipal Officer, Maintenance Team, Ministry Supervisor, System Administrator — see the project [README](../README.md) for full detail).

- A contributor only works inside their assigned module.
- Do not modify another contributor's feature without their approval.
- If a change requires touching shared code (`lib/core/`, `lib/shared/`, `lib/services/`, `lib/models/`, `lib/widgets/`), communicate with the team **before** making the change — shared code affects every module at once.

---

## Design System

The Civic Glass Design System (`lib/core/theme/`, `lib/core/constants/`) is the single source of truth for every visual value in the app.

Never redefine:

- Colors
- Typography
- Icons
- Spacing
- Radius
- Motion
- Elevation

Always use the centralized design tokens documented in [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md). If a token you need doesn't exist yet, raise it with the team — don't invent one locally.

---

## Flutter Theme

Always consume:

- `Theme.of(context)`, or
- an approved design token (`AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppIcons`, etc.)

Never hardcode a visual value (a color literal, a raw number for size/spacing/radius, a `Duration` literal) directly in widget code.

---

## Icons

Lucide only, via `AppIcons` (`lucide_icons_flutter`). No additional icon packs — no `Icons.*`, no `CupertinoIcons.*`, no third-party icon sets.

---

## Typography

Inter only, via `AppTypography` / `Theme.of(context).textTheme`. No custom fonts.

---

## Assets

Use centralized asset constants (`AppAssets`). Never reference an asset path directly as a string literal — if the asset you need isn't in `AppAssets` yet, add it there first.

---

## Components

- Reuse existing shared components whenever one is available.
- Do not duplicate widgets that already exist — search before you build.
- If a new reusable component is genuinely needed, propose it and get approval before creating it.

---

## Screen Development

- Follow the approved Figma screens exactly.
- Do not redesign an approved screen.
- Do not invent new screens.
- Do not invent new workflows.
- Implement only the states the screen specification approves — nothing extra, nothing missing.

---

## State Handling

Implement every screen state required for that screen:

- Loading
- Empty
- Success
- Error
- Offline
- Permission
- Disabled

Only implement the states applicable to the current screen — don't build states the screen specification doesn't call for.

---

## Navigation

- Follow the approved navigation architecture exactly.
- Never add a navigation destination that isn't in the approved architecture.
- Never remove an approved navigation destination.

---

## Accessibility

- Maintain WCAG compliance (see [`DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md#accessibility) for the exact targets).
- Respect minimum touch target sizes.
- Respect semantic labels — every icon-only control needs one.
- Respect reduced motion.

---

## AI Assistant Rules

Any AI assistant used during development must:

- Read `DESIGN_SYSTEM.md` before generating any UI code.
- Follow the project's design system exactly — no exceptions and no "close enough" substitutions.
- Reuse existing architecture and components rather than generating new parallel ones.
- Never invent colors.
- Never invent spacing.
- Never invent typography.
- Never invent icons.
- Never redesign an approved screen.
- Generate Flutter code consistent with the project's existing structure and conventions.

---

## Code Quality

- Use meaningful naming for variables, functions, classes, and files.
- Keep widgets small and focused on one responsibility.
- Separate UI from business logic.
- Avoid duplicated code — extract and reuse instead.
- Follow Flutter/Dart best practices and idioms.
- Keep imports organized.
- Maintain `flutter analyze` with **zero** issues at all times.

---

## Pull Requests

Before opening a pull request, verify:

- [ ] The implementation matches the approved Figma screens.
- [ ] All required states exist for the screen(s) touched.
- [ ] Both Light and Dark themes are verified.
- [ ] Responsive behavior is verified (320px, 375px, 428px).
- [ ] `flutter analyze` passes with zero issues.
- [ ] No unrelated files were modified.

---

## Prohibited Practices

Do not:

- Hardcode colors.
- Hardcode spacing.
- Hardcode typography.
- Import another icon library.
- Create duplicate components.
- Modify another contributor's module without approval.
- Redesign approved UI.
- Commit broken code.
- Ignore analyzer warnings.

---

## Definition of Done

A feature is complete only when:

- [ ] Implementation matches the approved designs.
- [ ] The Design System is fully respected — no hardcoded values, no invented tokens.
- [ ] All required states exist.
- [ ] Accessibility requirements are met.
- [ ] `flutter analyze` passes.
- [ ] Code has been reviewed.
- [ ] The feature is ready for merge into `test`.

---

Consistency is more important than creativity.

Every contributor and every AI assistant must build CivicVoice as **one unified application** — not six separate projects.
