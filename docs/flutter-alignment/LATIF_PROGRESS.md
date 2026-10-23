# Latif progress

## Current-location button visibility - 23 October 2026

Web and native map pickers now use their shared gold action fill with a dark location glyph and 2 px dark outline in both themes, retaining the 48 px action target and existing capture callback. Web validation: 8 existing LocationPicker tests pass and actual stylesheet controls visually checked over synthetic light/dark map backgrounds (not live provider/GPS acceptance). Native: 21 existing picker chrome/ownership tests pass; changed-file analyzer clean. Scope is the current-location control; remaining shared UI inventory and Maintenance device acceptance stay queued.

## Shared native media and map-picker UI - 23 October 2026

`4d652bb` connects Municipal resolution/rejection thumbnails and approved-outcome photos to the existing indexed swipe/zoom/share gallery. The selected image opens first and the gallery retains all permitted photos; rejection evidence is no longer stamped VERIFIED. Evidence headings wrap on narrow screens rather than overflowing. No image permission expansion or parallel viewer was added. `83a904c` gives map search an explicit 48 px control with 24 px corners, a clear action that invalidates the old query, and the existing shared orb during search. Capture/address loading uses the same orb with the controller's current message, wrapping at large text sizes; core location ownership/provider/routing logic is unchanged.

Complete native suite: **1,178 pass**, analyzer and whitespace clean. Twelve new cases cover compact search at 320/390/412 in both themes, larger-text/reduced-motion orb feedback, Municipal resolved/rejected gallery selection/swipe/close and the approved-outcome gallery. Existing gallery sharing/zoom controls and Municipal screens remain covered. Device feel remains owner acceptance. Maintenance workflow testing is still pending the owner's planned account; do not create or change roles/accounts on their behalf.

Continue the remaining shared UI inventory (permitted saved-location consumers and local draft-photo previews, preserving already accepted cards/search/timeline/busy feedback), then first-invalid-field focus/scroll, notification and Admin reconciliation. Do not mark the entire UI backlog complete from this slice. Francis-owned ordinary-success/checkmark and native Activity Detail stay separate; the original branding SVG remains untouched. No API, web runtime, production deployment or integration promotion change.

## Native evidence/proximity/completion checkpoint - 23 October 2026

Native commits `4e2a738` and `fa1498c` reconcile GPS freshness after token refresh and the Maintenance completion contract. Field-issue notes stay attached to an editable IN_PROGRESS task; they no longer hide it as terminal Failed or reset progress to zero. Completion checks exactly three distinct local uploads, supported file types, nonempty files up to 10 MB each, 10-2000 character notes and explicit 100% progress. Missing attachments are never silently skipped. Assigned tasks start before submitting, any assigned team member remains eligible, repeated in-flight writes are blocked, and session/team checks fence each request and response. Only matching task/team/status/progress/notes/new-evidence acknowledgement reaches awaiting-confirmation. Historic resolution photos remain intact across send-back cycles and cannot substitute for three new uploads. Uncertain saves require authoritative refresh before retry, with a visible Refresh task action. Pending/resolved records stay read-only.

Verification: full native suite **1,166 passing**, analyzer and whitespace clean; 21 existing API workflow/approval/proximity tests pass. Added service/transport/widget checks cover actual multipart fields/files, invalid and missing evidence, response mismatch, duplicate writes, ownership changes, field-issue continuity and returned-work evidence history. No API source, role/account/report, production deployment or integration promotion changed. The Firebase-free design preview keeps synthetic evidence paths; real live saves always validate actual files. Physical Maintenance completion/return/approval acceptance remains pending in the private device checklist.

Next implementation: remaining shared UI/media/card/timeline reconciliation, then validation, notifications and Admin reconciliation in the recorded order. Include the queued native picker compact search shape/orb-loading refinement in shared UI work. Preserve Francis-owned ordinary-success/checkmark and native Activity Detail. Do not reopen the Places Cloud configuration gate or add citizen assembly selectors.

## Native Places token correction - 23 October 2026

Owner phone testing exposed HTTP 400 from an oversized autocomplete session token: the app encoded 24 random bytes as 48 hex characters, exceeding Google's 36-character maximum. Native commit `331909e` preserves the same secure randomness as 32 URL-safe base64 characters. The serialized-request regression failed before the fix and passes after it; 35 related Places/picker/routing/submission tests and changed-file analysis pass. A live check through the actual corrected Dart PlacesService now passes autocomplete and details. The earlier standalone provider probe used UUIDs and missed this app-specific defect; its configuration/restriction results were valid but did not establish phone search acceptance. No further Cloud/key change is needed. Physical retest remains pending.

Queued native UI follow-up from this test: match the web picker search bar's compact height and rounder corners; replace location-capture loading with the shared orb treatment aligned with web. Record these for shared UI reconciliation after core map behavior; do not interrupt the implementation order or owner-owned success/Activity Detail work.

## Native maps and automatic routing reconciliation - 22 October 2026

4356c99 adopts Places API (New) with restricted mobile request identity and search sessions; e36e9be protects the latest issue pin from stale GPS/search/geocoder/camera results; e954812 omits client locality hints so existing server polygons own routing. Native 1,138 tests and analyzer/whitespace pass; 18 existing API routing/geography tests pass. See [NATIVE_MAPS_AND_ROUTING.md](NATIVE_MAPS_AND_ROUTING.md). On 22 October, the owner approved and we saved exactly Maps SDK for Android + Places API (New) for android_maps_key_cv, retaining both existing Android package/certificate restrictions. Live app-contract probes returned HTTP 200 with five Wusuta suggestions and matching Place Details with an address and valid Ghana coordinates; wrong-package and wrong-certificate probes both returned HTTP 403 / API_KEY_ANDROID_APP_BLOCKED. The provider configuration gate is cleared; owner phone acceptance remains pending. Phone and iOS acceptance remain pending; no install or integration promotion. Next is owner phone acceptance, then recorded evidence/proximity/completion reconciliation. Later native Super Admin routing UI/Admin dashboard work and password masking/padlock remain queued; owner success/checkmark and Activity Detail stay separate.

## Native submission and duplicate safeguards - 22 October 2026

Implemented in 074f27e, 826f1fd and 4a7f4e6: account-scoped frozen report/evidence keys and validated receipts, safe uncertain-save retries/reopening, session fences, and selected-pin advisory suggestions before Photos with explicit fresh-GPS seconding or distinct-report continuation. Complete suite: 1,114 pass; analyzer/whitespace clean. See [NATIVE_REPORT_SUBMISSION_SAFEGUARDS.md](NATIVE_REPORT_SUBMISSION_SAFEGUARDS.md) for scope, limits, release prerequisite and remaining acceptance. No phone install, API/config change or promotion. Next implementation is Places New/automatic routing reconciliation, then the remaining recorded native backlog. Admin/dashboard and password masking/padlock findings remain queued; owner success/checkmark and Activity Detail remain separate.

## Shared native bottom sheets - 22 October 2026

cf8e730 adds showCivicBottomSheet/CivicSheetSurface; 544816d adopts it for all nine existing sheet launches across seven files: Nearby Reports, Maintenance photo source, Municipal Active sort, Municipal send-back form, three Ministry Insights pickers, shared region picker, and shared profile editor. Existing sheet data/results/actions stay with their owners. Standard surface: rounded 24 px top corners, a static 10 px backdrop and a feathered 24 px rise, readable theme surface, one handle and native barrier/Back/drag handling. Motion uses shared tokens: 200 ms entry, 100 ms exit, zero for reduced motion. Inputs use an opaque surface; the profile editor uses explicit close instead of drag bypassing its save/discard guard. Duplicate GlassDialogBackdrop wrappers were removed from these sheet builders, while real dialog wrappers remain.

Inspired by Transitions.dev's panel/menu examples (https://transitions.dev/library.html), adapted to Flutter's native sheet route without copying CSS, adding packages or changing authentication/API/config. Scope is modal sheets; fixed navigation bars and drawers are not redesigned in this checkpoint. Eleven new regression cases cover four widths/both themes, selection result/barrier dismissal, native drag, reduced motion and opaque form closing. Complete suite: 1,081 pass; analyzer/whitespace clean. Private light/dark raster previews checked surface and edge geometry. Physical feel/blur acceptance remains owner testing.

DEV-only source snapshot updated with review Dart sources while preserving its DEV firebase_options.dart and native identity/config. Package com.example.civic_voice.dev / Civic Voice DEV verified before wireless replacement install; DEV Firebase civic-voice-dev-11d98 and local API configuration verified, build explicitly defines http://192.168.100.8:4000. API health is OK and its Firebase project/DB were checked as DEV. No production uninstall or data clear. Device artifact and acceptance checklist stay private/uncommitted in web .tmp/device-checks-pending.md. Original integration checkout and owner notification SVG remain untouched; no integration promotion or merge.

## Frosted search rail and matched web motion - 22 October 2026

Native eb04638 follows the owner's accepted continuous animation. Compact search now paints above the real scrolling viewport, using the existing 20 px glass blur with a feathered 32 px tail. The backdrop has no solid panel or extra border. A shared layout delegate measures the animated header and corrects the list origin during layout, preserving the active drag/fling and visual anchor. Expanded short-list geometry and filter/search interaction remain intact. The outgoing header remains excluded from focus, taps and semantics. Native list/filter tests now select the vertical owner and filter header explicitly, instead of relying on paint-order-dependent first/last finders.

Web dd9e179 uses the same 200 ms easeOut/decelerate curve for header height, opacity and compact-control movement, retaining its existing masked backdrop. No auth, API, Firebase, map or production config change. Native 1,070 tests pass; analyzer/whitespace clean. Web 360 tests, lint/build pass (209 PWA entries). A browser fixture of the actual shared chrome verified intermediate heights, 20 px fog and exact focused-search dismissal offsets at 320/390/412/1440 in light/dark themes. Native light/dark raster checks confirm real background blur, and 20 offline sample-menu checks pass. Physical fog/feel acceptance remains owner testing.

Delivery: only the separate offline CV Search Test snapshot was rebuilt and installed; package and absent INTERNET permission verified. Normal DEV/prod installs remain untouched. Device acceptance details stay private/uncommitted in web .tmp/device-checks-pending.md. Preserve remaining integration backlog and owner-untracked branding assets.

## Continuous search scrolling repair - 22 October 2026

Final verification: 1,070 Flutter tests pass; analyzer and whitespace checks clean. The offline preview menu has 20 passing real-screen checks. Updated CV Search Test APK was installed wirelessly and its activity started; physical feel remains owner acceptance.

Implementation f600292 on codex/flutter-latif-review-fixes replaces the compact-rail header's instantaneous swap and post-frame jumpTo. That jump cancelled an active drag. Header height now eases over 200 ms with a crossfade; outgoing controls cannot receive taps, focus or accessibility interaction. Layout-time scroll correction keeps content anchored while preserving the active drag/fling. One held gesture can collapse, reverse, reach the top and collapse again; reduced motion swaps immediately without cancelling the gesture. Existing short-list guards and focused-search restoration remain.

The 80 real-consumer cases now hold the pointer through the transition and reverse without lifting, across all ten screens at 320/390/412/1440 px in both themes. Shared regressions cover intermediate animation geometry/content anchoring, held reversal through the top, fling momentum and reduced motion. Previous separate drag gestures missed the cancellation bug. Phone smoothness still requires owner acceptance; automated passing checks do not establish Telegram-equivalent feel.

Delivery uses the existing isolated offline CV Search Test fixture app, package com.example.civic_voice.searchpreview, with no INTERNET permission and no Firebase/API startup. Its source snapshot remains outside Git. This is not a new normal DEV build or integration promotion. The original integration checkout and owner branding asset remain untouched; private device results stay uncommitted in web .tmp/device-checks-pending.md.

## Native device-feedback and Nearby checkpoint - 22 October 2026

Current review candidate includes 6d05f0f (fresh accuracy/timestamp/300 m/account checks for Nearby), c3be080 (API-backed Nearby sheet, not own cached reports), e142d3e (full-screen focused search and 48 px pill triggers), 0d260ec (native adaptation of web thinking-orbs searching/globe with license attribution), and 839e2cb (shared indexed swipe/zoom/share evidence galleries for Citizen, Maintenance and Municipal Review/Progress). All ten search consumers keep the shared lifecycle and scroll restoration. Web now shows one compact Current Status row/bar; absent recorded work remains truthful in Report details instead of crowding the status card. The compact fraction is lifecycle stage, not an invented work percentage.

Native verification: complete suite 1,065 pass; analyzer clean; twelve contrast cases rerun after final particle-opacity adjustment. Final compact-card verification: all 360 web tests pass, lint/build clean (209 PWA entries); nine focused report/API tests pass. Native focused geometry checked at 320/390/412/1440; all-consumer search matrix still passes. Browser visual QA used an isolated fixture of the actual live Tracking component (no owner account mutation), with compact bar and no overflow at mobile/desktop widths in both themes. Actual fresh GPS, map/zoom/swipe performance and phone acceptance remain owner testing; do not infer physical acceptance from automated checks.

DEV source snapshot C:/Projects/mobile/civic_voice_dev_latif_20261022 updated from review source through 839e2cb; profile APK package/label, compiled LAN API4000 and DEV Firebase resources verified before wireless install. App process is running and Flutter VM attached at install time; no production uninstall/data clear/config change. Original integration checkout remains 6ace645 with owner notification SVG untouched. Manual acceptance details and artifact hash remain private/uncommitted in web .tmp/device-checks-pending.md. Next implementation is native stable submission intent keys/receipt recovery and selected-pin duplicate suggestions; do not overwrite the owner's testing build with further work without identifying the new checkpoint. Preserve remaining Places New, validation, shared-UI and notification debt, Francis-owned success/checkmark and Activity Detail. Google logging stays OFF.

## Current native auth and feedback checkpoint - 22 October 2026

Supersedes older pending/local-only statements below. On codex/flutter-latif-review-fixes in C:/Projects/mobile/civic_voice_latif_review: aae4383 adopts server password verification/custom-token exchange/sync for login, registration continuation and forced-password renewal; 594744e adds bounded best-effort Logout requested reporting before local cleanup; 075c60d fixes disabled-button orb contrast and remaining button-spinner adoption; d4f3dc9 keeps manual Municipal/Maintenance retry feedback in its button rather than flashing a centered Ghana loader. Existing pull gestures and cold loading remain distinct. See native docs/flutter-alignment/NATIVE_AUTH_AND_FEEDBACK.md.

Verified current native candidate: 1,032 tests passed, zero failures; analyzer no issues; whitespace clean. New checks cover API transport, all five role destinations, handoff/UID validation, first-login failure boundaries, duplicate submits, late route disposal, twelve light/dark button contrast cases, and delayed retry/failure/disposal behavior. This is automated verification, not physical or live-provider acceptance of this new native flow. API/web code is unchanged this checkpoint (last validation 173 API tests; 360 web tests plus lint/build). API deployment/migration/project-key/throttle/proxy prerequisites remain mandatory before updated clients.

Delivery: small commits are ready for the authorized push to the review branch and matching documentation branches. Verify remote heads before continuing; later documentation commits may sit above implementation d4f3dc9. No integration/main promotion, merge, production changes or phone installation. Original native checkout remains 6ace645 with owner-untracked notification-monochrome.svg preserved. Device checks stay private/uncommitted in web .tmp/device-checks-pending.md; next installation must verify isolated DEV identity, DEV Firebase, local API URL and matching Maps config together.

Next native integration: authoritative nearby discovery/seconding and durable report submission UUID/receipt recovery, then recorded Places New/routing, evidence/proximity/completion, shared preview/cards/timeline, validation and notification reconciliation. Do not claim those completed from current auth/search tests. Keep citizens free of assembly selectors. Francis retains ordinary-success/checkmark and native Activity Detail work. Google optional logging stays OFF; no billing changes.

## Shared Flutter search follow-up - 22 October 2026

Implemented locally on codex/flutter-latif-review-fixes in C:/Projects/mobile/civic_voice_latif_review: 1a61e5b (shared behavior) and 37a26de (all ten consumers). Search is expanded at the top; sufficiently overflowing lists switch to a compact search button beside horizontally usable filters. Ordinary reverse scrolling does not flicker the full header open; returning to the top restores it. Short lists keep search accessible. Focused search preserves list position on Close/Back/Escape, stores submitted history, and permits empty submission to clear a query. Header-height compensation preserves the card being read, and upward wheel/keyboard intent at the top can reveal the full header. Existing filter-only collapse behavior is retained.

Consumers: Citizen My Reports; Maintenance Assigned Tasks; Municipal Inbox, Active, Closed and Assign Team; Admin Users, Maintenance Teams and Activity; Ministry Reports. Search results preserve current role/filter scope independently of the previously applied query. Form member pickers and map place search are intentionally separate interactions. Jurisdiction/time selectors and summary cards remain scrolling content. Narrow Active/Assign Team card text now wraps without overflow.

Validation: full Flutter suite 970 passed, zero failures; analyzer no issues; whitespace clean. Includes 80 actual-consumer checks across 320/390/412/1440px and light/dark themes, plus shared lifecycle/scroll/history/disabled/reduced-motion tests. Physical acceptance remains pending. The manual phone checklist is private and uncommitted in web .tmp/device-checks-pending.md. Do not mark device acceptance or rollout complete.

The original C:/Projects/mobile/civic_voice checkout remains at its previous integration state with the owner's untracked notification-monochrome.svg preserved. No native Firebase/Maps configuration, package identity, dependency, API or production changes; no phone installation, push, merge or deployment. Build the verified isolated DEV candidate when resuming physical checks. PR #20 remains reviewed against its unchanged submitted head; local follow-ups are not remote approval.

## Integration review checkpoint - 22 October 2026

Submitted head 82d11cd produced 871 passing tests and two failures in the full suite; analysis reported one warning and 46 infos. Francis-owned repairs are isolated on codex/flutter-latif-review-fixes: dd1f4c5, 1af2765, ee4b736 and c5d87c2. The repaired candidate passes 878 tests, analysis and whitespace checks. A formal GitHub review with three inline comments is posted on PR #20. Read LATIF_REPAIR_REPORT.md for exact repairs, shared-owner session integration and remaining device/API acceptance. This is not a promotion, remote-head approval, push or merge. Contributor notes below remain historical; API and Flutter owed backlogs contain newer implemented server contracts.


## C01 — Citizen My Reports card interaction

- Status: implemented and validated.
- Screen/file: `lib/features/citizen/screens/citizen_reports_screen.dart`
- Preserved contracts: existing report content, filters, search, statistics,
  empty/no-results states, and `ReportTrackingScreen(reportId)` navigation.
- Change: the report history card is the single accessible tappable target; its
  filled CTA is replaced by a quiet trailing chevron.
- Automated validation: `flutter test --no-pub test/citizen_widget_test.dart`
  (15 passed, including the focused card interaction/semantics test),
  `flutter analyze` (no issues), and `git diff --check` passed.
- Manual browser checks passed, including opening a populated report card and
  confirming navigation to its matching tracking screen.
- Reference concern: the supplied web checkout's local `origin/test` resolves
  to a Flutter commit and does not contain `src/components/ReportPrimitives.jsx`;
  the required reference ancestry hash is also unavailable locally.

## C02 - Nearby Issues sheet accessibility (narrow approved scope)

- Status: implemented and locally validated for the approved narrow Nearby
  Issues accessibility and navigation test slice; I03-dependent Nearby
  consolidation remains blocked.
- Screen/file: `lib/features/citizen/screens/citizen_dashboard_screen.dart`.
- Change: the existing native Nearby Issues bottom sheet now identifies itself
  as a named accessibility route, while retaining its semantic heading.
- Preserved contracts: local `ReportCrudService` data, displayed report rows,
  native drag/barrier/back dismissal, report tracking navigation, and the
  existing Report Issue quick action route to Create Report.
- Focused coverage added in `test/citizen_widget_test.dart`: sheet opening and
  accessibility label, native back dismissal, and Report Issue navigation to
  `CreateReportScreen`.
- Validation: `flutter test --no-pub test/citizen_widget_test.dart` passed
  18/18 tests; `flutter analyze` found no issues; `git diff --check` passed
  with Windows CRLF warnings only.
- Blocker: I03 backend proximity validation and the safe-detail endpoint remain
  unverified, preventing broader C02 API-dependent consolidation work. No
  proximity discovery, safe-detail, or API behavior was added in this narrow
  scope.

## C03 - Citizen report creation navigation

- Status: Stage 1 and Stage 2 implemented; automated validation is blocked by
  the local Flutter SDK startup hang before Dart starts.
- Screens/files: `create_report_screen.dart`, `photo_upload_screen.dart`,
  `review_report_screen.dart`, `report_submitted_screen.dart`, and
  `citizen_reports_screen.dart`.
- Stage 1: Create, Photos, and Review are focused authoring screens with
  ordinary Back, no `CivicBottomNav`, no middle add FAB, and safe-area/keyboard
  content padding.
- Stage 2: My Reports now pushes Create without removing its existing route,
  retaining its filters, search, and scroll state. The authoring route chain
  carries that origin through Photos and Review. After confirmed submission,
  only Create/Photos/Review are removed before Submitted is shown, so system
  Back returns to the preserved origin. Submitted returns to the retained My
  Reports route when available, always routes Return to Dashboard to Home, and
  replaces itself with a fresh Create flow for Submit Another Report.
- Preserved contracts: existing draft save/clear generation, report payload,
  attached-photo persistence, precise location/address/community/assembly,
  guest/session handling, successful-submission-only transition, and retry on
  submission failure.
- Focused coverage added in `test/citizen_widget_test.dart` for Submitted
  system Back, retained My Reports, Submit Another history replacement, and
  Return to Dashboard. The existing Stage 1 chrome/Back test remains.
- Validation blocker: do not run Flutter/Dart validation until the stale
  SDK-launcher contention is resolved. Device validation remains required for
  Android system Back, keyboard/safe-area behavior, offline submission retry,
  real photo persistence, location permission/error flows, guest reporting,
  and My Reports search/filter/scroll restoration.

### C03 follow-up - duplicate submission protection

- Review Report now takes a synchronous, screen-local in-flight lock before
  invoking the existing `ReportCrudService.createReport` path. While awaiting
  the genuine response, Submit Report and Back to Photos are disabled and the
  button exposes the accessible `Submitting report...` state. Extra taps do
  not create extra requests or navigation attempts.
- A successful response retains the existing draft-clear and Submitted-route
  behavior. A failed response leaves the draft untouched, restores the button,
  and permits one genuine retry. Completion after the Review widget unmounts
  returns without state updates or navigation.
- Focused widget coverage uses deferred screen-local submit callbacks for
  rapid taps, immediate disabled/semantics state, one successful navigation,
  failed-draft preservation/retry, and disposal before completion. Tests were
  added but not executed because Flutter/device validation remains blocked.

### C03 follow-up - honest Submitted reference

- Removed the fabricated `CV-2026-004582` fallback from Submitted. A nonblank
  supplied reference is shown exactly as returned; null, empty, and
  whitespace-only values show `Reference number unavailable` instead.
- Submitted now requires both a nonblank report ID and reference before it
  presents a success confirmation, coverage notice, or Track My Report action.
  An incomplete direct route shows an honest confirmation-unavailable state,
  exposes no fabricated reference, timestamp, or tracking status, and keeps
  only safe dashboard/new-report navigation.
- Focused widget coverage covers genuine, null, empty, and whitespace-only
  references plus the incomplete-route state. Tests were added but not run;
  Flutter/device validation remains pending.

## C04 - Citizen Report Tracking

- Status: Stage 1 implemented; focused regression coverage is added but not
  executed because Flutter/device validation remains blocked.
- Screen/file: `lib/features/citizen/screens/report_tracking_screen.dart`.
- Change: Pending Approval retains the existing canonical `Awaiting
  Confirmation` status and 90% progress from `ReportStatus`; its tracking
  explanation now reads: “The team finished the work and submitted it. A
  municipal officer is confirming it before the report closes.”
- Focused coverage added in `test/citizen_widget_test.dart` uses an explicit
  `pendingApproval` fixture and verifies the status, 90% progress, approved
  explanation, and normal report-found behavior.
- Blockers: the Track map pan/zoom/drag contract and exact-pin interaction
  remain an I07 product decision. Guest conversion and ownership continuity
  remain shared Auth/backend work; no authentication, registration, backend
  ownership, map, bottom-navigation, or Back behavior was changed.

## V03 - Ministry Municipal Performance filter access

- Status: Stages 1 and 2 implemented; automated validation is pending because
  Flutter/Dart startup is currently blocked before tests can run.
- Files: `ministry_municipal_performance_screen.dart`, the module-scoped
  `region_picker_chip.dart`, and the compatible Ministry Reports caller.
- Change: Municipal Performance keeps region and scope controls pinned while
  only its explanatory subtitle collapses. Region picker dismissal preserves
  the current region; explicit All Regions clears it. Efficiency Trend metric
  controls now wrap and retain 44px minimum touch targets on narrow screens.
- Preserved contracts: existing regional/scope data filtering, no-results,
  loading/retry/error behavior, metric calculations, selected appearance, and
  Ministry Reports filtering.
- Focused coverage added in `test/ministry_widget_test.dart` for pinned
  filters after subtitle collapse, picker dismissal versus explicit reset,
  narrow metric targets, and Ministry Reports picker compatibility.
- Stage 2: Municipal Performance no longer has a production sample fallback.
  Without a genuine report-backed aggregate, it shows No Performance Data
  rather than municipality rankings, percentages, trends, or national totals.
  The directory marks genuine report aggregates explicitly; widget tests use
  local fixtures. Refresh and retry are disabled unless an approved callback
  is supplied, and a failed callback remains an error rather than claiming a
  local success.
- Focused coverage now verifies the honest default with no fabricated stats or
  leaders, the disabled no-callback refresh/retry actions, and preservation of
  genuine directory-derived performance data alongside the Stage 1 filter and
  responsive-control checks.
- Remaining dependency: shared-owned `lib/main.dart` must pass the approved
  Ministry refresh callback before this screen can offer a live refresh.
- Validation blocker: do not run Flutter/Dart validation until the local SDK
  startup issue is resolved. Device validation remains required for narrow and
  large-text layouts, picker barrier/Back/swipe dismissal, filters, retry, and
  both themes.

## V01 - Ministry Dashboard data accuracy and zero state

- Status: Stage 1 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- Files: `ministry_dashboard_screen.dart`, `ministry_dashboard_data.dart`,
  `ministry_data_directory.dart`, and focused Ministry widget/data tests.
- Change: missing or zero report data now retains National Dashboard with four
  zero-value summaries, an inline Refresh control, and an honest welcome
  explanation. It does not render a chart or municipality ranking. The
  dashboard now aggregates all seven canonical report statuses; Open Work
  includes Submitted, Under Review, Assigned, In Progress, and Awaiting
  Confirmation. Quick Insights includes Awaiting Confirmation, while Rejected
  remains included in the underlying total.
- Preserved contracts: existing scoped report source, active-municipality
  derivation, real report counts, loaded chart/ranking presentation when data
  exists, and the existing unavailable-state presentations. Unsupported
  dashboard percentage deltas and fallback mock data were removed.
- Focused coverage added in `test/ministry_widget_test.dart` for the zero
  summary/no-fabrication state, seven-status totals, pending approval in Open
  Work and Quick Insights, existing unavailable states, and no false local
  retry success without a refresh callback.
- Remaining limitation: `lib/main.dart` currently does not pass the Ministry
  directory loading/error/offline/authorization state into this screen. That
  shared-owned route wiring is outside Stage 1; preserve the existing UI
  states and request a narrow ownership-approved change before wiring them to
  live directory state.
- Validation blocker: do not run Flutter/Dart validation until the local SDK
  startup issue is resolved. Device validation is still required for empty and
  loaded dashboards, Refresh with an approved signed-in data source, all
  unavailable states, both themes, narrow layouts, and large text.

## V02 - Ministry Analytics

- Status: Stages 1, 2, and 3 implemented; automated validation remains pending
  because Flutter/Dart startup is blocked before commands begin.
- Files: `ministry_analytics_screen.dart`, `ministry_analytics_data.dart`,
  `ministry_data_directory.dart`, and focused Ministry widget/live-data tests.
- Change: the existing date-range dropdown remains inside
  `CollapsibleListHeader` and collapses with Analytics content; the existing
  Category, Status, and Municipality controls now remain in a persistent
  Ministry-owned row. Shared `AppDropdownField` and
  `CollapsibleListHeader` implementations were not changed.
- Preserved contracts: date selection, selected dimension and distribution,
  charts from genuine selected-interval data, unavailable states, safe-area
  spacing, and Ministry navigation.
- Stage 2: removed the fabricated production Analytics fallback, fabricated
  municipality/category/trend presentation, and unsupported comparison deltas.
  The default route now shows the honest empty state when it has no data. The
  complete seven-status `ReportStatus` lifecycle, including Awaiting
  Confirmation and Rejected, is retained in selected-interval aggregations.
  Trend Insights is deterministic selected-data text only; no AI insight was
  added.
- Refresh/retry no longer changes local screen state after a timer. Actions
  are enabled only when an approved refresh callback is supplied, so the UI
  cannot claim an unverified refresh succeeded.
- Stage 3: Category and Municipality cards now explicitly say “Resolution
  Rates,” so their genuine segment-resolution values are not presented as
  report shares. Live trend buckets now match their selected interval: daily
  for seven days, five-day for 30 days, fifteen-day for 90 days, and monthly
  for the current year. The all-live fallback uses only real report history.
  Empty intervals retain zero buckets rather than invented activity.
- Focused coverage added/updated for date-header collapse, persistent controls,
  post-scroll dimension selection, narrow-width rendering, honest empty
  defaults, omission of unsupported comparisons, resolution-rate labels,
  interval-accurate trends, empty-period zero buckets, all seven status counts,
  and no false local refresh success. Existing dropdown-selection coverage
  remains in place.
- Remaining dependency: shared-owned route wiring must provide real
  loading/error/offline/authorization state and an approved refresh callback.
  A comparison baseline and explicitly defined period remain unavailable; any
  future resolution-rate comparison must be expressed in percentage points.
  I06 AI-generated analytics remains blocked.
- Validation blocker: do not run Flutter/Dart validation until the local SDK
  startup issue is resolved. Device validation is required for scrolling
  filters, dropdown dismissal, narrow/large-text layouts, unavailable states,
  and both themes.

## V04 - Ministry Reports, Insights and municipality contacts

- Status: Stages 1–3 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- Stage 1 change: Ministry Reports cards now keep the neutral canonical status
  icon with the title/location row and place the status badge and date beneath
  it. This keeps long titles and Awaiting Confirmation readable on narrow
  phones without making report rows interactive or changing filtering, national
  summaries, data sources, or fallback behavior.
- Focused coverage added in `test/ministry_widget_test.dart` supplies a long
  Awaiting Confirmation report at 375px and verifies the title, status, and
  date remain visible below the title/location row without overflow.
- Stage 2: Report Insights no longer supplies fabricated fallback content. It
  shows an honest empty state without genuine data, uses the supplied live
  dataset and all seven canonical statuses, and exposes a truthful status
  breakdown. Open Backlog now explicitly includes Submitted, Under Review,
  Assigned, In Progress, and Awaiting Confirmation; Rejected remains counted
  separately. The peak-category text uses its label rather than a `MapEntry`,
  and no comparison delta or AI-style narrative is shown.
- Focus Summary remains visibly disabled with an I06 explanation and cannot
  navigate to Municipal Performance. Refresh and retry controls are disabled
  unless an approved callback is supplied, so they cannot claim local success.
- Focused coverage updated in `test/ministry_widget_test.dart` and
  `test/ministry_live_data_test.dart` for the honest default, full status
  breakdown and Awaiting Confirmation filter, open backlog, readable peak
  wording, disabled Focus Summary, no false retry, and genuine live data.
- Stage 3: Reports no longer embeds fabricated report rows or national totals.
  Without supplied genuine data it shows the existing No Reports state; loaded
  tests use explicit test-only fixtures. Real directory-derived rows, all
  canonical statuses, search/status/region filtering, static cards, and
  national summaries independent of filters are preserved. Refresh and retry
  actions remain visible but disabled until an approved callback is supplied.
- Focused Reports coverage now verifies the honest default with no fabricated
  rows/totals, genuine directory data, unchanged national summaries after a
  filter, disabled retry without a callback, and the existing narrow-row
  regression.
- Remaining blockers: F03 focused search/history and F04 shared status-badge
  adoption are shared-owned. Shared route wiring in `lib/main.dart` must be
  ownership-approved before Insights Back can preserve the originating filtered
  list; municipality missing-record handling has the same route-ownership gate.
  I06 AI insights remain blocked.
- Validation blocker: do not run Flutter/Dart validation until the local SDK
  startup issue is resolved. Device validation is required for narrow and
  large-text card layouts and the existing Reports filters/states.

### V01–V04 follow-up - Ministry refresh ordering and snapshot provenance

- `MinistryDataDirectory.refresh()` now assigns each read a monotonically
  increasing request revision and captures the current session generation.
  Only the newest current refresh may publish report rows, municipal contacts,
  loading/error state, confirmed-snapshot provenance, or the directory
  revision. Late successes and failures therefore cannot overwrite a newer
  authoritative result.
- Reports and contacts are parsed into local collections before either is
  published, then applied together as one Ministry snapshot. A latest failure
  retains a previously confirmed snapshot and records `failed`/stale state;
  a first failure remains `unavailable`. A successful empty response is a
  confirmed `loaded` snapshot, distinct from never having fetched.
- `clearSession()` advances both fences before clearing the report/contact
  snapshot, so a pending directory read cannot repopulate it afterwards. The
  existing shared `SessionDataService.clear()` already calls this method; any
  future shared logout or session-switch path must retain that integration.
- Added `test/ministry_data_directory_test.dart` with deferred-response
  coverage for out-of-order success/failure, stale retention, confirmed
  emptiness, atomic report/contact publication, latest-loading ownership, and
  session invalidation. Tests were added but not executed because Flutter/Dart
  startup remains blocked; Flutter/device validation remains pending.

## A01 - Admin Dashboard accuracy, privacy, and layout

- Status: Stage 1 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- Dashboard summaries now derive only from marked, authorized live directory
  snapshots. Missing user or audit data is explicitly Unavailable rather than
  presented as a successful zero result; directory preview/mock content is not
  used by the dashboard. Assembly-scoped sessions use the existing
  `AdminSession` visibility rules before aggregates or activity are derived.
- The quiet two-by-two summary has text-only values, vertical dividers, no
  decorative stat icons, and no unsupported percentage deltas. Open Alerts is
  now Alert events and counts only ALERT and CRITICAL audit records.
- The alert-events action remains visibly disabled with an explanation until
  the shared Activity severity-filter route handoff is approved. API health is
  labeled Sample or Unavailable until a genuine authorized Super Admin health
  snapshot is available; an Assembly Admin does not receive platform health.
- Dashboard retry and pull-to-refresh are disabled unless an approved combined
  refresh callback is supplied, preventing a local success state without a
  genuine refresh. Focused Admin widget coverage now includes unavailable
  defaults, explicit fixture data, no percentage delta, and disabled retry.
- Remaining dependencies: shared route ownership for Activity severity handoff
  and `lib/main.dart` wiring for an approved combined dashboard refresh and
  authorized live state. Flutter/device validation remains required for both
  Admin roles, unavailable/error states, responsive layout, and live data.

### A01 follow-up - reactive directory presentation

- `AdminDashboardScreen` now rebuilds its directory-derived presentation when
  the existing Admin User or System Activity directory reports a snapshot,
  loading transition, error, or confirmed empty result. It performs no fetches
  and registers no manual listeners; a merged notifier is owned by the widget
  tree.
- Retained snapshots after a directory refresh failure are explicitly marked
  as potentially stale instead of appearing newly confirmed. Unavailable
  sources remain Unavailable, while confirmed empty snapshots show zero.
- Focused widget coverage adds explicit user/activity fixtures for reactive
  metric updates, alert/critical-only event totals, assembly scoping, empty
  snapshots, stale indications, and 375px/1.5x layouts. Tests were added but
  not executed because Flutter/Dart startup remains blocked.
- Remaining blockers are unchanged: shared `lib/main.dart` combined-refresh
  wiring, the Activity severity-filter route handoff, verified role/session
  authorization, backend enforcement, and Flutter/device validation.

## A02 - Admin drawer active states and navigation accessibility

- Status: Stage 1 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- `AdminScaffold` now accepts a module-local active drawer destination and
  exposes the selected item with existing primary tokens and selected
  semantics; inactive items remain neutral. The native Flutter `Drawer`, its
  slide animation, barrier, swipe, and system-Back dismissal were retained.
- Role Management and Admin Profile identify their drawer destination. The
  Maintenance Teams list, create/edit form, detail, and missing-detail states
  all identify the same Maintenance Teams drawer family without new routes or
  `lib/main.dart` changes.
- The existing shared `KebabMenuButton` remains unchanged and continues to use
  Flutter's popup-menu overlay. Focused Admin widget coverage now covers
  selected/inactive semantics, Role/Profile/Teams states, native Back and
  barrier dismissal, Assembly Admin drawer absence, and a lower-viewport menu.
- Remaining limitation: User Management's mock fallback and no-Firebase retry
  behavior are separate data-accuracy work, not part of this drawer/menu
  stage. Flutter/device validation remains required for drawer gestures, both
  themes, large text, and popup placement on physical devices.
- Follow-up accessibility improvement: the existing Admin header menu,
  notifications, Back, and profile controls now each expose one named semantic
  button and matching tooltip without changing their callbacks, dimensions, or
  disabled state. The nested icon/tooltip semantics are excluded to avoid
  duplicate screen-reader announcements. Focused widget coverage verifies
  labels, native Drawer opening, Back/profile callbacks, and disabled profile
  semantics; it has not been executed because Flutter/Dart startup is blocked.
- Shared blocker: `AdminSession` currently treats missing role/tier information
  as Super Admin. Verified authentication/session ownership must replace that
  fail-open presentation; it was not changed in this A02-only follow-up.

## A03 - Admin User Details modernization

- Status: Stage 1 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- `AdminUserDetailsScreen` now uses a compact, left-aligned identity row with
  initials, name, phone, text role, and an account-status badge. Identity and
  status have scoped semantics without duplicating the visible child labels.
- Account information, Access, Permissions, and Account Activity now use
  text-only headings and calm unboxed read-only rows. Existing editable role,
  tier, region, assembly, and status controls, plus the save/cancel/discard,
  loading, unavailable, error, and unauthorized flows remain unchanged.
- Focused Admin widget coverage verifies the compact identity content,
  identity/status semantics, text-only section hierarchy, and a 375px,
  1.5x-text layout. Flutter/device validation remains required for both
  themes, large text, keyboard/Back,
  permission guards, save failure, and a real authorized user record.
- Remaining owner-gated work: direct-route user scope enforcement and
  transactional deletion/membership cleanup require confirmed authorization
  and I01/W02 server contracts; no API or directory behavior was changed here.

## A03 - Create User visual modernization

- Status: Stage 3 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- Create User now has text-only Your Jurisdiction, Account Details, and Access
  headings with spacing-based grouping instead of decorative heading icons and
  bordered section wrappers. The existing jurisdiction picker and Access
  dropdowns are unchanged.
- Full Name and Phone Number are now underline-style fields with persistent
  visible labels, existing error text, name/telephone autofill hints, and
  next/done keyboard actions. Provisioning, Firebase token handling, API/SMS
  warnings, freeze behavior, confirmation, and draft preservation paths were
  not changed.
- Focused Admin widget coverage covers heading/Access availability, underline
  decorations, keyboard and autofill configuration, validation errors, and a
  375px 1.5x-text layout. Existing creation-freeze coverage remains intact.
- Remaining blockers: A03 Stage 2 direct-route protection remains blocked on
  a verified Admin session signal; backend authorization and server-enforced
  creation freeze remain required. Flutter/device validation is pending.

## A03 - Admin User Directory data integrity

- Status: implemented; Flutter/Dart validation remains pending because SDK
  startup is blocked before commands begin.
- `AdminUserDirectory` now starts empty and unavailable. Production no longer
  presents `mockAdminUsers()` as a fetched user roster; fixtures remain
  explicit in Admin tests only. Its unavailable, loading, loaded, and failed
  states distinguish unfetched data from a server-confirmed empty list, while
  retaining a previously confirmed list as stale after a failed refresh.
- Refresh without Firebase now reports unavailable rather than succeeding as a
  no-op. Save, deactivate, and delete no longer apply local success fallbacks:
  they require Firebase credentials and an authoritative server response before
  changing the directory.
- User Management now presents unavailable, confirmed-empty, failed, and
  stale-record states honestly. Create User now passes the exact validated,
  server-returned record to its callback instead of selecting an arbitrary
  first directory entry. Focused tests seed user fixtures explicitly and cover
  unavailable/empty presentation plus Firebase-less mutation failures.
- Remaining blockers: `lib/main.dart` still swallows initial refresh failures
  and resolves missing user IDs by falling back to the first record; it needs
  route-owner correction. `SessionDataService.clear()` must invalidate pending
  user-directory requests before clearing notifiers. Verified Admin identity,
  backend list/read/update/delete authorization, transactional membership/lead
  cleanup, and the API timestamp contract remain owner/server dependencies.
  Timestamp parsing was intentionally unchanged. Flutter/device validation is
  deferred.

### A03 follow-up - directory ordering and provenance correction

- Successful create, update, deactivate, and delete responses now invalidate
  conflicting list reads only when the server confirms the mutation. Older or
  concurrent list responses cannot replace a newly confirmed mutation.
- `hasLiveSnapshot` now means only a successfully fetched complete authorized
  user list. A confirmed single-user response is retained locally but does not
  enable Dashboard totals or present a partial directory as loaded.
- User Management now presents a genuine first-load token/API failure as an
  error, while a failed refresh after a confirmed empty list retains that
  empty snapshot and labels the refresh as stale.
- Directory tests use controlled asynchronous request hooks for overlapping
  refreshes, mutation/read ordering, partial upserts, confirmed-empty lists,
  token failure, and failed mutations. They have not been executed because
  Flutter/Dart startup remains blocked.
- Remaining shared-owner blocker: `SessionDataService.clear()` must call
  `AdminUserDirectory.invalidateAndClear()` before clearing Admin session
  data, so in-flight authenticated reads are invalidated. Direct-route
  fallback, verified identity, backend authorization, timestamp-contract, and
  Flutter/device validation blockers remain unresolved.

### A03 follow-up - session safety and mutation ordering correction

- `AdminUserDirectory` now advances a private session generation when
  `invalidateAndClear()` runs. Delayed list reads, saves, deletes, and Create
  User responses check their captured generation before applying local data,
  so an earlier session cannot repopulate the cleared directory or trigger
  Create User success/navigation feedback.
- Per-record mutation revisions make the most recently started save,
  deactivate, or delete operation authoritative for local presentation. A
  late result for the same user is discarded; mutations for different users
  remain independent. This is client-side ordering only and does not claim
  server-side transaction ordering.
- User Management no longer installs pull-to-refresh while the directory has
  no genuine supported refresh operation. The directory comment now describes
  confirmed server data rather than a mock fallback.
- Deferred-response tests cover session clear during refresh/save/delete,
  stale Create User results, same-user save/delete ordering, independent
  users, and unavailable pull-to-refresh. They have not been executed because
  Flutter/Dart startup remains blocked.
- Remaining shared-owner blocker: `SessionDataService.clear()` must invoke
  `AdminUserDirectory.invalidateAndClear()` before it clears Admin session
  state. Backend authorization must still reject stale or unauthorized writes;
  verified session identity, route fallback, timestamp contract, and
  Flutter/device validation remain unresolved.

### A03 follow-up - mutation revision cleanup

- Per-user mutation tracking now removes an entry when its currently owning
  save or delete operation finishes, including failure paths. A directory-wide
  monotonic mutation revision prevents a late older response from becoming
  current after that cleanup; newer operations for the same user therefore
  remain authoritative, while distinct users remain independent.
- Focused directory tests cover cleanup after success and failure, out-of-order
  same-user saves across cleanup, independent-user operations, and the existing
  session-clear behavior. They have not been executed because Flutter/Dart
  startup remains blocked.
- Remaining shared-owner blocker: `SessionDataService.clear()` must invoke
  `AdminUserDirectory.invalidateAndClear()` before it clears session data, so
  pending authenticated operations are invalidated. Server authorization and
  Flutter/device validation remain required.

### A03 follow-up - User Details honest retry availability

- Removed the `Future.delayed` User Details retry transition that changed an
  error or offline state to loaded without making a confirmed request.
  `AdminUserDetailsScreen` has no genuine detail-refresh callback or safe
  directory lookup contract, so those states now explain that reloading is
  unavailable and expose no Retry action.
- Focused Admin widget coverage now verifies that error presentation has no
  Retry control and remains an error after the former timer interval. Existing
  User Details navigation coverage remains in place. These tests have not been
  executed because Flutter/Dart startup remains blocked.
- Remaining blockers: shared route resolution still falls back to the first
  user for an unresolved direct route; verified Admin-session identity and
  backend read/update/delete authorization are required before a genuine,
  safely scoped User Details reload can be integrated.

## A04 - Maintenance Teams selectors and form state

- Status: Stage 1 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- Maintenance Teams region and assembly filters are now full-width children of
  the list scrollable, so they move naturally with list content while the
  existing search, filtering, loading states, navigation, and native GlassFab
  remain unchanged. The screen-local selector copy is now exactly `Select
  region`, `Select Region first`, and `Select assembly`; the shared
  `RegionAssemblyPicker` was not changed.
- Changing a form region now clears its assembly, selected members, and lead.
  Changing its assembly clears selected members and lead. A lead-only edit is
  now dirty and therefore uses the existing discard confirmation.
- Focused Admin widget coverage adds scrolling/full-width selector and exact
  placeholder checks, region/assembly stale-state clearing, and lead-only
  discard confirmation. Existing member-selection and lead-reassignment
  coverage remains intact.
- Remaining blockers: `lib/main.dart` still falls back to the first team for
  an unresolved direct-route ID; this requires route-owner approval. The
  directory's no-Firebase mock fallback and timer retry are addressed in
  Stage 2. Team list/read/write/member/lead authorization must remain
  server-enforced; a fail-closed client guard is blocked until Admin sessions
  expose a verified identity signal. Flutter/device validation remains needed
  for scrolling filters, selector menus, narrow/large-text layouts, and both
  admin tiers.

## A04 - Maintenance Teams data accuracy and server-operation safety

- Status: Stage 2 implemented; automated validation remains pending because
  Flutter/Dart startup is blocked before commands begin.
- The shared Maintenance Team directory now starts with no production mock
  records and an explicit unavailable state. A confirmed successful server
  response is the only path to loaded data, including a genuine empty list.
  A failed later refresh retains previously confirmed records and labels them
  as stale rather than presenting success.
- Create, update, and delete server operations now fail without Firebase or a
  server response; they no longer mutate production directory records as a
  local success fallback. Form drafts and existing error messages remain in
  place on those failures. The screen retry now invokes the genuine directory
  refresh rather than a timer-driven loaded transition.
- Admin test fixtures now seed Maintenance Teams explicitly. Focused coverage
  adds unfetched-versus-confirmed-empty presentation, no default mock row,
  failed retry retention, and no-Firebase mutation failure checks, while
  retaining the Stage 1 filter/form tests.
- Affected consumer: `test/maintenance_widget_test.dart` still assumes the
  former global `TEAM-0001` mock fixture. It needs owner-approved explicit
  test seeding before its next validation run; no Maintenance test or
  production file was modified here. Municipal tests already explicitly seed
  their shared-directory fixtures.
- Remaining blockers: `lib/main.dart` still swallows initial refresh failures
  and owns direct-route fallback behavior. Backend list/read/write/member/lead
  authorization and a verified Admin-session signal remain required. Device
  validation is pending for unavailable, stale-data, retry, form-failure, and
  both-role flows.

### A04 follow-up - dirty form system Back protection

- Create and Edit Team forms now route Android/system Back and the shared
  Admin header Back control through the existing dirty-discard confirmation.
  Clean forms close normally; dirty forms keep their draft on Keep Editing and
  close only after Discard. The form serializes an open discard dialog and the
  one intentional post-confirmation pop so repeated callbacks cannot stack
  confirmations or recursively re-intercept the route owner's `maybePop`.
- Focused Admin widget coverage adds clean create system Back, dirty create
  Keep Editing/Discard behavior, and dirty edit header Back behavior. Existing
  Cancel and lead-only discard coverage remains. These tests were added but
  not executed because Flutter/Dart startup remains blocked.
- External blockers remain: Franz owns the `lib/main.dart` missing-team route
  fallback; verified Admin session identity and backend team authorization are
  required; and the Maintenance-owned `TEAM-0001` test needs explicit fixture
  seeding. Flutter/device validation remains pending.

### A04 follow-up - Team Details header navigation

- Existing and missing Maintenance Team detail states now expose the standard
  Admin header Back control through their existing approved route-close
  callback. Equivalent body-level Back controls were removed from both states.
- Focused Admin widget coverage adds existing-detail header Back, missing-team
  header Back, native/system Back, duplicate-control absence, and Maintenance
  Teams drawer-family selection checks. These tests were added but not executed
  because Flutter/Dart startup remains blocked.
- The shared `lib/main.dart` missing-team direct-route fallback, verified Admin
  session identity, backend team authorization, and Flutter/device validation
  remain blocked outside this Admin-owned presentation change.

### A04 follow-up - Team Details member-data accuracy

- Team Details now observes the existing `AdminUserDirectory` notifiers.
  Teams with no member IDs retain the empty-team message; assigned teams show
  loading or unavailable member-detail states until a confirmed user snapshot
  arrives. Confirmed partial snapshots identify unresolved members rather than
  calling the team empty, and failed refreshes label retained details as stale.
- Focused Admin widget coverage adds genuine-empty, unavailable, loading,
  live-arrival, confirmed-member, partial-resolution, and stale-snapshot cases.
  Existing Team Details Back coverage remains. These tests were added but not
  executed because Flutter/Dart startup remains blocked.
- The shared `lib/main.dart` missing-team direct-route fallback, verified Admin
  session identity, backend user/team authorization, and Flutter/device
  validation remain blocked.

## A05 - System Activity accuracy, layout, and retry behavior

- Status: Stage 1 implemented; automated Flutter/Dart validation remains
  pending because local SDK startup is blocked.
- System Activity no longer initializes from fabricated audit events or mock
  health metrics. An unfetched directory is explicitly unavailable; a loaded
  empty list remains a confirmed empty audit feed. Explicit test fixtures stay
  available only when supplied to the screen.
- Corrective pass: the screen now observes the Admin-owned directory state, so
  an unavailable no-Firebase/unfetched directory cannot remain permanently in
  the route's loading presentation. Genuine in-flight directory requests still
  render loading; confirmed empty, loaded, failed/stale, and unavailable
  states remain distinct.
- Health readings are labelled Live only after the existing authorized health
  endpoint supplies all displayed fields and a valid source `checkedAt` value.
  Incomplete or malformed health responses are discarded as Unavailable.
  Explicitly supplied fixture metrics are labelled Sample. Malformed API
  activity without a timestamp is rejected instead of being assigned the
  current time.
- Retry and pull-to-refresh are enabled only when an actual available refresh
  callback exists. The timer success fallback was removed. Failed refreshes
  retain a prior authorized snapshot with a stale-data notice; otherwise the
  error/unavailable state remains visible.
- The time-range selector now sits outside the collapsible search and category
  header but inside the normal Activity list, so it scrolls naturally with
  content. Search, centered category-chip labels, time filtering, and existing
  Admin-session scope filtering remain intact.
- Focused Admin coverage now exercises directory unavailable/loading/empty/
  stale transitions, explicit fixture/sample and valid Live-health rendering,
  disabled retry without a callback, failed refresh, time-range scrolling,
  malformed activity/health mapping, and existing search/chip and Assembly
  Admin filtering behavior.
- Remaining blockers: I04 audit-detail/severity route handoff, F07 tier-scoped
  notifications/deep links, verified Admin-session identity, backend
  authorization, and `lib/main.dart` route/refresh ownership remain outside
  this stage. Flutter and device validation are still required for both tiers,
  refresh failure/stale presentation, narrow screens, large text, keyboard,
  and Back behavior.

### A05 follow-up - System Activity refresh request ordering

- `AdminSystemActivityDirectory` now assigns each refresh a monotonically
  increasing revision. Only the latest initiated refresh may publish activity
  records, health provenance, loading, error, state, or snapshot provenance.
  A delayed older success or failure is discarded, preserving the newer
  confirmed populated or empty snapshot, or the newer failure/stale state.
- The existing production Firebase and Admin API paths are unchanged. The
  directory's test-only construction hooks support deterministic deferred
  responses without introducing mock production activity or health data.
- No dedicated Activity-directory test previously existed, so
  `test/admin_system_activity_directory_test.dart` was added. Its deferred
  tests cover success/success, failure/success, success/failure, confirmed
  empty, stale-snapshot failure, and health-provenance ordering. They have not
  been executed because Flutter/Dart startup remains blocked.
- Remaining shared-owner blocker: `SessionDataService.clear()` directly clears
  Activity notifiers but does not invalidate pending Activity requests. Shared
  session ownership must invoke an Admin-owned request invalidation before
  clearing the snapshot, or an old authenticated response may repopulate it.
  Flutter/device validation remains pending.

### A01/A05 follow-up - independent System Health request ordering

- Health-only reads now use a dedicated monotonically increasing revision in
  `AdminSystemActivityDirectory`. A full Activity refresh invalidates earlier
  health reads when it starts, then starts its own health read only after its
  current Activity snapshot is confirmed. The most recently started health
  read, whether standalone or full-refresh-owned, is the only one allowed to
  publish health data or health provenance.
- Health-only operations remain isolated from Activity records, Activity
  loading, state, and errors. Delayed older health successes and failures are
  discarded, while strict complete-payload validation continues to prevent
  incomplete data from becoming Live health.
- Deterministic deferred-response coverage now exercises health-only
  success/success, failure/success, success/failure, both full-refresh and
  health-only overlap orders, preserved Activity records, and incomplete health
  data. These tests have not been executed because Flutter/Dart startup remains
  blocked.
- Shared session invalidation remains unresolved: `SessionDataService.clear()`
  must invalidate pending Activity and health operations before clearing its
  notifiers. Flutter/device validation remains pending.

### A05 follow-up - Activity and Settings widget coverage

- Focused `test/admin_widget_test.dart` coverage now verifies both System
  Activity and System Settings at 375px with 1.5x text scale. It checks the
  Activity filters/time-range control and Settings supported controls, plus
  the Activity confirmed-empty and both screens' honest unavailable
  explanations, for visible content and layout exceptions.
- A deterministic screen-level Settings save was not added: the screen uses
  the static production directory directly and exposes no injectable save
  callback or directory instance. Existing directory tests already cover
  deferred save/refresh ordering; adding widget-level network simulation would
  require new production test wiring, outside this no-production-change pass.
- These widget tests have not been executed because Flutter/Dart startup
  remains blocked. Shared logout/session invalidation is also still blocked:
  `SessionDataService.clear()` must invalidate pending Admin directory
  operations before clearing snapshots.

### A05 Stage 2 - System Settings accuracy, honest availability, and UI corrections

- System Settings no longer initializes from `mockSystemSettings()`. The
  Admin-owned directory begins unavailable with conservative non-authoritative
  fallback values for non-UI consumers; the screen never presents those values
  as confirmed platform configuration.
- Directory provenance now distinguishes unavailable, loading, loaded, and
  failed snapshots. A refresh requires Firebase and an authenticated user;
  missing Firebase or credentials cannot turn Retry into a false loaded state.
  A failed refresh preserves only a previously confirmed server snapshot and
  the screen marks that snapshot stale.
- GET/PATCH settings responses must provide a supported session timeout plus
  boolean audit-logging and account-creation values. Partial or malformed
  responses are rejected rather than receiving invented permissive defaults.
  Drafts remain intact on save failure, and the form adopts only the validated
  response returned after a successful save.
- The screen now has one Admin-local, text-only `System Preferences` heading.
  It no longer uses the shared decorative `SettingsSection` wrappers or renders
  General Configuration, Security & Access, or Service Preferences headings.
  Default Language, Maintenance Mode, and Public Status Page remain disabled,
  neutral-grey Coming Soon rows.
- Focused tests now cover strict settings mapping, unavailable/loading/
  confirmed/stale screen states, disabled retry without Firebase, explicit
  fixture rendering, permitted headings, Coming Soon controls, dirty/reset,
  and save-failure draft preservation. Automated Flutter/Dart validation is
  still pending because local SDK startup is blocked.
- Remaining blockers: verified Admin-session identity, backend Super Admin
  authorization and enforcement of account freeze/audit/idle-timeout policy,
  and real backend/device validation. Flutter UI state does not prove
  server-wide policy enforcement.
- Corrective pass: while a server save is in flight, the timeout dropdown,
  supported switches, Reset, and Save are disabled, and the save indicator is
  retained. The screen-level update/reset/save guards prevent local draft
  mutations or repeated saves until the request resolves. Success adopts the
  validated server snapshot; failure restores editing while retaining the
  unsaved draft and existing error feedback.
- Final concurrency correction: the Admin-owned settings directory now assigns
  each request an operation sequence and captures the confirmed-settings
  revision. Full settings reads exclusively own loading/state/error and use
  last-started-wins ordering among full reads. Session-timeout-only reads are a
  separate field-update lane: they never cancel or resolve a full read's
  loading state. A validated successful full read advances a full-snapshot
  generation, so any older timeout-only response is discarded; a failed full
  read does not manufacture that generation or a confirmed snapshot. A
  validated successful save advances the revision; any older full-read or
  session-timeout response/error is discarded before it can alter the
  confirmed snapshot or current state.
- Directory tests use controllable asynchronous callbacks to cover delayed
  token acquisition followed by save, full refresh plus session-timeout
  overlap, refresh then save ordering, failed save with an active refresh,
  multiple full reads completing out of order, stale refresh failure,
  malformed save responses, timeout-first then newer-full success/failure,
  delayed session-timeout reads, and normal valid refresh/save responses.
  The operation sequence is only a local UI-consistency measure: it does not
  establish session identity, backend authorization, or cross-device write
  ordering. `SessionDataService.clear()` still resets directory notifiers
  directly without invalidating in-flight requests; resolving that session
  boundary requires shared session/auth ownership. Those remain
  backend/shared-owner and device-validation blockers.

### A05 follow-up - System Settings current-refresh loading

- Removed aggregate full-refresh accounting from
  `AdminSystemSettingsDirectory`. The loading notifier is now owned solely by
  the latest applicable full refresh, so an older pending read cannot keep the
  screen busy after a newer refresh succeeds or fails.
- Early current-refresh failures clear loading as well, and a validated
  successful save clears any spinner held by an older refresh that becomes
  stale once the save advances the settings revision. Existing response,
  stale-snapshot, timeout-only-read, and save ordering rules remain unchanged.
- Deferred directory coverage adds newer-success and newer-failure cases while
  an older response remains pending, verifies the older completion cannot
  change loading/state/error, and retains confirmed settings as stale after a
  latest-refresh failure. Tests have not been executed because Flutter/Dart
  startup remains blocked.
- `SessionDataService.clear()` still clears Settings notifiers without an
  operation-invalidation hook. Shared session/auth ownership must add that
  integration; Flutter/device validation remains pending.

### A05 Stage 3 - Role Management accuracy and accessibility

- Role Management is now explicitly a read-only reference catalog for the
  fixed Super Admin and Admin tiers. Tier descriptions and the permission
  comparison state that they do not verify current server authorization or
  enforce backend policy.
- Removed the fabricated permission-audit age and the unfiltered `View Detailed
  Logs` substitute. The screen now explains that verified audit history and
  audit-detail navigation are unavailable until the I04 contract is approved.
- Removed timer-driven Retry recovery. Offline and error states remain honest
  and have no Retry action because no live role-management refresh exists.
- Permission results now have role/capability/reference allow-or-deny semantics
  and switch to readable labelled results on narrow screens or larger text.
  Focused widget coverage covers the reference copy, unavailable audit state,
  disabled retry/navigation, semantics, 375px layout, and 1.5x text scale.
- Remaining blockers: verified Admin identity, backend role/permission
  authorization, live role assignment/management APIs, I04 audit-detail and
  filter routing, and Flutter/device validation. Static reference data is not
  evidence of server-side permission enforcement.

### A05 Stage 4 - Admin Notifications safe unavailable state

- Admin Notifications no longer derives account events, relative timestamps,
  or notification counts from `AdminUserDirectory`. It now presents an honest
  unavailable state until F07 supplies a durable, server-authorized Admin inbox.
- Read/unread, mark-all-read, Clear all, swipe dismissal, pull-to-refresh, and
  inferred user-detail navigation are not exposed on the Admin screen. The
  existing native header and Back route remain available.
- Focused Admin widget coverage checks the unavailable copy, absence of mock
  account/event content and inbox controls, retained bell-route entry, no
  inferred user-navigation callback, and narrow 375px/1.5x-text Back behavior.
- Remaining blockers: F07 tier-scoped inbox/read-dismiss synchronization,
  trustworthy event timestamps and counts, safe notification payload/deep-link
  contract, verified Admin identity, backend authorization, and shared
  `lib/main.dart` Admin-route guard/record lookup (including removal of its
  first-user fallback). Flutter and device validation remain pending because
  the local SDK cannot start.

### A04 follow-up - Maintenance Teams async request ordering

- `MaintenanceTeamDirectory` now gives team-list reads a last-started-wins
  revision and uses per-team mutation revisions for server-backed updates and
  deletes. A confirmed create, update, or delete invalidates any earlier list
  read, so an older Admin or Municipal list response cannot restore outdated
  team data after a mutation is accepted.
- A newer same-team mutation is the only one allowed to publish a local team
  change; mutations for different teams remain independent. A server-confirmed
  mutation superseded locally by a newer same-team request now reports that
  outcome rather than returning as a local success or overwriting newer UI.
  Failed mutations leave confirmed records untouched. The directory now also exposes the
  Admin-owned `invalidateAndClear()` hook, which clears records and prevents
  pending reads or mutations from publishing after a future shared session
  owner calls it.
- The ordering is local UI protection only. The client cannot determine the
  server's final state when overlapping writes are accepted out of order by the
  backend; a later authoritative server refresh is required for reconciliation.
  It does not provide authorization or transactional guarantees.
- Added deterministic directory coverage for out-of-order list responses,
  create/update/delete versus earlier refreshes, same-team and different-team
  mutation overlap, mutation failure, stale snapshots, and invalidation. Tests
  have not been executed because Flutter/Dart startup remains blocked. Shared
  session integration and Flutter/device validation remain pending.

### A04 follow-up - Maintenance Team mutation revision uniqueness

- Corrected a same-team ordering defect: active per-team revision entries are
  removed when work finishes, so deriving a later revision from that map could
  reuse an older value while an earlier request was still pending. The
  directory now assigns every update/delete a monotonically increasing
  directory-wide mutation revision, while retaining the bounded per-team map
  only for current-operation ownership. An older completion therefore cannot
  become current after cleanup and a later same-team mutation.
- Deterministic deferred coverage now exercises the three-operation sequence
  (A starts, B finishes and cleans up, C starts, then A finishes late), failure
  cleanup, different-team independence, existing invalidation, and existing
  refresh/mutation ordering. Tests were added but not executed because
  Flutter/Dart startup remains blocked.
- This remains local UI ordering only. Server-side write ordering,
  authorization, and cross-device reconciliation require backend ownership.
  `SessionDataService.clear()` still needs shared-owner integration with
  `invalidateAndClear()` before logout/session changes; Flutter/device
  validation remains pending.

## Step 216 - final implementation and validation status

This section supersedes earlier entries in this progress record that say the
Flutter SDK prevented test execution. Those statements are retained as
historical context only.

### Completed implementation status

| Task | Status | Remaining boundary |
| --- | --- | --- |
| C01 - My Reports | COMPLETED and TESTED | Trust-rating/Profile and verified authentication integration remain shared-owned. |
| C02 - Nearby Issues | PARTIALLY BLOCKED | The owned accessible sheet/navigation slice is complete; I03 server-authorized proximity and safe-detail data are required for the full feature. |
| C03 - Create Report | COMPLETED and TESTED | Server-side submission idempotency and real device camera/location/permission validation remain required. |
| C04 - Report Tracking | PARTIALLY BLOCKED | Pending Approval presentation is complete; I07 map-gesture policy and guest-account report-ownership/origin continuity remain product/shared Auth work. |
| V01 - National Dashboard | COMPLETED and TESTED | Shared live-state/refresh route wiring and genuine backend data remain integration work. |
| V02 - National Analytics | COMPLETED and TESTED | I06 AI/comparison contracts and shared refresh/live-state wiring remain unavailable. |
| V03 - Municipal Performance | COMPLETED and TESTED | Genuine backend aggregates, authorization, and approved shared refresh wiring remain required. |
| V04 - Reports and Insights | COMPLETED and TESTED | F03/F04/I06, safe origin restoration, and missing-record route handling remain shared integrations. |
| A01 - Admin Dashboard | COMPLETED and TESTED | Verified Admin identity, server authorization, and shared Activity navigation/refresh wiring remain required. |
| A02 - Admin Drawer | COMPLETED and TESTED | Verified role/tier identity is required; absent tier data must not imply Super Admin. |
| A03 - User Management | COMPLETED and TESTED | Shared missing-user route handling, session invalidation integration, and backend authorization remain required. |
| A04 - Maintenance Teams | COMPLETED and TESTED | Shared missing-team route handling, server authorization/write ordering, and the Maintenance-owned `TEAM-0001` fixture remain required. |
| A05 - Activity, Settings, Roles, Notifications | COMPLETED and TESTED within safe scope | I04 audit-detail routing, F07 secure inbox, verified Admin identity, and backend contracts remain pending. |

### Verified automated and browser validation

- TESTED in normal Windows PowerShell: Admin suites **260 passed**, Citizen
  suites **34 passed**, and Ministry suites **155 passed**; **449 passed** in
  total.
- The Chrome manual walkthrough has been completed. No detailed Chrome
  findings were supplied for this record, so this document does not infer or
  claim additional browser/device evidence.
- PENDING INTEGRATION: Android/iOS physical-device validation remains required
  for keyboard and system Back behavior, text scaling, narrow layouts, themes,
  camera/photo and location permissions, map behavior, offline/reconnect
  handling, and authenticated API flows.

### Remaining integration and backend blockers

- `lib/main.dart` is shared-owned and still needs safe direct-route
  missing-record handling, approved live-state/refresh assembly, route
  arguments/origin preservation, and verified Admin-tier route guards.
- `lib/services/session_data_service.dart` must invalidate Admin directory
  operations before clearing their notifiers. Admin-owned directories expose
  invalidation protections, but shared logout/session-switch integration is
  still required to prevent delayed responses from repopulating cleared data.
- Authentication and backend owners must provide verified role, tier, assembly,
  and region authorization. Client-side scope filtering is not server-side
  authorization.
- Backend ownership remains responsible for authoritative API health, audit
  history/detail filtering (I04), durable tier-scoped notifications with
  read/dismiss/deep-link safety (F07), proximity-safe Nearby data (I03), AI
  insights/comparisons (I06), guest report continuity, report submission
  idempotency, and cross-device mutation ordering.

### Commit-preparation ownership note

- `lib/features/admin/screens/admin_profile_screen.dart` contains a one-line
  `activeDrawerDestination: AdminDrawerDestination.adminProfile` change. It
  corrects active-drawer presentation, but Profile is explicitly owned by Aziz
  under `LATIF_AGENT.md`. Preserve the file unchanged and exclude it from a
  Latif-only commit unless Franz/Aziz approves inclusion.
- The four dedicated directory tests are required Latif test additions:
  `test/admin_maintenance_team_directory_test.dart`,
  `test/admin_system_activity_directory_test.dart`,
  `test/admin_system_settings_directory_test.dart`, and
  `test/ministry_data_directory_test.dart`.
- Temporary diagnostic output files are not commit content:
  `admin-widget-failures*.txt`, `c01-review.txt`, and `c02-*-errors.txt` /
  `c02-*-test-results.txt`.
