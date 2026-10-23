# Shared native preview checkpoint

## Shared saved-location and draft-photo previews - 23 October 2026

Native `af68ac4` extracts the existing Maintenance full-screen map as one read-only report-location viewer. `a966e59` adopts it for Citizen tracking/review/Nearby/duplicate inspection and Municipal review/active/closed details. Municipal active/closed projections retain the original coordinates instead of dropping them. Missing or invalid coordinates never open an invented fallback pin; map inspection cannot change the issue location. Existing Maintenance external-map behavior is retained.

`5abbf6f` connects Citizen draft upload/review and Maintenance completion attachments to the existing selected-index swipe/zoom/share gallery. Previewing does not remove or submit photos. Completion thumbnails are square with the remove target clear of the centre. Existing upload/removal/source flags, submission keys, permission boundaries and completion rules are preserved.

Verification: full native suite **1,188 pass**, analyzer and whitespace clean. New checks cover exact saved pin/immutable map inspection, both themes, invalid/missing coordinates, Municipal coordinate projections, draft selected-index/swipe/close and retained attachments. The existing Maintenance route test now previews/swipes completion evidence and confirms all three attachments remain before submission. This is automated verification; real device map/gesture acceptance remains pending. Web runtime/API source and production are unchanged. Private device checks stay uncommitted.

Next: native first-invalid-field focus/scroll, then notifications and Admin reconciliation, followed by the queued password-field follow-up. Maintenance live workflow acceptance still awaits the owner's planned account. Francis retains ordinary-success/checkmark and native Activity Detail. No integration promotion, merge or production deployment.

