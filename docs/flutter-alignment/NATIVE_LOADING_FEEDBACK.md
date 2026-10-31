# Flutter loading feedback - 31 October 2026

Owner instruction: no loading animation in the middle of a Flutter screen.
Runtime **c00a80c** (including **1a88c36**/**0298bc8**) uses plain text for
standalone page/sheet loading feedback.
The shared `GhanaLoadingIndicator` has no star or animated decoration; its label
and accessible live-region announcement remain. Ghana star/flag feedback belongs
at the top in `GhanaRefreshIndicator`; button/field busy feedback and determinate
report/step progress retain their behavior.

The earlier **408e630** attempt removed the second bar but retained a page star;
the owner reported that star still flashing and did not accept the result.
**0298bc8** removes page stars globally and Activity's 180px loading container.
Like live Admin Home, Activity keeps verified content steady during refresh and
does not insert an extra updating row; only top PTR provides refresh feedback.
Different filters still clear previous-query results rather than mislabel them.

The owner then reported reduced but remaining millisecond flicker while pulling
to refresh: the wording under the former star was still briefly visible.
**1a88c36** suppresses shared page-loading text throughout every non-idle PTR
phase, including drag/settle before the network callback. The top indicator owns
feedback until it is idle; page-loading text cannot flash underneath it even
when initial and refresh requests overlap. Only the small status widget listens
to indicator frames; the whole Activity list is not rebuilt on every pull tick.

The owner confirms text/star gone on 1a88c36, but reports possible remaining
container space. The page-message slot measures **0px** during PTR; a separate
**80px** pull offset was reproduced on both Home and Activity. Conditional
star/bar siblings remounted the unkeyed refresh content, losing its snap-back
animation and recreating the list. **c00a80c** gives the content a stable key.
Its state/list now survives drag -> loading and the intended 250ms return
animation releases the pull space while the top bar loads. In 8ms render traces,
both screens return to **0px** offset with no extra gap within the body.
The owner confirms text/star gone, then explicitly chooses to skip the possible
remaining middle gap as minimal impact and close this UI follow-up. That gap is
**owner-deferred**; do not investigate further unless reopened. This is narrower
than full spacing or broader Activity Detail/workflow acceptance.

The policy also replaces standalone busy orbs/spinners in Admin Overview,
Alerts/review, Routing/detail, notification loading/updating, nearby reports,
session restoration, biometric availability, Maintenance Profile/photo loading
and Municipal dashboard loading. Shared Ghana page statuses cover the remaining
Maintenance/Municipal detail/list loaders. Data fetching, authorization,
verification and retry behavior are unchanged.

## Automated validation

- **1,650 full Flutter tests pass; analyzer clean.**
- Twelve Activity cases cover pending initial load, a single correctly positioned
  top bar, stale initial completion, repeated refresh success/failure and stable
  search/cards and unchanged card positions during the pending request, in both
  themes. Filter changes and failed-load retries cannot reintroduce page stars.
  Fast initial/refresh overlap is sampled every 16ms for 75 frames: page-loading
  wording is absent from the first pull frame through completion, in both themes.
  A nonzero drag phase is sampled every 8ms: the same card element stays mounted,
  the 80px pull space returns to zero while loading, and the hidden page-status
  slot has zero height. The previous keyless version fails these checks.
- Four shared-status cases cover static, accessible pending feedback at 320px and
  1x/2x text in both themes, with no decorative painter. Existing cold-load
  assertions require plain feedback; the full suite retains layout, auth, inbox
  and busy-control coverage.
- Twenty focused Activity/Home/shared-status checks pass. Six additional
  actual-font Home/Activity cases capture cold load and populated PTR in both
  themes plus initial-request/PTR overlap (ten captures); representative
  cold/refresh renders were inspected, including no page text under active PTR.
  These use the public refresh lifecycle, not physical gestures or owner QA.

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
