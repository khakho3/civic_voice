# Kingsben - Flutter Ministry client review and repair

Issued 1 November 2026. One assignment: queue 27, V01-V04, with Ministry-only
layout/state coverage from queue 23. This supersedes the completed PR21 work pack.
Finish one slice before starting the next. Existing screens/services are present;
verify them, reproduce defects, then make small client repairs. Do not rebuild.

## Branches and references

| Item | Value |
| --- | --- |
| Editable repo | `https://github.com/khakho3/civic_voice` |
| New task branch | `codex/flutter-kingsben-ministry-review` |
| Base and eventual PR target | `codex/flutter-latif-review-fixes` |
| Verified native checkpoint before this packet | `3de411399943037ebf206da263845c6a43e564a6` |
| Included prior integration | PR21 squash `c89a8a4`, item05 `732ef9d` |
| Web reference repo | `https://github.com/FranzAfun/civic-voice-web` |
| Pinned web reference | `1c9624126904d4000c085c93373e7f88d976c90f` on `codex/web-api-integration` |
| Your progress record | `docs/flutter-alignment/KINGSBEN_MINISTRY_PROGRESS.md` |
| Human brief | [One-page brief](../../output/pdf/kingsben-ministry-assignment.pdf) |

The human brief uses the original contributor pack's charcoal/gold palette. Its
1 November color correction preserves every word and the verified single page.

Old `codex/flutter-kingsbeng-maintenance-municipal` is deleted after PR21. Do not
recreate it or resume an old module/integration/main branch. Determine actual
checkout paths on your computer; never assume Francis's paths or device details.
Read applicable AGENTS.md, this guide, DESIGN_SYSTEM.md and DEVELOPMENT_RULES.md.
This owner's current branch/ownership packet supersedes older main-first or
feature-branch instructions. Preserve all existing/untracked work.

From a clean native checkout:

```powershell
git status --short --branch
git fetch origin codex/flutter-latif-review-fixes codex/flutter-kingsben-ministry-review
git switch --track origin/codex/flutter-kingsben-ministry-review
git merge-base --is-ancestor 3de411399943037ebf206da263845c6a43e564a6 HEAD
git status --short --branch
```

If a local task branch exists, inspect its changes/commits before switching or
fast-forwarding. Report divergence; never reset/clean/force-push or erase work.
The published task branch includes this packet; no automatic merge/rebase from
another branch. Missing setup/reference is a recorded blocker, not permission to
start from a stale branch.

## Hard boundaries

- Flutter Ministry client only. No API repo/backend, database/schema/migration,
  endpoint/payload contract, permission/role/account policy, AI/scoring, Firebase,
  Cloud/Maps keys, signing, identity, production or deployment changes.
- Web is read-only reference, including its source/docs/assets/config/dependencies.
  Do not write files, install dependencies, run formatting/builds that write there,
  commit/push/create branches, or checkout/reset its owner worktree. Read the pinned
  tree with `git show`. A normal fetch for that reference may update Git metadata,
  never worktree files. Report missing pinned reference; don't silently use an old
  preview. Live pages use `src/pages/MinistryApi.jsx`; preview/sample pages are not
  the live API contract. Relevant web test: `MinistryApi.test.jsx`.
- Allowed native changes: six Ministry screens below, Ministry models, the Ministry
  data directory for reproducible client-only shaping defects under existing
  contracts, `region_picker_chip.dart`/`ministry_scaffold.dart`, task-specific tests,
  and your progress record. Shared components are consumed, not redesigned.
- `lib/main.dart`, auth/session policy, API client, shared widgets/theme/models,
  Municipal/Maintenance/Admin/Citizen source and their directories are outside this
  pack. If a fix needs those files, record a small proposed integration change for
  Francis and continue independent work. Never weaken session/provenance guards.
- Actor-locality audit, Assembly Admin mutation reports, Activity PTR positioning,
  info buttons, ordinary-success redesign, digests, notifications/Profile, public
  sharing, AI/advisory, release readiness and global cleanup are not your tasks.
- Never mutate real accounts/roles/reports to manufacture QA states. Start with
  isolated labelled fixtures and unreachable loopback test APIs. Live writes need
  approved synthetic DEV data; this read-only Ministry pack does not authorize them.
  Do not start/stop/reconfigure Francis's API or copy private DEV credentials.
- Any permitted device install needs the approved isolated DEV setup verified as
  a whole: package/label, Dart + native Firebase, effective API/database, signing
  and Maps restrictions. Do not change tracked production files or clear app data.

## Work in this order

### 1. National Dashboard and Analytics - V01/V02

Files: `ministry_dashboard_screen.dart`, `ministry_analytics_screen.dart`, related
models and `services/ministry_data_directory.dart` under `lib/features/ministry/`.

- Preserve the shared confirmed report/contact snapshot, latest-read/session
  fences and cached-on-failure behavior. Confirmed empty means true zeros; missing
  or failed data must not become a successful sample dashboard.
- Verify all seven statuses, pending approval in open workload, coherent totals,
  actual selected periods and labels/units. Don't invent percentage changes,
  denominators, historic comparison data, trends or new aggregation policy.
- Verify date/dimension controls remain accessible, cancel retains selection,
  refresh/retry doesn't flicker or lose state, and origin drill-down/Back works.
  Use existing shared search/loading/filters. No center loading animation.

### 2. Municipal Performance and Municipality Detail - V03/V04

Files: `ministry_municipal_performance_screen.dart`,
`ministry_municipality_detail_screen.dart`, related Ministry models and picker.

- Verify region/scope/metric filters, search/no-match, cancelled picker selection,
  pinned control access, wrapped >=44px targets and narrow/large-text readability.
- Open the actual municipality; Back retains originating context, filters and
  scroll. Distinguish missing municipality, no contacts and unavailable contacts.
- Preserve real officer contact permissions and dial/SMS cancel/failure feedback.
  Never invent staff, actions, contact fields or a backend endpoint.

### 3. Reports Overview and Report Insights - V04

Files: `ministry_reports_screen.dart`, `ministry_report_insights_screen.dart` and
related models. Preserve read-only report rows and deterministic insights.

- Verify search/history/filter interactions, all seven statuses, real period/
  category/status data and coherent unfiltered national summaries.
- Long titles, status/date badges, chips and summaries must fit phones, keyboard,
  both themes and 1x/1.5x/2x text. Existing rows stay static where no action exists.
- Empty, no-match, unavailable, cached/offline, unauthorized and retry states must
  be truthful. Unbuilt Focus Summary stays honestly disabled with an explanation.
  Don't present deterministic insight as AI or introduce a new approval workflow.

## Evidence and tests

First inspect current code and `docs/FLUTTER_OWED_BACKLOG.md` V01-V04 in the pinned
web tree. Those older PORT labels are review prompts, not proof of missing code.
Read existing tests before writing new ones:

```powershell
flutter test --no-pub test/ministry_widget_test.dart test/ministry_live_data_test.dart test/ministry_data_directory_test.dart test/ministry_dashboard_provenance_test.dart
flutter analyze --no-pub
git diff --check
```

Use the installed approved SDK/lockfile. Do not upgrade dependencies or rewrite
pubspec.lock to avoid a failure. Report missing setup. Add meaningful regressions
for demonstrated defects. Don't weaken tests, hide fixture mistakes or conflate
isolated screens with real route/live/platform acceptance.

Cover 320/390/412/768px, both themes and representative 1x/1.5x/2x text plus keyboard,
Back, cancelled filters, short/empty/populated data and failures. Prefer loaded
fixtures with unique visible content assertions; a no-exception render alone does
not prove the intended state. Restore every mutated singleton/flag in teardown.
Record viewports/states, actual data source, private captures and exact test counts.
Physical checks require real device evidence and remain separate from fixtures.

Before final publication run the full Flutter suite, analyzer and whitespace check
on the exact candidate. Record any pre-existing failures with evidence; don't call
all-role acceptance complete. No API/web source or tests are part of this task.

## Deliver and stop

Record each slice's checked paths/states, reproduction, fixes, changed files,
reference SHA, test commands/results and remaining blockers in your progress file.
Separate implemented/automated/device/owner-accepted. A slice without a reproduced
defect can be verified with evidence; don't invent changes to fill a checklist.

The owner authorizes scoped commits, tested normal pushes only to this task branch,
and one PR onto `codex/flutter-latif-review-fixes`. Suggested PR title:
`fix(flutter): verify Ministry screens and data states`.
Explain final behavior, tests, render/device evidence and genuine blockers.
Then stop for Francis's review. No self-merge, branch deletion, promotion/deployment
or unrelated work. The owner/integrator handles reserved Admin/API fixes separately.
