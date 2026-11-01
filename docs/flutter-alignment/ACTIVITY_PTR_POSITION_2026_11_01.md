# Activity shared PTR placement - 1 November 2026

Runtime `e29b4b9` moves the live Activity refresh wrapper from inside the list
to the complete body, including search/filter chrome. It uses the existing
`GhanaRefreshIndicator` with `AdminScaffold.contentPadding(context).top`, matching
Admin Home. Star/bar feedback belongs directly below the app bar, above search
and category pills. Denied access still has no refresh wrapper.

No shared PTR code, search/filter implementation, API/query, history, Time/date,
paging/detail/Back behavior or role/scope policy changed. The stable refresh
content key and existing no-central-loader behavior are retained. The independent
possible minimal middle gap remains owner-deferred; no further gap work here.

## Evidence

- Four new geometry cases reproduced the bar at y208 instead of the app-bar
  bottom y88 on the old tree: **120px too low**. All four pass after repair at
  320/412px, both themes, with 24px safe areas. They assert fixed anchor, retained
  rail/card elements, restored geometry and completed indicator removal.
- **1,977 full Flutter tests pass; analyzer clean.** Fifty-seven focused
  Activity/detail/refresh tests pass, including existing fast/slow loading,
  repeated pulls/failure, no page-star/text flashes and no remounted cards.
- Four additional private font/icon-loaded Home/Activity render cases pass,
  both themes, with eight drag/loading captures. Home and Activity both place
  the bar at y88; drag star is below that edge, and the content retracts while
  loading. Representative captures were visually inspected.
- No live account/team/report/role mutation for QA. Automated geometry and
  rendered fixtures are not the owner's phone acceptance of this placement.

## Installation and next work

Verified isolated DEV through e29b4b9 is wirelessly replace-installed and launched
with retained data and matching installed digest. All 73 source/14 protected
configuration hashes match; DEV identity/signing/Firebase/LAN API, actual API
DEV/local database, phone readiness and Maps restrictions pass. Owner explicitly accepts
the new position on 1 November 2026. No reinstallation or acceptance of the
independent Kingsben task is implied.

The isolated DEV profile build/install is recorded in canonical web
`docs/CURRENT_STATUS.md` and private `.tmp/dev-activity-ptr-position-preflight.json`.
Owner confirms the feedback is in the right place under the app bar and above
search/filter pills. Placement is accepted; earlier requested phone checks remain
owner-confirmed. A new default Last24 empty-view report is logged separately as
ACTIVITY-INITIAL-TIME-WINDOW; this acceptance does not close that data issue.

Next reserved investigation: ADMIN-AUDIT-LOCALITY and then
ACTIVITY-INITIAL-TIME-WINDOW, followed by ADMIN-SCOPE-MUTATION,
then queue06 submission reliability. Do not broaden permissions or infer creator
ownership. Full reports are in canonical web
`docs/OWNER_ADMIN_FOLLOWUPS_2026_11_01.md`. Kingsben's Ministry task remains separate;
his task branch is not updated or merged by this fix. No promotion/deployment.
