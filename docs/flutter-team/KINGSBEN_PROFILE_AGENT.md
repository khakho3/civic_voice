# Kingsben's Flutter Profile review

Issued 6 November 2026. This assignment covers queue items 16 and 21 and the
Flutter portion of 17. Work through the three slices below in order. Start with
the current screens and fix reproducible defects. Preserve accepted layouts,
navigation and live data.

| Reference | Value |
| --- | --- |
| Flutter repository | https://github.com/khakho3/civic_voice |
| Task branch | `codex/flutter-kingsben-profile-review` |
| PR target | `codex/flutter-latif-review-fixes` |
| Starting baseline | `af8f08898f86d957c016f14f371875ac92d318de`, includes Ministry squash `218e418` |
| Web repository | https://github.com/FranzAfun/civic-voice-web |
| Read-only web reference | `b50586dd24f744ecbe64d75dc865ed4fa9ad408d` |
| Progress and handoff | [KINGSBEN_PROFILE_PROGRESS.md](../flutter-alignment/KINGSBEN_PROFILE_PROGRESS.md) |
| One-page brief | [Kingsben's Profile assignment](../../output/pdf/kingsben-profile-assignment.pdf) |

Read applicable AGENTS.md, DEVELOPMENT_RULES.md and DESIGN_SYSTEM.md. This
assignment specifies the working branch and scope in place of older main-first
instructions. From a clean checkout, fetch the task and target branches and use
the published task branch. If it already exists locally, inspect its status and
history before switching or fast-forwarding. Keep unrelated and untracked work.

```powershell
git status --short --branch
git fetch origin codex/flutter-latif-review-fixes codex/flutter-kingsben-profile-review
git switch --track origin/codex/flutter-kingsben-profile-review
git merge-base --is-ancestor af8f08898f86d957c016f14f371875ac92d318de HEAD
```

Read the pinned web tree with `git show`. Useful references are P01–P05 and C01
in `docs/FLUTTER_OWED_BACKLOG.md`, the Profile components, and the actual role
routes. Web is reference only, including its code, docs, dependencies and
configuration. A fetch can update its Git metadata. If the pinned ref is
unavailable, record it and continue with verified native references.

## 1. Profile across roles

Check Citizen, Guest, Municipal, Ministry, Maintenance and both Admin tiers.
Verify real identity fields, permissions and Back from About, Notifications and
Change Password. Cover missing fields, Maintenance lead/non-lead/unassigned
states, and Guest without fake phone, edit or standing. Preserve the current
grouped rows, avatar edit entry, logout confirmation and role-specific
preferences. Check large text, keyboard and a short viewport. Preserve the
native App Lock capability and settings behavior.

## 2. Name editing and save feedback

Keep the editor limited to the fields the current API allows. Check validation,
cancel, dismissal, focus return, double submission and pending responses. Show
success only on an acknowledged save. Distinguish a verified rejection from a
timeout, disconnect or other unconfirmed outcome. Keep entered text and offer a
safe way to recheck. If the callback collapses outcomes to a boolean, use
truthful neutral feedback and record the limitation instead of guessing.
Preserve the existing session and namespace fences, including same-UID
reactivation. Exercise a late result after an account change.

## 3. Citizen standing on Home and Profile

Use labelled fixtures for a low, fractional, highest and missing server value.
Check Home-to-Profile agreement, pull-to-refresh, resume, stale responses and
Guest exclusion. Preserve the compact Home layout the owner accepted. Use the
existing server-owned value and thresholds. Keep standing off officer review
surfaces. If proof depends on the real provider, record a device acceptance step
instead of changing any account or report to manufacture the state.

## Boundaries

Editable scope is the five role Profile screens, their Profile-specific
presentation/model code, `lib/widgets/profile_*.dart`, Citizen standing
presentation and existing Profile read handling, plus focused tests and the
progress record. On Citizen Home, limit edits to the standing integration.
Shared Profile components are used by every role. Test their affected consumers.

Reserve API work, permissions, role changes, scoring, auth/session policy,
production configuration, notification and push flows, generic shared controls
and app-shell routing for Francis. Record a specific proposed integration fix if
blocked outside the assignment. Use isolated fixtures and keep real accounts,
reports, device settings and saved drafts intact. Any optional physical check
requires the approved isolated DEV setup and an available device.

## Evidence and delivery

Record the exact baseline, commands and failure names before changing code.
Check both themes, 320/390/412/768 px and representative 1x/1.5x/2x text.
Use rendered content and behavior assertions. Add regressions for reproduced
bugs and restore test singleton/platform state. Run affected tests, the full
Flutter suite, analyzer and whitespace check on the final candidate. Report
physical/owner confirmation separately from fixtures.

Use scoped commits and push only the task branch after checks. Open one PR into
`codex/flutter-latif-review-fixes` with the final behavior, test counts and any
remaining blockers. Stop for Francis's review. Merging, branch cleanup and
deployment remain with the integrator.
