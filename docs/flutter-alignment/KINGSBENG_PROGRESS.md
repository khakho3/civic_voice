# Kingsbeng repair progress — 14 October 2026

## Coverage/correctness follow-up — 31 October 2026

Status: **READY FOR SCOPED OWNER APPROVAL**. Earlier fixes preserved; no Git
publication. This is not full-suite or physical-device release acceptance.
This entry corrects the original rendering-only matrix's coverage claims.

### Navigation reproduction and repair

Before repair, three new regressions failed: status-only and whitespace-only
edits left without confirmation; after confirming exit through a no-op `onBack`,
subsequent system Back bypassed confirmation. The two original notes cases
passed (red run: 2 passed, 3 failed; `%TEMP%\civic-review-draft-red.log`).

`update_progress_screen.dart` now compares status with the initial editor status
(including existing assigned-to-in-progress normalization), updates that baseline
on successful save, and treats raw nonempty notes as draft input. It clears the
one-attempt pop permission in `finally` if still mounted. Explicit Discard Draft
uses the same dirty check and restores status; confirmation copy mentions status.
Submission still trims notes and retains evidence/length/ownership/workflow rules.

`maintenance_draft_navigation_test.dart` retains both original notes tests and
adds those three reproduced paths plus status-revert and explicit-discard tests.
Coverage includes header/system Back, Cancel, confirmed exit, a non-popping
callback, and restoration of clean status. Missed gesture warnings are fatal.

### Audit of the original 264 cases

Source audit: `test/flutter_test_config.dart` sets a loopback API URL but does
not seed directories or initialize Firebase. Without Firebase the task directory
starts with five mocks, and the report directory with seven mocks. Maintenance
dashboard/tasks/editor, Municipal inbox/active and dashboard recent reports
therefore used preview records in an isolated run. Dashboard counters/assignment
summary used canned aggregates. Review, verification and assignment used mock
detail payloads because preview reports lack API IDs. Resolved list/details used
`ResolvedReportItem.mock()`. The team directory starts **empty**: assignment's
loaded report body displayed **"No teams match your search."**, not team cards.
The old matrix only asserted exceptions, so its historical passes did not prove
visible populated content or isolate singleton state.

The revised `kingsbeng_screen_layout_test.dart` retains all 11 screens × 4 widths
× 2 themes × 3 text scales. Each case explicitly seeds an active maintenance task,
submitted/in-progress/resolved reports and an available repair team. Unique IDs
and titles, fixed timestamps and no remote image URLs provide deterministic data.
API IDs select report projections; an existing reviewer prevents auto-claim.
`hasLiveSnapshot` selects directory-backed resolved records/dashboard aggregates.
Every modified directory value, loading/error/snapshot flag, changed-reference
set and verification-draft map is saved/restored for each case.

Each screen must visibly display its fixture title; relevant details also assert
citizen/checklist/team/resolution-note content. Targets are scrolled into view
and checked with `hitTestable()`, including the populated assignment team card.
Exception checks remain before/after scrolling. The final gesture uses the outer
scrollable, replacing `.last` which could select an offscreen non-scrollable stat
grid. Missed gestures are fatal. These are loaded-fixture checks, not exhaustive
empty/error/offline/photo/native-device coverage.

### Follow-up validation and boundaries

- Seven navigation tests + 264 populated layout cases: **271 passed**, 1:18;
  `%TEMP%\civic-review-verified.log`. No missed-gesture warnings.
- Other 10 focused files: **243 passed**, 1:09;
  `%TEMP%\civic-review-focused.log` (the earlier 12-file list minus these two).
- Total focused coverage: **514 passed** across the same 12 files, run as the
  271-case follow-up group and 243-case surrounding-regression group.
- `flutter analyze --no-pub`: **no issues**, 150.1s;
  `%TEMP%\civic-review-analyze.log`.
- `git diff --check`: **passed**, exit 0.
- Existing `pubspec.lock` blob remains
  `8848f51b60e2b31570a74d1cb14afff67d6fd75b`; no edit/revert.
- This follow-up edits only the editor, the two tests, and this document.
  No Ministry/biometric/shared/configuration/backend changes or publication.
- Earlier full-suite failures, physical DEV acceptance and pinned-web comparison
  blockers below remain. Full suite not rerun for this scoped follow-up.

## Scoped engineering review — 31 October 2026

Status: **FIXED (local changes), OWNER ACCEPTANCE PENDING**. This entry supersedes
the assignment's historical "not started" status below. No commit, push, PR,
branch switch, installation, account change or live workflow write was performed.

### Repository and evidence boundary

- Task branch verified: `codex/flutter-kingsbeng-maintenance-municipal`.
- Starting HEAD: `5302c8ec181ae3a2ec2aba3d7c2eedf6d9258f84`.
  `e56bb2f051a648aadac62c8955df3083090f2013` is an ancestor (exit 0).
- Existing user change: `pubspec.lock` (matcher, meta, test_api and vector_math
  versions). Preserved; no dependency resolution or SDK upgrade performed.
- Installed SDK: Flutter 3.44.6 / Dart 3.12.2, framework `ee80f08bbf`.
  Results describe this installed SDK and existing dependency state.
- Read the 31 October agent guide and native evidence/completion reconciliation;
  the older development guide's branch-switch instructions are superseded.
- Read-only web checkout: `C:\Projects\web\civic-voice-web`, clean,
  `feature/municipal-module`, HEAD `391072f2c795577873ead9a27e0f97462de994c5`.
  Required reference `236bda3e0ceb2d946bd19d21f82d1bc03a67f9e7` is absent locally.
  **BLOCKED / NOT VERIFIED:** comparison against that pinned web revision.
  No web changes or fetch performed.
- **BLOCKED / NOT VERIFIED:** physical DEV acceptance. The complete approved
  package/Firebase/API/database/signing setup and synthetic accounts were not
  established. Earlier phone installations are not reused as acceptance evidence.

### Slice 1 — queue 02, T01–T04

**VERIFIED (automated baseline):** 68 tests passed across
`maintenance_widget_test.dart`, `maintenance_update_service_test.dart`,
`maintenance_api_mapping_test.dart`, and `kingsbeng_workflow_regression_test.dart`.
Coverage includes record-specific navigation, pending/open workflow, evidence
gallery, validation, field issues, send-back history, matching acknowledgements,
duplicate writes and ownership changes. Some existing tests exercise Profile or
notifications; their files and implementation were not changed.

**FIXED — T01 refresh:** pull down on an empty Assigned Tasks view: no scrollable
existed. Pull down on dashboard or task list with the supplied refresh callback:
the callback was bypassed. Four gesture regressions failed before repair and
passed afterward. Both screens now use their existing `_reload` handler; the
empty list uses an always-scrollable sliver with existing chrome insets.

**FIXED — T03 draft navigation:** enter notes, then tap header Back or invoke
system Back: the editor previously disappeared without confirmation. Both
regressions failed before repair. `PopScope` now protects dirty drafts and busy
saves; Cancel preserves notes, Discard exits. Existing explicit Discard Draft
and successful submission navigation remain covered by the original tests.

Files: `lib/features/maintenance/screens/assigned_tasks_screen.dart`,
`dashboard_screen.dart`, `update_progress_screen.dart`;
`test/maintenance_refresh_regression_test.dart` (new),
`test/maintenance_draft_navigation_test.dart` (new).

Contracts preserved: exactly three distinct valid new uploads, 10–2000 character
notes, explicit 100% progress, start before completion, historical evidence not
substituting for new evidence, and submission awaiting officer confirmation.
No service/model/API contract was edited. The existing service can start an
assigned task before submitting; that sequencing was not changed.

**NOT TESTED in this pass:** native camera/gallery cancellation and permission
dialogs, process death/lost picker recovery, photo removal/replacement on a real
device, exhaustive failure/keyboard/long-content combinations. Photo addition,
validation and gallery navigation have fixture coverage, not device evidence.

### Slice 2 — queue 03, M01–M06

**VERIFIED (automated baseline):** 142 tests passed across municipal widget,
mapping, detail-header scaling and closed-evidence-gallery groups. Existing
tests cover checklist/rejection controls, assignment selection/confirmation,
search/route context, read-only monitoring, approval cancellation, required
return reason, rejected/resolved presentation and gallery navigation.

**FIXED — M03 uncertain decision recovery:** open Send Back, enter a reason,
change the isolated record from pending to in-progress while the sheet is open,
then submit. The service rejects the stale decision. After restoring an
authoritative pending fixture and refreshing, the old failure message remained
and reopening Send Back lost the reason. Added regression failed before repair
and passes after it. The screen retains the submitted reason, clears stale
feedback after successful refresh, and disables approval/send-back retries until
refresh succeeds. Successful acknowledged decisions clear the draft.

Files: `lib/features/municipal/screens/municipal_report_progress_screen.dart`,
`test/kingsbeng_workflow_regression_test.dart`.

**VERIFIED (transport fixtures):** 12 new tests in
`test/municipal_transport_outcomes_test.dart` cover claim/decision success,
403, 404, 409, 500 and socket loss. Zone-injected in-memory HTTP clients intercept
all calls; error status/message are retained and no automatic retry occurs.
These are transport tests, not proof of live server authorization or complete
screen handling of every HTTP error. **NOT TESTED:** live claim races, role
changes, share-sheet dismissal/failure on-device, and every uncertain decision
screen path. Monitoring-only officer behavior and unavailable Archive/public
hosting remain unchanged.

### Slice 3 — queue 23, Maintenance/Municipal only

**Historical rendering result (see follow-up limitations above):** initial
264-case default-state matrix plus
the expanded 24-case pending/approval matrix cover all 14 permitted screens at
320/390/412/768px, light/dark, 1x/1.5x/2x, and top/bottom safe-area padding.
The loaded-screen matrix also scrolls below the initial viewport. Initial
loaded-screen run: 156 passed, 108 failed; pending matrix: 14 passed, 10 failed.
The failures exposed fixed-height cards/navigation and unbounded text rows.
No failure assertion was removed or suppressed.

Corrections use existing typography, tokens, badges, cards and controls:

- Maintenance dashboard: scale stat-card/chart room; constrain task status.
- Assigned Tasks: constrain status beside the task title.
- Task Details: wrap team/status metadata and constrain photo/location headings.
- Municipal dashboard: adapt stat layout for enlarged text, constrain status and
  team summary; retain the existing column count at normal scale.
- Inbox: wrap status/time and constrain category metadata.
- Active Reports: constrain count/status; wrap progress label/value.
- Report Review and Verification: constrain headings and citizen names.
- Progress: wrap completion label/value.
- Closed Reports and Resolution Details: constrain/wrap dates and actions.
- Existing module-local `municipal_scaffold.dart`: scale bottom navigation and
  its matching content inset; keep labels on one line with full text semantics.

Exact layout files are the corresponding named screen paths under
`lib/features/maintenance/screens/` and `lib/features/municipal/screens/`, plus
`lib/features/municipal/widgets/municipal_scaffold.dart`. No shared component was
duplicated or edited. Tests: new `test/kingsbeng_screen_layout_test.dart` and
expanded `test/kingsbeng_workflow_regression_test.dart`.

**NOT TESTED:** pixel/screenshot acceptance, TalkBack/VoiceOver, every long-name
and keyboard/state permutation. A no-overflow widget render is not a complete
accessibility audit. **DEFERRED:** information-button design, public sharing
infrastructure, and other contributors' modules.

### Final validation and handover

Changed production files (all permitted presentation ownership):

```text
lib/features/maintenance/screens/assigned_tasks_screen.dart
lib/features/maintenance/screens/dashboard_screen.dart
lib/features/maintenance/screens/task_details_screen.dart
lib/features/maintenance/screens/update_progress_screen.dart
lib/features/municipal/screens/municipal_active_reports_screen.dart
lib/features/municipal/screens/municipal_dashboard_screen.dart
lib/features/municipal/screens/municipal_inbox_screen.dart
lib/features/municipal/screens/municipal_report_progress_screen.dart
lib/features/municipal/screens/municipal_report_review_screen.dart
lib/features/municipal/screens/municipal_resolution_details_screen.dart
lib/features/municipal/screens/municipal_resolved_reports_screen.dart
lib/features/municipal/screens/municipal_verification_screen.dart
lib/features/municipal/widgets/municipal_scaffold.dart
```

Changed tests: `kingsbeng_workflow_regression_test.dart`; new tests:
`kingsbeng_screen_layout_test.dart`, `maintenance_refresh_regression_test.dart`,
`maintenance_draft_navigation_test.dart`, `municipal_transport_outcomes_test.dart`.
All are under `test/`. The only other agent edit is this progress document.
The pre-existing lockfile diff remains byte-for-byte at Git blob hash
`8848f51b60e2b31570a74d1cb14afff67d6fd75b` (same `8848f51` as the initial diff).

The continuation request arrived during final failure classification. Existing
context, branch, guide, progress record and diffs were recovered/rechecked;
implementation was not restarted. All three slices had reached validation.

| Final check | Actual result |
| --- | --- |
| `flutter analyze --no-pub` | **VERIFIED:** no issues, 107.8s |
| All 12 focused test files (listed below) | **VERIFIED:** 509 passed, 2:04 |
| `flutter test --no-pub --reporter expanded` | **FAILED:** 1,829 passed, 98 failed, 6:42 |
| `git diff --check` | **VERIFIED:** exit 0 |
| Git publication / physical installation | Not performed |

Focused command: `flutter test --no-pub test/maintenance_widget_test.dart
test/maintenance_update_service_test.dart test/maintenance_api_mapping_test.dart
test/kingsbeng_workflow_regression_test.dart test/maintenance_refresh_regression_test.dart
test/maintenance_draft_navigation_test.dart test/municipal_widget_test.dart
test/municipal_api_mapping_test.dart test/municipal_detail_header_scaling_test.dart
test/municipal_closed_evidence_gallery_test.dart test/municipal_transport_outcomes_test.dart
test/kingsbeng_screen_layout_test.dart --reporter expanded` (one command).

Full-suite failures, counted from individual `[E]` records:

| Unchanged test file | Failures | Evidence / owner |
| --- | ---: | --- |
| `test/civic_filter_consumers_test.dart` | 24 | Ministry Analytics/Performance/Insights consumers; shared header disposal assertion |
| `test/ministry_widget_test.dart` | 73 | Lifecycle/tooltip errors and cascading exceptions; Ministry/shared owner |
| `test/biometric_lock_preference_row_test.dart` | 1 | Unsupported-hardware test expected `Unavailable`, found none; shared authentication/Profile owner |

**BLOCKED — FRANCIS APPROVAL REQUIRED:**
`lib/widgets/collapsible_list_header.dart:63–75` declares lazy `late final`
`_railOverlay`/`_railOverlayCurve`, then accesses both unconditionally in
`dispose()`. The captured stack shows disposal first initializing the controller,
then `TickerMode.getValuesNotifier` looking up an already-deactivated context.
Proposed owner repair: initialize the controller/curve while mounted (e.g.
`initState`), or dispose only already-initialized nullable fields; add shared
teardown regression coverage and rerun all consumers. No shared file was edited.

The full log also contains RawTooltip callbacks against deactivated contexts and
953 "multiple tickers were created" messages. Those are exception occurrences,
not a count of failed tests. Teardown failure can cascade; attributing every
Ministry failure exclusively to the SDK or exclusively to this header would
require further owner testing. The SDK was inspected read-only, not patched.

The separate biometric test uses an unmocked native availability check and a
fixed 50ms wait; its missing-label assertion is distinct from ticker failures.
Its source and shared implementation are unchanged. The isolated rerun of all
three files completed at **74 passed / 97 failed** (43s): 24 shared-filter and
73 Ministry failures reproduced, while all three biometric tests passed.
Thus the biometric failure is intermittent in this evidence; timing/platform
setup is a hypothesis, not a confirmed cause. Suggested owner follow-up:
inject the existing availability callback in this unsupported-hardware test,
then independently test the native adapter. Changing that out-of-scope test
requires **FRANCIS APPROVAL**; it was not changed here.

No focused Maintenance/Municipal regression failed. The previously reported
1,531/97 run did not provide a complete per-test log, so exact historical
failure identity is not asserted from totals alone.

The 97 reproduced failures run in unchanged Ministry/shared presentation paths;
the shared lazy-disposal defect is present in HEAD, not introduced by these
repairs. No claim is made that repairing it alone will resolve every cascading
failure. Broader suite acceptance remains **BLOCKED — FRANCIS APPROVAL REQUIRED**.

Logs: `%TEMP%\civic-final-analyze.log`, `civic-final-focused.log`,
`civic-final-full-suite.log`, `civic-out-of-scope-reproduction.log`; red/green
fixture logs also remain there. Only this progress document is edited for
reporting. Publication remains **OWNER ACCEPTANCE PENDING** and requires a
separate user instruction.

## New assignment issued - 31 October 2026

Owner assigned Kingsben all three client slices: queue 02 Maintenance, queue 03
Municipal and queue 23's layout/state review limited to those modules. Status:
**assigned, not started**. Read [the current agent guide](../flutter-team/KINGSBENG_AGENT.md)
and [one-page brief](../../output/pdf/kingsben-flutter-assignment.pdf).

Task branch: `codex/flutter-kingsbeng-maintenance-municipal`; starting base and
eventual PR target: `codex/flutter-latif-review-fixes`. This supersedes the older
branch/start allocation below for this assignment. API/backend work is excluded;
web is read-only reference. Preserve accepted behavior and DEV/production
isolation. Record each slice, tests, device evidence and blockers here. No work
or acceptance is claimed yet; Francis reviews and decides whether to merge.

## Current owner continuation - 28 October 2026

Canonical entry: `C:/Projects/www/civic-voice-web/docs/CURRENT_STATUS.md`; read `NEW_CHAT_HANDOFF_2026_10_28.md` and `PRIORITY_QUEUE_2026_10_28.md` there before work. Owner now prioritizes **01 Flutter general Admin Activity Detail** (not the Open Alerts original-event snapshot). Follow the 40-item ordered queue; older “next Open Alerts/card sweep” and contributor allocation paragraphs are historical. Scope/authorization/workflow, auth/notifications, confidence review, UI, AI/public and final cleanup/release gates remain distinct; no blanket completion is claimed.

Standing Home/Profile integration is built; ce622ea Home spacing is owner-confirmed, broader live/device acceptance pending. Confidence/AI and three-repo dead-code/obsolete-file/full smoke review remain open; long-text/nav overflow is owner-deferred. This is documentation only; no runtime/process/configuration/build/install/test rerun or production change. Use last validated baselines in the canonical handoff, reverify repo/upstream/DEV targets before changing code. GitHub connectivity was intermittent on 28 October; verify remote freshness/publication before work. Preserve owner/private assets and existing accepted search/filter/Back/notification behavior. No merge, promotion or deployment without instruction.

## Integration published — 15 October 2026

Owner authorized promotion and Latif preparation. Accepted repair commits through a498f15 were fast-forwarded into codex/flutter-web-alignment. GitHub PR #19 is MERGED (15 October 2026, 13:34 UTC). Fresh fetch proved the old Latif branch contained no unique contributor commits; it was safely recreated from integration and both branches published atomically by ordinary fast-forward, with upstreams. Shared guide publication checkpoint c097f6f includes docs/flutter-team/LATIF_AGENT.md. Latif may now start; this supersedes all older waiting/uncommitted/integration-pending notes. Main remains 75e43b3; production configuration unchanged.

Use codex/flutter-latif-modules; PR base codex/flutter-web-alignment. Contributor agents must read the guide directly from the refreshed Flutter branch, inspect local unpushed work before any update, keep web test read-only, and never reset/force-push or work on main/integration. Follow the guide's exact ID allocation and explicit outstanding search/API/device gates. The API fix efe742e remains on its separate local integration branch and is not deployed by this Flutter promotion. Production login investigation stays paused.


## Accepted repair commits — 15 October 2026

Owner accepted the tested DEV workflow and requested scoped commits. Flutter repair branch codex/flutter-kingsbeng-review-fixes now contains 7461625 (lifecycle/models), b9917f3 (shared loader/headers), 803c7b1 (Municipal flows), ca225c8 (Maintenance completion/rework), bca09f0 (Citizen jurisdiction, notifications, session safety and regression tests). API branch codex/api-web-integration contains efe742e (scoped approval/return authorization and truthful jurisdiction; 76 tests). Source content is the previously verified 708-test/analyzer-clean Flutter tree. Commits are local; no push, merge or branch recreation is implied. Integration remains bb1e6fc and Latif waits for the integration checkpoint. Production login investigation is explicitly paused at owner's request.

Search clarification: current native shared component is focused search with Close/Back and retained list position; scroll-driven collapse is not implemented or physically accepted. Latif owns remaining Citizen/Ministry/Admin search adoption; retain scroll-collapse parity as an explicit outstanding shared UX requirement, assess shared behavior first and test all consumers. Do not silently label focused search as scroll-collapsible or duplicate implementations. Municipal/Maintenance focused search is already adopted in these repairs.

Earlier uncommitted/awaiting-owner-acceptance notes are historical. The remaining untested Citizen notification/coverage and photo removal/replacement checks, native Places HTTP gate and API follow-up debts remain recorded; acceptance of tested staff flows does not erase them.


## Verified DEV workflow checkpoint — 15 October 2026, 13:23 UTC

This checkpoint supersedes earlier temporary-role and blocked-device notes below. Native branch codex/flutter-kingsbeng-review-fixes remains based on 04dd917; integration codex/flutter-web-alignment remains bb1e6fc. Repairs are uncommitted and await owner acceptance; Latif still waits. No production configuration, credentials, deployment or installed production app was changed.

Actual Pixel DEV phone checks: Municipal verification and assignment; non-lead Maintenance submission with completion notes and three separately selected synthetic evidence photos; Awaiting Confirmation shown to the officer; blank send-back reason rejected; real return reason shown on the crew task; final Municipal confirmation and Resolved success. The second completion was resubmitted through the DEV API, not the phone. First startedAt stayed unchanged across return/resubmission. Assignment no longer sends a progressPercent field forbidden for Municipal officers. Pre-confirmation selection copy no longer claims assignment has succeeded.

Validation: Flutter analyze clean (14.9s); all 708 Flutter tests pass; all 76 API tests pass; web lint/build pass with 185 PWA precache entries; whitespace checks clean. The initial test run caught two old pre-assignment copy expectations; updated those while preserving the separate actual-success assertion. Different-officer/cross-assembly policy remains covered by isolated HTTP tests, not a second physical officer account.

Cleanup completed: labelled QA report CV-2026-7EB72EBB20 and team TEAM-000004 deleted through the guarded local DEV API. Test account CIT-000059 has its exact original role/locality/team/adminTier/publicId/trustScore restored; Admin and other original records untouched. Only three agent-created synthetic phone gallery files removed. Ignored API secrets/qa-role-restore.json retains nonsecret restoration and outcome evidence. QA audit records remain as truthful history. Phone interaction stopped when the owner appeared to be using it; no forced re-login. Last DEV session uses the restored Citizen account; Admin credentials were never used against production. Agent API4002 remains separate from owner4000.

Remaining acceptance: owner review of rebuilt DEV flows, fresh Citizen unknown-coverage and report-reference notification device check, photo removal/replacement device check. Do not call these physically verified. Native legacy Places HTTP search, server/client evidence-minimum mismatch, durable notification inbox/FCM, verifiedAt/checklist persistence and public-share hosting remain recorded backlog. Web API mode still gates modules beyond auth/Profile; Maps browser check waits for their integration.

Production login: owner reports intermittent missing reset SMS and invalid credentials even after a successful reset. Read-only evidence: live health and production Firebase client config respond 200; production-labelled installed APK is a 12 October debug build containing local4000 plus production Firebase strings. This suggests an environment mismatch but does not establish the runtime API target or explain every password failure. Preserved 26 July release APK contains only live API/prod Firebase. No production sign-in/reset/install attempted. Diagnose actual runtime/build target before further resets; do not label production authentication fixed.


Integrator repair branch: `codex/flutter-kingsbeng-review-fixes`, based on submitted PR19 head `04dd917998687745e542a455886aa7c253b19a9f`. Integration remains `bb1e6fc147ba7eecdb6987d0aeea6046489da78f`. Repairs are local and uncommitted; no merge/push. Latif waits for approved integration and branch refresh.

Implemented means source and automated checks pass, not physical acceptance or server deployment.

| ID | Repair / status | Remaining gate |
| --- | --- | --- |
| W01 | Shared strict seven-state parsing; lifecycle 15/30/50/70/90/100; pending remains open; real workflow dates and returned reason mapped. Narrow Citizen compatibility adopted. | Latif adopts remaining module surfaces; target API schema/deployment and device checks. |
| W02 | Current membership/lead refreshed; any assigned team member can submit; actual team contact/submitter data used. | API currently rejects approval by an officer other than original reviewer; server fix and live lead-change/recipient checks. |
| M01 | Required rejection category plus separate free-text reason; standing help without invented deltas; citizen fields corrected. | Server category enforcement/product policy. |
| M02 | Selected-team confirmation, no self-contact, current lead success contact, availability gates; shared focused search/text chips. | Device assignment/Back/permission checks. |
| M03 | Work monitoring read-only; pending evidence, approve confirmation and required Send Back reason; actual dates, returned receipt/contact, public-safe share. | Same-assembly officer API authorization; physical end-to-end approval/return. |
| M04 | Rejected error treatment, duration/reason/evidence, internal category excluded from public share; Archive disabled/explained. | Device sharing/dismissal/failure checks; live public-share domain remains I08. |
| M05 | Dashboard short-content refresh physics, contextual empty shell and pending queue; shared Ghana loader and bounded headers. | Physical refresh, offline, large text and safe-area audit. |
| M06 | Claim/409 gating and real retry; account-scoped bounded checklist draft cleared on logout. | No server verifiedAt/checklist persistence; memory draft is not persisted verification. |
| T01 | Pending filter/open counts, coherent Kumasi sample coordinates, real production coordinates preserved; shared filters/search. | Device filter/refresh checks. |
| T02 | Pending read-only and returned notices; actual photo count/viewer, latest directory data and truthful timeline. | Device photo/permission/missing-record checks. |
| T03 | Real camera/gallery and removable thumbnails; notes/three-photo validation; submit PENDING_APPROVAL, busy/discard/first-invalid focus; membership gating. | API allows one photo while client requires three and ten-character notes; product/server reconciliation before release. |
| T04 | Submitted/failed/completed outcome branches and invalid-route guard; Back cannot reopen submitted form. | Physical system Back and repeated submission checks. |
| T05 | Exact pending/returned references and current-lead-only completion notification when another member submits; return count gives fresh notification identity. | Physical FCM/recipient checks and I05 durable inbox. |

Verification: 701 tests passed, analyzer clean, native whitespace check clean. Web lint/build/whitespace checks also required and recorded in repair report. Production Firebase, app identity, dependencies and API source unchanged. Isolated DEV snapshot preserves development Firebase/applicationId separately; never commit its configuration.

## 15 October follow-up (supersedes earlier guard-open wording)

W02/M03 same-assembly completion permission is repaired locally in the API and covered by HTTP tests; source is not deployed or accepted. M06 initial ownership and atomic status checks retained. Native Citizen map assembly propagation, unknown-coverage feedback and public reference/title notifications repaired as prerequisites; Latif must preserve them after approved integration. API no longer guesses geography from staffing. API75tests pass; latest native count follows repair report. Live account setup was blocked by automatic approval review; no live fixtures or full staff-device acceptance. No commits/merge/push.
