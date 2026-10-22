# Latif PR integration review and repairs

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

22 October 2026. PR: https://github.com/khakho3/civic_voice/pull/20
Submitted head: 82d11cd461c7db5d54ae0b16b09688920d5c4e20
Base: codex/flutter-web-alignment, 6ace645.
Review branch: codex/flutter-latif-review-fixes, C:/Projects/mobile/civic_voice_latif_review.

## Code Review

**Verdict:** REQUEST CHANGES on the submitted PR head. Local repairs are a separate candidate, not a remote approval or merge.
**Confidence:** HIGH for the reproduced failures and repaired boundaries; physical-device/live end-to-end acceptance remains pending.

The PR removes production preview fallbacks and adds useful request ordering, provenance, navigation and accessibility coverage. The full integration suite exposed two failures not reflected by the contributor's 449 selected passing tests. A real GitHub review with three inline findings is submitted at https://github.com/khakho3/civic_voice/pull/20#pullrequestreview-5609504702.

| Priority | Finding at submitted head | Local repair |
| --- | --- | --- |
| P1 | Ministry Dashboard treats missing/unconfirmed data like a confirmed zero-report snapshot | Directory state/provenance now drives the real route. A missing snapshot shows unavailable, loading stays distinct, and successful empty data alone shows zero. Prop changes update the existing screen state. Failed retry errors are caught, and the error page scrolls at small sizes. |
| P2 | Admin Profile does not supply the new active drawer destination | Added the missing Profile destination; retained the failing selection assertion. |
| P2 | Maintenance test dereferences TEAM-0001 after production mock removal | The test explicitly seeds/restores its required fixture. Production directory stays empty until real data arrives. |

### P1 - Unconfirmed Ministry data rendered as zero

File at submitted head: lib/features/ministry/screens/ministry_dashboard_screen.dart:128. The null-data branch and genuine zero branch were identical, while the shared route built aggregates before a verified snapshot existed. A cold or failed API read could therefore look like zero national reports. The repair gates the route on provenance, listens to directory transitions and tests failure/loading/confirmed-empty states on the actual app route. A 320-pixel error-layout overflow exposed by the fix was repaired without weakening responsive assertions. The route-navigation test now asserts the honest unavailable state before continuing every existing navigation check.

## Shared-owner integration repair

This boundary was explicitly documented as outside Latif's ownership, rather than attributed as a new contributor regression: SessionDataService.clear() directly emptied notifiers without invalidating in-flight authenticated work. It now uses the user/team invalidators and new Activity/Settings invalidators. Pending reads, health reads and settings saves cannot repopulate the previous account's data after logout. Reset states are unavailable, not a confirmed empty result. New delayed-response tests exercise the fences. No server mutation cancellation or token revocation is claimed.

## Analyzer cleanup

Removed an unused private optional parameter, used the current semantic flag API, migrated unused callback parameters to Dart wildcards, and updated deprecated text scaling/null-aware element syntax. Assertions were preserved. Generated plugin headers had only line-ending differences after pub get; those were normalized and excluded. No dependency upgrade or native Firebase/Maps configuration change.

## Validation

- Submitted head full suite: 871 passed, 2 failed.
- Submitted head analyze: 1 warning, 46 infos, no errors.
- Repaired targeted Ministry/responsive run: 272 passed before the final failed-retry test was added.
- Final full suite: 878 passed, 0 failed.
- Final analyze: no issues found.
- Whitespace: clean.
- SDK: Flutter 3.47.7. Dependency bootstrap and first command startup were slow; cached/offline pub get and no-version-check commands completed. No SDK reinstall or destructive lock/cache cleanup was used.

No main/integration promotion, push, merge, deployment or physical device install. The original native checkout and its untracked assets/branding/notification-monochrome.svg are preserved.

## Next acceptance and owed integration

1. Prepare a verified isolated DEV phone build using matching DEV Firebase and API settings before installation; never build this review checkout's committed production config directly onto the phone.
2. Admin: open Profile and its drawer; check the active item. Logout while Users/Activity/Settings is loading, then sign into another role and confirm no old data reappears.
3. Ministry: cold/offline dashboard must show unavailable, not invented zero metrics. Retry offline safely; reconnect and confirm real data or a genuinely empty snapshot.
4. Citizen: author a report, go back through Photos, submit once, return to the retained My Reports filters/scroll; check Pending Approval tracking.

Remaining integration is not declared complete by this PR: native server password-login adoption and clear auth events; authoritative Nearby API; durable submission keys/receipt recovery; map search migration and routing scope; evidence/proximity/completion rules; shared media/location preview; busy-button contrast; empty-refresh PTR flash; full collapse-on-scroll search across every consumer; notification lifecycle; other live-state route reconciliation; final UI polish. Review the existing API/Flutter owed backlogs, which contain the current implemented server contracts rather than relying on older contributor blocker descriptions. Francis retains the shared ordinary-success/checkmark and native Activity Detail tasks.

## Local repair commits

- dd1f4c5: Profile drawer selection and explicit Maintenance test fixture.
- 1af2765: Ministry provenance, retry and small-screen error safety.
- ee4b736: Admin session invalidation and delayed-response tests.
- c5d87c2: analyzer cleanup preserving assertions.
