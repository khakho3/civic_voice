# Native validation attention

## Native validation attention - 23 October 2026

Native `753b96e` adds one post-validation focus/reveal helper and adopts it for login, registration, recovery, password setup/change and rejected verification codes. It waits for inline errors, skips disabled/offstage controls, respects reduced motion and ignores work after navigation/removal or a newer reveal request. Existing authentication, OTP, policy and mutation guards remain unchanged; service failures keep separate messages rather than being presented as invalid input.

`2af682b` reveals the missing Citizen title or location action. Continue with too few photos explains the existing two-photo requirement and reveals upload controls without navigating or discarding accepted photos. `3f9e5cd` applies the shared attention to staff identity/jurisdiction and profile-name editing; missing Region is marked before the disabled Assembly prerequisite. `cd84c79` reveals missing Maintenance notes or the first eligible empty evidence slot. Short forms keep their fields mounted inside one scrolling form item so scrolling to Submit cannot dispose the invalid field above. Fixed-header text controls reserve top scroll clearance.

Verification: full Flutter suite **1,193 pass**, analyzer and whitespace clean; final related workflow/attention checks **45 pass** and updated focus tests rerun with simulated keyboard insets/reduced motion. Tests cover first-field order, repeated attempts, rendered visibility/header clearance, safe removal, missing title/photo navigation guards, Admin field focus and existing valid submissions. These are automated checks, not physical keyboard/device acceptance. Existing cards/search/previews and report submission ownership/keys remain intact. No web runtime/API/production change, integration promotion or merge. Private device checklist remains uncommitted.

Next: notification lifecycle/content/navigation reconciliation, then Admin dashboard/routing reconciliation and queued password-field/padlock follow-up. Keep remaining quiet report-card consistency checks recorded; Citizen already has whole-card tapping, trailing chevron and opaque unshadowed fill. Francis retains ordinary-success/checkmark and native Activity Detail. Maintenance live completion acceptance awaits the owner's planned account.

