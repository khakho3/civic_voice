# Native map search and pin routing - 22 October 2026

## Super Admin safeguard client -24October2026

Native7b25813/983468e implements the separately scoped unresolved-locality queue/editor; see [NATIVE_REPORT_ROUTING.md](NATIVE_REPORT_ROUTING.md). Automatic citizen routing remains owned by the server from the issue pin, with no citizen assembly selector. The editor uses the exact allowed geography/reason/version/acknowledgment contract and existing read-only pin/evidence viewers; it never chooses geography from staffing. Installed DEV runtime throughad28085 still requires owner confirmation; no real records were routed for QA. Earlier pending-client statements below are historical.


## Map theme and pin feedback - 23 October 2026

Web `69636c8` applies one dark tile palette to LocationPicker and all shared MapPreview consumers. Changing the resolved app theme updates the existing map without recentering; light mode clears custom styling and unmount disconnects the observer. `ebe43bd` explicitly preserves busy-button opacity, primary fill and WebKit text colour while retaining disabled duplicate-click protection.

Native `eeee12a` / `039b84d` apply the same map palette to all nine GoogleMap instances and put capture/address orb feedback beneath the search control. Dragging dismisses the keyboard, clears stale suggestions and invalidates previous work; confirmation stays unavailable until the selected pin is resolved. The selected coordinates remain authoritative.

Verification: 1,180 native tests, clean analyzer; 365 web tests, lint/build and whitespace checks pass. Browser checked actual busy-button CSS in both themes inside a disabled fieldset; this fixture does not establish real provider/GPS acceptance. Phone map/drag/theme acceptance remains pending. The temporary hotspot origin caused a Maps restriction mismatch; Wi-Fi is back at the already permitted development origin. No Cloud key restrictions were saved or relaxed. Local API readiness is healthy; normal DEV source configuration and app identity remain separate from production. Private installation details remain in the ignored device checklist.

Continue saved-location and local draft-photo preview inventory, then validation, notifications and Admin reconciliation. Maintenance acceptance awaits the owner's planned account. Francis retains shared ordinary-success/checkmark and native Activity Detail. No production deployment, merge or integration promotion.


## Native Places token correction - 23 October 2026

Owner phone testing exposed HTTP 400 from an oversized autocomplete session token: the app encoded 24 random bytes as 48 hex characters, exceeding Google's 36-character maximum. Native commit `331909e` preserves the same secure randomness as 32 URL-safe base64 characters. The serialized-request regression failed before the fix and passes after it; 35 related Places/picker/routing/submission tests and changed-file analysis pass. A live check through the actual corrected Dart PlacesService now passes autocomplete and details. The earlier standalone provider probe used UUIDs and missed this app-specific defect; its configuration/restriction results were valid but did not establish phone search acceptance. No further Cloud/key change is needed. Physical retest remains pending.

Queued native UI follow-up from this test: match the web picker search bar's compact height and rounder corners; replace location-capture loading with the shared orb treatment aligned with web. Record these for shared UI reconciliation after core map behavior; do not interrupt the implementation order or owner-owned success/Activity Detail work.

Review branch `codex/flutter-latif-review-fixes`: `4356c99` migrates Places search, `e36e9be` repairs picker operation ownership, and `e954812` reconciles coordinate-only routing. No production deployment, report/account mutation or integration promotion.

## Implemented

Search now uses Places API (New) autocomplete and details, Ghana-restricted suggestions without excluding named establishments, bounded requests, minimal detail fields and session tokens. Selecting a place ends its active autocomplete session immediately; another query uses a fresh token even while the older detail request is in flight. Mixed query/place rows do not discard valid place suggestions. Invalid/mismatched coordinates cannot become a chosen pin. Provider diagnostics/configuration values stay out of user-facing errors; there is no legacy endpoint or unrestricted retry fallback.

Android supplies the runtime package and signing-certificate SHA-1 headers through the existing configuration channel. iOS supplies its bundle identifier and configured key through that channel; Swift compilation/live iOS acceptance is not verified on this Windows host. Existing keys remain outside tracked files. See Google's [Places New autocomplete](https://developers.google.com/maps/documentation/places/web-service/place-autocomplete), [Place Details](https://developers.google.com/maps/documentation/places/web-service/place-details) and [mobile web-service security guidance](https://developers.google.com/maps/api-security-best-practices#secure-client-side-web-service-calls).

The latest explicit GPS request, chosen search result or map gesture owns the issue pin. Initial/programmatic map idle cannot confirm a fallback centre. Reopening a saved issue pin does not replace it with current/home GPS. Late GPS/detail/geocoder responses cannot overwrite a newer selection or notify a disposed controller; clearing/changing the query invalidates suggestions immediately. Real touch gestures can interrupt programmatic camera movement. Confirmation requires a current, resolved selected pin and waits while its address is resolving. Reverse-geocoder centroids never replace selected coordinates. If address lookup fails, the explicitly chosen coordinates remain confirmable with truthful feedback; unavailable GPS never silently confirms the initial map centre. Capture failures/timeouts leave usable retry/manual-pin controls.

## Automatic routing remains server-owned

Native submission sends the selected issue latitude/longitude and omits geocoder region/assembly hints. The existing API derives jurisdiction from its checksum-verified GSS district polygons. Account/home area, live submission GPS, text addresses and the staff roster are not routing authority. Citizen reporting remains map-only; no region/assembly selector was added.

Unknown, outside, ambiguous or near-boundary pins remain saved/unresolved for the Super Admin safeguard. A correctly scoped report becomes visible on a later matching Municipal inbox read when officers join; creation of an officer does not resolve missing geography or manufacture retrospective pushes. Multiple matching officers can read unclaimed reports, with one atomic claim. Existing historical reports were not rewritten. Native Super Admin routing queue/detail remains part of later Admin reconciliation; it is not claimed complete by these client map fixes.

## Approved configuration and live provider verification

On 22 October 2026, the owner explicitly approved saving the prepared change to `android_maps_key_cv` in `gen-lang-client-0691154247`. The saved allowlist contains exactly **Maps SDK for Android + Places API (New)**. Both existing Android package/SHA restrictions, including the isolated DEV package, remain unchanged. Reopening the key confirmed the persisted selection.

Bounded live probes used the same field masks and session contract as the app. The correct DEV identity returned HTTP 200 and five Wusuta place suggestions. Selecting a suggestion returned HTTP 200 with matching place identity, an address and valid Ghana coordinates. Wrong-package and wrong-certificate probes each returned HTTP 403 / API_KEY_ANDROID_APP_BLOCKED. The former service-allowlist blocker is cleared. No key value, raw place ID or precise coordinate was printed or copied into a tracked file. Provider verification does not replace physical phone acceptance.

## Verification and delivery

Full native suite: **1,138 tests pass**, analyzer and whitespace checks clean. Added 24 cases cover New protocol/fields/identity/session/error handling, picker ownership/disposal/fallback/GPS failures and native coordinate-only multipart submission. Existing seven citizen locality/coverage regressions remain intact and updated for the New response shape. Eighteen existing API geography/routing tests pass, including cross-locality reports from the same citizen, edge ambiguity, zero/multiple officers, future officer visibility and single-winner claims. API source and production data are unchanged.

The isolated DEV source snapshot preserves DEV Firebase and native identity; the final profile APK built successfully with local API4000 explicitly defined. Builds and private acceptance details stay outside Git. No new phone install; real Android capture/search/drag/confirmation and iOS compile/provider acceptance remain pending. The existing native_exif Kotlin Gradle migration warning is pre-existing and did not require a dependency change here.

Next: owner phone acceptance, then evidence/proximity/completion reconciliation in the recorded order. Keep shared UI/validation/notification/Admin debt queued, including the Admin dashboard findings and password masking/padlock follow-up. Francis retains ordinary-success/checkmark and native Activity Detail. Optional Google activity logging remains OFF.
