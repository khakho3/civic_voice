# Nearby confirmation safety - 1 November 2026

Runtime **e2e8e9d** validates the nearby discovery contract before presenting a
candidate: at most five unique IDs, nonempty recorded reference/title/category,
finite WGS84 coordinates, finite 0-300m distance and integer confirmation count
0-4. Missing/invalid values fail verification rather than defaulting to a nearby
eligible report. Unexpected private response fields never enter the display model.

This uses a dedicated fromDiscovery parser. Existing duplicate suggestions share
the display model but have a different projection and can include already
confirmed/ineligible reports; their accepted parser, draft and confirmation flow
are preserved. Fresh device fixes, account checks, explicit confirmation,
permission/error behavior and Home/sheet dismissal semantics are unchanged.

A confirmation receipt now needs secondedByMe=true and integer count 1-5.
Malformed/missing counts follow existing unconfirmed-save handling, with no
success claim or blind retry. The fifth confirmation remains a valid receipt.
Web applies the same eligibility/receipt bounds. API 5836900 repairs expiry
reclamation at its existing 5000-key process limiter capacity without changing
per-user quotas, 60-second freshness, 100m accuracy, 300m radius or scoring policy.

Three new native regressions initially failed; all **1,994 full Flutter tests**,
**46 nearby/duplicate focused checks**, analyzer and whitespace now pass. Web has
**446 full checks**, 17 nearby focused checks, lint/build. API has **230 full
passes/one optional SQL skip** and eight proximity/audit checks, including the new
full-capacity recovery regression. These are automated fixture/transport checks,
not owner or physical-presence acceptance. The limiter is process-local and
submitted GPS still is not hardware attestation.

Verified DEV through e2e8e9d is replace-installed, digest-matched and launched on
the approved Pixel with API Online. All 78 reviewed source hashes and 14 protected
DEV configuration hashes match. DEV signing/Firebase/LAN API/local DB/Maps checks,
compiled strict-parser markers and preserved notification/launcher checks pass.
Fresh device draft/intent hashes are unchanged. Nearby agent-phone and owner
acceptance remain pending; canonical web checkpoint/private device checklist
track them. No real reports/roles, production config, merge or deployment changed
in this implementation slice.
