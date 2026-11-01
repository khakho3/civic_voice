# Native Guest continuity - 1 November 2026

Native **2e84672** verifies the registration response and binds password handoff to
its Firebase UID. Registration retains the originating identity through mounted
continuations and no longer globally signs out an unrelated session after route
disposal. A changed registration context receives session guidance; only a real
400 verification rejection maps to Incorrect Code. Already-linked Guest tokens
are forwarded so the API can finish the same Guest account.

**2,001 full Flutter tests**, analyzer and whitespace pass. Prior 57 focused auth
checks pass; 13 current cache checks include retained draft/photo/source metadata
through same-UID activation/restoration and isolation from a different account.
The API's eight real PostgreSQL fixture checks prove preserved UID/database/public
IDs/report ownership and safe concurrent/rollback/stale-context behavior. Full API
264 passes/three optional skips; web 464 tests/lint/build pass. Canonical evidence:
C:/Projects/www/civic-voice-web/docs/ITEM11_GUEST_CONTINUITY_2026_11_01.md.

No real SMS, OTP, password change or Guest registration was performed. Live provider
linking, interrupted completion, actual phone upgrade/restoration and owner
acceptance remain open. Broader global SDK/session races remain in item 13.
No production configuration, schema, merge, promotion or deployment change.

DEV profile APK verified and wirelessly replace-installed/digest-matched; 78 source
hashes/14 protected configs and current draft/intent hashes preserved. Launch was
deferred to preserve the current foreground; Guest phone checks remain pending.
