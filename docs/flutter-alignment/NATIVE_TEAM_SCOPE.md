# Teams, leads and current Maintenance identity - 31 October 2026

Runtime `732ef9d` implements queue item 05's native freshness fixes.

- Maintenance Profile quietly refreshes on entry/resume and supports the shared
  top pull-to-refresh. Failure retains the last available profile with a retry
  warning. There is no page-center loader.
- Verified signed-user sync is authoritative for team name/current lead. A stale
  Admin directory cannot override it. Preview directory changes also repaint the
  mounted Profile; an explicit absent lead never falls back to an old lead.
- Profile reads verify Firebase UID, role, activity and non-guest access. Newer
  reads win; logout/relogin and identity changes fence earlier responses. A name
  save during a read survives while membership still refreshes. Revoked access
  clears the cached identity; temporary unavailability retains the last snapshot.
- Team/account/jurisdiction changes immediately clear cached task cards. Late
  responses, including a move-away/move-back cycle, cannot restore them. An
  unassigned technician does not fetch an assigned-task list. Any authorized
  member may submit; pending-approval/completed tasks remain read-only.

The API also preserves omitted PATCH fields, serializes membership/lead changes,
guards deletion and jurisdiction moves with outstanding work, and refreshes current
contacts/notification recipients. The owner chose to block a move while assigned,
in-progress or pending-approval work remains. Existing report transitions remain;
this slice does not introduce an active-work reassignment UI.

**Automated:** 1,669 full Flutter tests pass; analyzer clean. Nineteen new
service/widget cases cover identity/scope/read races, removal, lead changes,
entry/resume/PTR, error/retry and mounted Profile updates. Fifty-one focused cases
also pass. Test fixtures are not real account/role/report mutations.

The isolated DEV profile APK through 732ef9d is artifact-verified, wirelessly
replace-installed and launched on the Pixel 9 Pro XL, retaining data and matching
installed digest. All 63 source/14 protected configuration hashes match; DEV
package/signing/Firebase, compiled LAN API4000 and no production targets verified.
The owner restored the API; fresh actual-process DEV/local-database, readiness,
phone LAN and Maps identity/restriction checks pass. No agent API restart.
Owner confirmation remains pending: test item05 first, then review PR21, then the
agreed merge and possible further client tasks. No PR review/merge in this step.
Evidence stays in canonical web CURRENT_STATUS.md and ignored private ledger.
Do not reopen the owner-deferred Activity gap.

Kingsben's branch has independently advanced to `12c483c`; it was fetched for
coordination only. Its Maintenance/Municipal scope and PR target are unchanged.
Preserve these session/task-directory/Profile/main-route changes when reviewing
his open PR #21. No contributor work was merged or overwritten.

Current PR inspection (1 November): [Kingsben PR #21](https://github.com/khakho3/civic_voice/pull/21)
is open from `codex/flutter-kingsbeng-maintenance-municipal` to
`codex/flutter-latif-review-fixes`. Head `12c483c`; target is correct. Awaiting
separate review; no review acceptance or merge is claimed by item 05.
