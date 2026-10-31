# Flutter Admin Activity Detail - 28 October 2026

## Wireless DEV reinstall - 31 October 2026

At the owner's request, unchanged runtime **578ab59** was rebuilt as an Android
arm64 profile APK with `API_BASE_URL=http://192.168.100.8:4000`, verified,
wirelessly replace-installed and launched on the Pixel 9 Pro XL with data
retained. The installed APK digest matches. DEV package/label/signing and
compiled Dart/native Firebase/API pass verification; production targets are
absent. All 53 source hashes and 14 protected configuration hashes match the
previous checkpoint; no source or configuration was copied. The running API's
DEV Firebase/local database, phone-to-LAN health/readiness and Maps provider/
package/certificate restrictions were rechecked successfully.

**Current transport is direct Wi-Fi LAN**, superseding the earlier USB-only
installation below; this build needs no USB cable or ADB reverse for API access.
Exact evidence remains private in `.tmp/dev-activity-wireless-preflight.json`
and `.tmp/device-checks-pending.md`. Owner Activity Detail acceptance remains
pending; no full suite was rerun for this environment-only rebuild. Item 02 was
not started. No account/report/settings, API process, merge, promotion or
deployment change occurred.

Queue item 01 (I04/A05/B01) is implemented in 389487f, with verified-scope
invalidation in 578ab59, in the review checkout. The isolated DEV profile build
is USB-installed and launched; owner phone acceptance remains pending. This is the general audit detail; the
Open Alerts original-event snapshot and its review actions remain separate.

## Integrated behavior

- Live System Activity uses the existing authenticated API list with 50-row
  cursor pages and server-filtered total/alert-event counts. Search, all four
  categories, severity/outcome, action/actor/target and UTC date windows compose.
  Date-only custom ranges include the selected final day using an exclusive
  next-day UTC boundary. Overlong search retains the input and last valid
  query with an explanation; it is not silently truncated.
- Existing history stays visible when collection is off. Alert-event counts
  are explicitly distinguished from unresolved incidents. No audit setting is
  changed. A refresh keeps verified same-owner rows and the search rail mounted;
  errors show a stale-snapshot notice and Retry rather than confirmed empty.
- Whole-card and focused-search actions fetch `/api/admin/activity/:id` afresh.
  Detail shows a full UTC timestamp, original UTC instant, action, outcome
  including UNKNOWN, recorded actor/public ID/role/scope, historical target
  reference and event-specific allowlisted scalar context. Explicit null/false/
  zero remain honest. Observed earlier values are not claimed as transactional
  before-images or proof that every selected field changed.
- Missing/deleted/inaccessible events share the scoped missing state. Access
  denial, service failure, loading and malformed/unrelated replies are distinct.
  Missing actors retain recorded snapshots. Target availability is not invented;
  no unauthorized related-record navigation or arbitrary metadata dump is added.
- Real owner/role/tier/jurisdiction/session keys fence token waits, success and
  failure. Session clear and verified scope changes invalidate loaded screens
  immediately. URL tier
  parameters do not grant authority; the API remains the authorization source.
- Back preserves the mounted list's query, filters, cursor page, scroll and
  keyboard focus. Direct entry replaces itself with Activity, avoiding loops.
  Shared Ghana loading/PTR, collapsible search, Flutter-only animated pills,
  card feedback, Admin chrome and Super-only health remain in use.

## Verification

- Full regression run: **1,627 passes**, with one new login test rejected for
  mismatched fixture UIDs. After the fixture-only correction, its complete
  login-route file passes **16/16**, including the new scope test. No runtime
  correction was needed for that failure; the full suite was not repeated
  after this test-only edit. All **45 new cases** are verified across full and
  focused runs. Final `flutter analyze --no-pub`: **no issues**. Checks cover
  parsing/redaction, real loopback HTTP
  request shape, owner/session/token races, missing/forbidden/error/retry, query
  composition, pages beyond 500, history-off counts, Back/scroll/focus, direct
  entry and actual-font detail/list layouts.
- Detail layout tests: 320/412/1440px, both themes, 1x/1.5x/2x text. Live list:
  320/390/412/1440px, both themes, 2x text. Existing shared-search consumer and
  refresh checks remain covered by the full suite.
- Eight additional ignored actual-font visual cases produce **32 captures**:
  list/detail, top/bottom, 320/412px, both themes, 1x/2x text. Representative
  normal and extreme renders were inspected. These fixtures are not live API,
  installed-artifact or owner device confirmation.
- Existing API audit contract/HTTP checks: **14 pass**. They cover scope,
  inactive/non-Admin gates, pagination, redaction and history-off semantics.
  API and web runtime are unchanged; no real records/settings were mutated.

## Remaining item 01 gate

On 28 October the owner authorized USB installation. Seven reviewed runtime
deltas were copied to the isolated DEV checkout; 53 source hashes match review
and all 14 protected configuration hashes remain unchanged. The profile APK
through 578ab59 was built, artifact-verified, replace-installed and launched on
the Pixel 9 Pro XL with data retained. The installed digest matches the artifact.
DEV package/label/signing, compiled API, Dart/native DEV Firebase and preserved
Android masking hooks pass verification; production targets are absent. Maps
provider and package/certificate restriction checks pass. The existing API
process targets DEV Firebase/local civic_voice; no process/config change occurred.

The build command explicitly uses `--dart-define=API_BASE_URL=http://127.0.0.1:4000`.
USB `adb reverse tcp:4000 tcp:4000` and a phone-side read-only health request
verify connectivity; API readiness passes. Keep the cable attached/API running
and restore the reverse after reconnect. Future Wi-Fi runs must explicitly use
the current LAN define. Exact evidence is private in the web
`.tmp/dev-activity-usb-preflight.json`; the earlier source-only and ce622ea
installation ledgers remain historical. No new full suite was run for this
installation; the source validation above is unchanged.

Owner-check Super/Assembly detail, real missing/forbidden events, filters/paging/
PTR, keyboard/Back/scroll and both themes. These remain pending; installation,
launch and connectivity do not confirm user-visible behavior. Never manufacture
real audit/account/report events or change audit settings just for QA.

The seven runtime deltas recorded in the private ledgers are:
`admin_audit.dart`, `admin_activity_repository.dart`,
`admin_activity_detail_screen.dart`, `admin_system_activity_screen.dart`,
`lib/main.dart`, `lib/services/api_client.dart` and
`lib/services/session_data_service.dart`.

Queue item 09 audit reliability/policy remains open. Item 02 Maintenance is the
next queue item after this slice's gate is recorded; it was not started here.
No merge, promotion, production build, migration or deployment is authorized.
