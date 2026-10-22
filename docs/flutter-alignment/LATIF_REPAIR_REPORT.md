# Latif PR integration review and repairs

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
