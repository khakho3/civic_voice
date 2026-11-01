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

The isolated DEV profile APK is built and artifact-verified from this runtime:
63 source hashes match, all 14 protected DEV configurations are unchanged,
DEV package/signing/Firebase and explicit LAN API4000 are verified, with no
compiled production target. It is **not installed**. Installation and owner
confirmation must be recorded separately in canonical web
`docs/CURRENT_STATUS.md` and the private device checklist. The previous confirmed
installation is `c00a80c`; ADB is currently disconnected and API4000 unavailable.
No merge, promotion or deployment. Do not reopen the owner-deferred Activity gap.

Kingsben's branch has independently advanced to `12c483c`; it was fetched for
coordination only. Its Maintenance/Municipal scope and PR target are unchanged.
Preserve these session/task-directory/Profile/main-route changes when reviewing
his future PR. No contributor work was merged or overwritten.
