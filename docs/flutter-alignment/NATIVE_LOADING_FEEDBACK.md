# Flutter loading feedback - 31 October 2026

Owner instruction: no loading animation in the middle of a Flutter screen.
Runtime **408e630** makes standalone page/sheet loading feedback static. The
shared `GhanaLoadingIndicator` retains its star, label and accessible live-region
announcement without an animated bar. Animated Ghana refresh feedback belongs
at the top in `GhanaRefreshIndicator`; button/field busy feedback and determinate
report/step progress retain their behavior.

The Activity defect was reproduced in an actual-font widget render: a pending
initial request plus the public refresh lifecycle displayed two flag bars.
The corrected light/dark renders display only the top bar. This is automated
fixture/render evidence, not a physical gesture or owner acceptance claim.

The policy also replaces standalone busy orbs/spinners in Admin Overview,
Alerts/review, Routing/detail, notification loading/updating, nearby reports,
session restoration, biometric availability, Maintenance Profile/photo loading
and Municipal dashboard loading. Shared Ghana page statuses cover the remaining
Maintenance/Municipal detail/list loaders. Data fetching, authorization,
verification and retry behavior are unchanged.

## Automated validation

- **1,644 full Flutter tests pass; analyzer clean.**
- Six new Activity cases cover pending initial load, a single correctly positioned
  top bar, stale initial completion, repeated refresh success/failure and stable
  search/cards during the pending request, in both themes.
- Four shared-status cases cover static, accessible pending feedback at 320px and
  1x/2x text in both themes. Existing cold-load assertions now require static
  feedback; the full suite retains layout, auth, inbox and busy-control coverage.
- Sixty focused cases pass before the full run. Two additional ignored
  actual-font render cases pass; both light/dark captures were inspected.

## DEV and owner gate

The owner authorizes verified DEV installation after completed changes without
another confirmation question. Continue to follow the canonical web
`docs/BUILD_ENVIRONMENT_CHECKLIST.md`, preserve isolated DEV configuration and
data, and record the actual installed artifact in the private device checklist.
Production builds/deployments, merges and promotions still require instruction.

DEV runtime/install evidence and remaining owner checks are recorded in
`LATIF_PROGRESS.md` and the web `docs/CURRENT_STATUS.md`. Installation is not
owner acceptance: check Activity initial load/PTR, Time -> Custom dates,
Back/filters/page/scroll, light/dark themes and the pending Activity Detail and
completion-workflow gates on the phone.

## Team integration

Kingsben's assignment and branch are unchanged. This owner/integrator policy
also makes small loading-only edits to Maintenance Profile/photo placeholders
and the Municipal dashboard loading row on the target working branch. Preserve
those edits when integrating his 02/03/23 work; no workflow or API contract was
changed by this slice.
