# Kingsben - Flutter Maintenance and Municipal work pack

Issued 31 October 2026. Owner: Kingsben (historical repository name: Kingsbeng).
This is the current allocation for Kingsben and his assisting agent. It replaces
older Kingsbeng branch/start/ownership instructions for this assignment only.

## Start here

| Item | Agreed value |
| --- | --- |
| Editable repository | `https://github.com/khakho3/civic_voice` |
| Task branch | `codex/flutter-kingsbeng-maintenance-municipal` |
| Starting working branch and PR target | `codex/flutter-latif-review-fixes` |
| Verified source checkpoint before this packet | `e56bb2f051a648aadac62c8955df3083090f2013` |
| Web reference, read-only | `https://github.com/FranzAfun/civic-voice-web`, `codex/web-api-integration` |
| Pinned web reference at issue | `236bda3e0ceb2d946bd19d21f82d1bc03a67f9e7` |
| Your progress record | `docs/flutter-alignment/KINGSBENG_PROGRESS.md` |
| Human brief | [One-page assignment](../../output/pdf/kingsben-flutter-assignment.pdf) |

PR #20 was Latif's original `codex/flutter-latif-modules` submission. Francis
authorized closing it without merging on 31 October. Its `82d11cd` commit is
already an ancestor of our working branch, which contains the later repairs.
The older `main`, `codex/flutter-web-alignment` and `codex/flutter-kingsbeng-workflow`
branches are not this assignment's starting points or PR target.

## Repository and environment boundaries

1. Identify Kingsben's actual local Flutter and web checkout paths. Use the
   workspace context when available; ask for missing paths rather than assuming
   another developer's filesystem. Read applicable `AGENTS.md` files and this
   guide before edits. Check branch, HEAD and existing changes in each checkout.
2. The web repository is **reference only**. Do not edit its source, docs, assets,
   configuration, dependencies or lockfiles. Do not commit, push or create a
   branch there. Read the pinned reference or an existing approved preview;
   record the reference SHA. Do not replace native live behavior with web mocks.
   If the local web checkout has owner changes, leave them intact. A web defect
   goes into your blocker/findings list, not a web patch.
3. All implementation belongs on your named Flutter task branch. Keep the base
   branch read-only; do not push into it or into `main`. Preserve existing work,
   untracked branding/private files and contributor commits. No reset/clean,
   force push, branch deletion or blind recreation of an existing branch.
4. **No API repository or backend work.** No database, schema, endpoint, payload
   contract, authorization, role/account, Firebase, Cloud, Maps-key, signing,
   app identity or deployment changes. Existing endpoints may be consumed
   unchanged in an approved DEV setup. Report backend blockers to Francis and
   continue independent client work.
5. Start with isolated fixtures when safe DEV access is unavailable. Never use
   production credentials or real accounts/reports to manufacture test states.
   Live workflow writes require owner-approved synthetic DEV records/accounts;
   the assignment alone does not authorize changing real data. Do not start,
   stop or reconfigure Francis's API process. Do not copy another developer's
   local Firebase files, secrets or machine configuration into Git.
6. Before any phone build/install, obtain the approved isolated DEV setup and
   verify package, Dart/native Firebase, effective API URL, signing and Maps
   identity together. DEV is `com.example.civic_voice.dev`, `Civic Voice DEV`,
   Firebase `civic-voice-dev-11d98`, with the verified local DEV API/database.
   This is not permission to change tracked production configuration. Preserve
   installed app data and the production app. Do not assume Francis's LAN IP
   or phone serial works on your computer.

## Branch setup

The task branch is published with this packet. From a clean Flutter checkout:

```powershell
git status --short --branch
git fetch origin codex/flutter-latif-review-fixes codex/flutter-kingsbeng-maintenance-municipal
git switch --track origin/codex/flutter-kingsbeng-maintenance-municipal
git merge-base --is-ancestor e56bb2f051a648aadac62c8955df3083090f2013 HEAD
git status --short --branch
```

If the local task branch already exists, inspect it and any unpushed commits.
Switch only when safe. A fast-forward from its own remote is allowed after
inspection; divergence must be reported, never erased. Do not automatically
merge another branch into it. If the published task branch cannot be fetched,
report that setup blocker instead of starting from old main/integration.

The owner authorizes scoped commits, tested normal pushes to this task branch
and a PR targeting `codex/flutter-latif-review-fixes` for this work pack. Francis
will review and decide whether to merge. Do not merge or promote anything.

## Work in this order, one complete slice at a time

These features are already implemented. Verify current source and behavior,
record reproducible defects, then make the smallest client repair. Do not
rebuild services because an older repair report calls them missing. Work
through all three slices; leave genuine blockers open and labelled.

### 1. Maintenance client workflow - queue 02, T01-T04

Cover Dashboard -> Assigned Tasks -> Task Details -> Update Progress ->
submitted/returned/completed outcomes, with real list-to-record context.

- Check pending/open counts and supported filters, search/Close/Back, retained
  query/scroll, refresh of short/empty/populated lists, and loading/error/retry.
- Verify returned reasons, actual evidence counts/gallery, current permitted
  task/team data and honest timeline/status wording. Pending and resolved
  tasks must keep their existing read-only behavior.
- Check camera/gallery cancellation and permission failure; photo add/remove/
  replace; notes retention; field-error focus; keyboard visibility; discard
  confirmation; busy/duplicate taps; interrupted/failed/uncertain submissions.
  Preserve user input and the existing authoritative-refresh-before-retry path.
- Preserve the current completion contract: exactly three distinct new valid
  uploads, 10-2000 character notes, explicit 100% progress and an already-started
  task. Historical photos cannot replace new evidence after send-back. These
  are existing contracts to test, not policy to redesign. See
  [evidence/completion reconciliation](../flutter-alignment/NATIVE_EVIDENCE_AND_COMPLETION.md).
- Successful crew submission means awaiting officer confirmation, not resolved.
  Check server-acknowledged results, cancelled/failed outcomes and system Back;
  Back must not resurrect a submitted editable form.

Primary files: `lib/features/maintenance/screens/dashboard_screen.dart`,
`assigned_tasks_screen.dart`, `task_details_screen.dart`,
`update_progress_screen.dart`, `task_completed_screen.dart`, plus the module's
existing presentation widgets. T05 is limited to checking existing in-app
task notices/navigation; server notification delivery and FCM are outside scope.

### 2. Municipal client workflow - queue 03, M01-M06 client scope

Cover Dashboard/Inbox -> Report Review -> Verification -> Assign Team, then
Active Reports -> Report Progress -> approval/send-back -> final details.

- Check real record IDs/caller context, claim conflicts, ownership changes,
  loading/missing/forbidden/offline/retry states and disabled unauthorized
  actions. A visual client guard does not prove server authorization.
- Verify existing checklist/rejection-category/reason controls, selected-team
  confirmation/cancellation, permitted contacts and authoritative assignments.
  Preserve input on failure and avoid claiming success before acknowledgement.
- Check pending evidence display, approve confirmation/cancel, required send-back
  reason, returned-work display, current timestamps and list/detail refresh.
  Officer progress remains monitoring; do not reintroduce officer evidence
  upload or a direct Mark Resolved shortcut.
- Verify resolved/rejected presentation, existing photo gallery and share
  dismissal/failure feedback. Keep unavailable Archive/public-hosting features
  honestly unavailable. No public sharing infrastructure or policy changes.
- Test the client against existing success, 409/conflict, denied, missing and
  uncertain responses using isolated fixtures. Log any server-contract defect.

Primary files: `lib/features/municipal/screens/municipal_dashboard_screen.dart`,
`municipal_inbox_screen.dart`, `municipal_report_review_screen.dart`,
`municipal_verification_screen.dart`, `municipal_assign_team_screen.dart`,
`municipal_active_reports_screen.dart`, `municipal_report_progress_screen.dart`,
`municipal_resolved_reports_screen.dart`, `municipal_resolution_details_screen.dart`
and their existing module presentation widgets.

### 3. Maintenance/Municipal layout and state review - queue 23 subset

Review only the two modules above. This is not ownership of the full 59-screen
inventory or shared Profile/auth/Admin/Citizen/Ministry work.

- Check 320/390/412px and a wide layout, both themes, 1x/1.5x/2x text where
  supported, realistic safe areas, keyboard, long content and actual
  loading/empty/error/refresh/returned/pending states relevant to each view.
- Compare with the accepted web reference and current native behavior. Preserve
  solid/grouped cards, typography/contrast, Ghana loaders/PTR, native filter
  bounce/checkmark, haptics preference, tap feedback, reduced motion and native
  Back. Keep the shared search rail/query/focus/scroll restoration stable.
- Repair demonstrated clipping, inaccessible controls or state/layout defects
  within module presentation files. Keep all permitted information available;
  do not add blanket cards or make a new visual system.
- The owner's future long-information/info-button idea (including Audit Detail)
  and Citizen bottom-navigation overflow are deferred. Do not implement them.

## Allowed files and escalation

Edit the named Maintenance/Municipal screen files, their existing module-local
presentation widgets and relevant tests. Exclude Profile and shared inbox/
notification infrastructure. Maintain only your progress document for reporting.

Read module models/services, shared widgets and API calls to understand behavior,
but report a required change outside the allowed presentation scope before
editing it. In particular, do not change `lib/main.dart`, `lib/services/`,
`lib/models/`, `lib/core/`, `lib/widgets/`, module models/services, platform files,
dependencies or lockfiles. Do not fork a shared component locally to bypass this
boundary. Francis coordinates any necessary shared-file work.

## Validation and evidence

Record a baseline before editing. Use the repository's compatible Flutter SDK.
If dependency setup is needed, run `flutter pub get` and inspect the diff; report
unexpected lock/platform churn rather than committing it. Relevant existing
tests include:

```powershell
flutter analyze --no-pub
flutter test --no-pub test/maintenance_widget_test.dart test/maintenance_update_service_test.dart test/maintenance_api_mapping_test.dart test/kingsbeng_workflow_regression_test.dart
flutter test --no-pub test/municipal_widget_test.dart test/municipal_api_mapping_test.dart test/municipal_detail_header_scaling_test.dart test/municipal_closed_evidence_gallery_test.dart
git diff --check
```

Add meaningful regressions for confirmed defects and rerun the affected checks.
Before final publication, run the full Flutter suite and analyzer on the exact
candidate. Report failures and their provenance honestly; do not remove tests
or weaken assertions merely to make a run green. No web/API tests or source
changes are required for this Flutter-only assignment.

For each slice, record in `docs/flutter-alignment/KINGSBENG_PROGRESS.md`:

- Backlog ID, screen/route, state, reproduction and actual changed files.
- Preserved contracts, reference SHA and meaningful tests/results.
- Fixture/render evidence separately from actual device/model/OS checks.
- Built, verified, blocked, deferred and owner-accepted status separately.
- Backend/shared-file blockers, including affected request/response behavior
  without credentials, personal data or private logs.

Screenshots/renders should show both themes and representative narrow/large-text
and failure states. A passing test, render, install or teammate phone check is
not Francis's acceptance of the whole workflow. No test run is claimed by the
issuance of this packet.

## Commit, push and PR handoff

Use scoped commits per slice or defect. Review the staged diff for unrelated
changes and secrets. Push only your task branch after the required checks pass:

```powershell
git push --set-upstream origin codex/flutter-kingsbeng-maintenance-municipal
```

Open one PR in `khakho3/civic_voice` with head
`codex/flutter-kingsbeng-maintenance-municipal` and base
`codex/flutter-latif-review-fixes`. Suggested title:
`fix(flutter): verify Maintenance and Municipal client flows`.

The description must cover all three assigned slices, actual fixes, changed-file
ownership, tests, screenshot/device evidence, remaining blockers and deferred
items. A slice with no reproduced defect can be reported as checked, with
evidence; do not invent a change. Do not call a backend-blocked workflow complete.
Then stop for Francis's review. No self-merge, integration/main promotion,
deployment, production installation or branch deletion.
