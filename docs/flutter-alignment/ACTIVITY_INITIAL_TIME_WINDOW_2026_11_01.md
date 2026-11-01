# Activity initial time window - 1 November 2026

Reproduced the owner's report on the phone: Last 24 Hours showed "Activity could
not be verified"; changing to All Time displayed history. Flutter's rolling
`DateTime.toIso8601String()` can emit six fractional-second digits. The existing
API accepts up to three and returns 400 for six; the client showed a verification
failure rather than history. This was not an empty authorized result.

Native **6534c50** converts rolling cutoffs to UTC millisecond precision before
formatting. The default remains Last24, with the same inclusive lower bound.
Custom UTC calendar ranges, server scope, cursor reset, failure handling and
accepted shared PTR position are preserved. An injected repository clock makes
the regression deterministic; it defaults to DateTime.now in production.

The fixed-clock regression failed before the precision repair. It now covers
first entry, refresh, 7/30-day presets, All Time and re-entry with a clock containing
microseconds. All **1,980 Flutter tests**, analyzer and 52 focused Activity checks
pass. Six API contract checks pass, including an explicit unsupported-microseconds
case. A read-only authenticated DEV request returned 400 with six digits and 200
with three, with 67 matching recent events. No API behavior or web runtime change.

Verified DEV through 6534c50 is replace-installed/launched on the connected Pixel,
data retained and installed digest matched; all 73 source/14 protected config hashes
and DEV target/signing/connectivity/Maps checks pass. Agent phone checks confirm
67 events on first Last24 entry, navigation re-entry and pull refresh; the seven-day
view also loads. The same build visibly separates historical Actor from Event
jurisdiction in detail. No actor tier is inferred from that historical ADMIN role.
Private evidence: dev-activity-time-preflight.json and phone captures/checklist.

These are agent/device checks, not owner acceptance of either new repair. Owner's
existing PTR acceptance stays closed. Next: ADMIN-SCOPE-MUTATION, then queue06.
