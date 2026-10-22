# Native report submission safeguards - 22 October 2026

Implemented on `codex/flutter-latif-review-fixes`: `074f27e` (durable receipt intent), `826f1fd` (recovery navigation), `4a7f4e6` (selected-pin duplicate suggestions). These adopt the existing API contracts; no API/database/Firebase/config change, deployment or promotion is included.

## Save and retry

Before sending, the app persists an account-scoped opaque submission key, frozen report fields and private copies of 2–5 evidence files. Editable draft cleanup cannot remove these copies. Concurrent submits share one request; timeouts, invalid receipts and uncertain responses retain the same intent. Retries reuse the same fields/key/evidence. A successful HTTP response requires the matching echoed key, boolean replay flag, report ID and public reference. Replays can return the report's current advanced status; the own-report cache upserts its ID instead of duplicating it.

Reopening Create checks the pending intent first and returns to its frozen Review screen. Recovery offers Check submission again or My Reports; Back cannot return to editable Photos while the save is uncertain. Missing evidence or damaged saved receipt data blocks a new intent instead of dropping photos or silently rotating the key. Conflict/deleted-original responses keep the receipt for recovery; do not force-clear it to recreate the same report. A first definitive validation/auth/quota rejection permits correction; a later rejection cannot disprove an earlier uncertain save.

Account/session checks prevent late results from clearing another account's draft, republishing old reports or navigating a new session. A verified receipt clears the editable draft before removing the receipt, preserving safe recovery if interrupted between those operations.

Limits: local recovery depends on app-private storage. Clearing app data, uninstalling or OS/storage loss can remove it; check My Reports before recreating an uncertain report. This does not provide a server-side pending-intent inbox. No new cryptographic GPS/photo-authenticity claim is made. The server's content fingerprint remains authoritative if saved content is damaged or altered.

## Similar reports before Photos

Continue checks the selected issue pin and current title/description/category against `/api/reports/duplicate-candidates`. No match advances directly; an optional lookup failure preserves the draft and allows reporting. Stale results are ignored when the draft or session changes, and repeated taps cannot open several steps.

The shared native sheet displays the privacy-limited candidates, reference/status/distance and an optional location preview. The citizen can view their own existing report, report a different issue, or explicitly confirm the same issue through the shared confirmation dialog. Own, already-confirmed, work-started and otherwise ineligible candidates never offer invalid seconding. No citizen assembly/locality selector, automatic merge, rejection, trust penalty, canonical linking or AI was added.

Confirmation reuses NearbyReportsService: fresh device GPS, within 300 m of the existing issue, accuracy at most 100 m, age at most 60 seconds and at most 10 seconds into the future. The selected issue pin is not proof of presence. Verified seconding clears the authoring draft and opens My Reports without creating a new report or inventing a new-report success reference. An uncertain confirmation blocks blind repeats and directs the citizen to check Nearby Reports; the draft remains available.

## Verification and next work

Complete native suite: **1,114 passing tests**, zero failures; analyzer and whitespace checks clean. Added 33 cases cover store/restart/evidence recovery, account isolation, concurrent/replayed/rejected saves, receipt transport/validation, recovery navigation, selected-pin discovery, malformed/ineligible candidates, stale edits, distinct/seconded decisions and ambiguous confirmation. Existing fresh-location tests also pass. These are automated checks; real provider/GPS/phone acceptance is still pending and its checklist stays private/uncommitted.

No new phone build was installed. Original integration checkout/owner notification SVG remain untouched. Keep the review branch unpromoted. Next implementation: Places New and automatic routing reconciliation, then remaining evidence/completion, shared UI, validation, notification and Admin reconciliation in the recorded order. Admin dashboard placeholders/count/status-bar findings remain queued before promotion. Password-field masking/padlock requests are recorded in the web's NEXT_UI_FIXES.md and FLUTTER_OWED_BACKLOG.md; they do not interrupt this order. Francis retains ordinary-success/checkmark and native Activity Detail work. Optional Google logging stays OFF.

Release prerequisite: deploy the matching API with its submission-receipt migration before releasing this client. An older API cannot acknowledge these retry keys. Production configuration and data were not changed.
