# Native permission onboarding - 1 November 2026

Citizen Home defers notification setup when an explicit location request opens
new blocked-location guidance. It resumes the notification offer when that guidance
is dismissed, avoiding overlapping setup dialogs. The status-only location check
now reports an undetermined permission as unavailable; explicit acquisition can
still obtain a genuine position on a browser without permission-query support.

Tests reproduce the old overlap and the two false-ready states. Additional cases
cover denied status-only resume, granted/blocked decisions, disabled GPS, existing
while-in-use/always grants and explicit unknown-state position acquisition. Native
role eligibility, OS permission scope, asked marker and notification/inbox behavior
are retained. No manifest, Firebase or production configuration change.

Actual phone fresh-install/denial/restricted/restoration and owner acceptance remain
open. Read-only DEV phone snapshot shows notifications granted and fine/coarse
location not granted; no permissions or owner data were reset. iOS was not built
or tested on this Windows host. Canonical validation/install record:
C:/Projects/www/civic-voice-web/docs/ITEM12_PERMISSION_ONBOARDING_2026_11_01.md.
No merge, promotion, migration or deployment.

## Validation and DEV installation

Native 45318ef: 2,011 full tests/analyzer/whitespace and 41 focused permission,
Citizen and push-registration checks pass. Web ad9e3ff: 468 full tests/lint/build/
whitespace and 18 focused setup/push checks pass. Two web and three native regressions
failed before their respective fixes. API unchanged; prior 264 passes/eight Guest
SQL checks remain applicable, without an unnecessary API rerun.

DEV profile APK is artifact-verified, wirelessly replace-installed and installed-
digest matched. 79 reviewed source hashes/14 protected configs and fresh current
device draft/intent hashes are preserved. DEV package/signing/API/Firebase/no-prod
checks, phone LAN health and Maps restriction checks pass. Existing foreground
was left alone; launch/actual permission setup phone checks are pending. This is
not owner acceptance. Notification scale/launcher resources remain intact.
