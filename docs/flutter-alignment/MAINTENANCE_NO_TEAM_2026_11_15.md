# Maintenance without a team · 15 November 2026

An active, verified Maintenance account can use Home, Profile and its personal
inbox without team membership. This follows the owner-accepted Web behavior.

## Investigation

The existing task directory already verified membership and skipped task reads
when the team was null. On the old installed DEV build, the unassigned account
showed a usable zero-count Home and generic **No assigned tasks** on Tasks.
The owner's earlier Tasks error did not reproduce in this sample. Genuine API
failures must retain recovery; this change does not treat every failure as empty.

New regression checks failed before the repair for missing assignment guidance,
mounted detail retaining former-team records, and an unknown task link opening
the first cached task. These reproduced source defects are distinct from the
unreproduced device error.

## Resulting behavior

- Home, Tasks and Profile share assignment guidance. Home retains its greeting,
  honest zero assigned-work counts, chart and navigation. Tasks Retry and pull
  refresh reverify membership and load a newly assigned team's work.
- Detail, Update Progress, Task Record and the full location map use the same
  task-access boundary. It verifies membership on entry/resume, resolves the exact
  requested task and removes content when its scope is lost. A missing task ID
  never substitutes the first cached task in the live app.
- A same-team refresh or transient failure preserves an existing update draft.
  A scope change resets that draft even if removal and reassignment occur before
  the next rendered frame. Existing Back/discard confirmation stays intact.
- Task responses retain only the verified crew's records. Denied reads clear
  cached work; temporary failures retain their error/retry state. Null, empty
  and whitespace membership IDs withhold task reads. Server permissions remain
  authoritative. No sample records or permission expansion were introduced.
- The existing personal notification inbox remains independent of task loading.

## Validation and remaining gate

The automated checkpoint and verified DEV installation are recorded separately
in Web `docs/CURRENT_STATUS.md` and its private artifact/device ledger. Coverage
includes both themes, 320/375/428px at 2× text, membership recovery/removal,
denied/transient reads, exact/deep task links, Back and draft preservation.

Owner acceptance remains a separate gate. Check Home, Tasks Retry, Profile and
personal Notifications on DEV. Report any repeat of the earlier Tasks error
with its entry/connection conditions. Automated fictional membership changes do
not establish a live administrator assignment/removal workflow check.

Canonical continuation: `C:/Projects/www/civic-voice-web/docs/CURRENT_STATUS.md`.
No merge, promotion or production deployment is authorized by this work.
