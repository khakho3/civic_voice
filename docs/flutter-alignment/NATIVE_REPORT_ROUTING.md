# Native Super Admin report routing

## Item 07 review - 1 November 2026

The queue and detail now use the existing GhanaRefreshIndicator immediately below
their standard app bar, outside the search rail. Short/empty pages support a real
pull. Refresh keeps verified rows mounted without inserting a loading message;
detail reload preserves the unsaved reason and locality choice, disables saving
while reading, and never submits a routing change. Cold loading stays static and
its text disappears while the top PTR is active. Shared indicator and accepted
Activity behavior are unchanged.

Six new light/dark checks cover a real queue pull, exact bar position, retained
card geometry, detail draft preservation/no write and slow first-entry refresh
with stale response exclusion. Phone widths 320/412 and safe insets are included.
All 1,991 Flutter tests, 19 routing widget checks and analyzer/whitespace pass.
The existing 18 API routing/geography checks and eight web routing checks pass.
Six new real PostgreSQL fixture checks verify competing routing editors, two
officer claims, atomic routing/audit/inbox rollback, audit-off and zero staffing.
These use a separately guarded temporary database and no real report changes.

DEV build/install and agent phone checks are recorded in the canonical web
checkpoint/private device checklist. Owner acceptance remains separate. The
known claimed-report boundary discrepancy remains a ground-truth review gate;
do not alter or backfill that report. No API authorization/routing behavior,
geometry, historic records, production targets, merge or deployment changed.
Older verification/install paragraphs below are historical.

Updated24October2026. Runtime commits7b25813 /983468e; stable-alert follow-up ad28085. Current cross-repository checkpoint: C:/Projects/www/civic-voice-web/docs/CURRENT_STATUS.md.

## Scope and access

- Existing API: GET /api/admin/report-routing?limit=25&q=…&cursor=…; GET/PATCH /api/admin/report-routing/:id. API source/schema/config remain41404be.
- Named native route /admin/report-routing, available from verified Super Admin's drawer and Management card. Direct links/resource dispatch are fenced by the verified Super Admin owner; ordinary Admin navigation and authority are unchanged. Server active-account/first-password/access checks remain authoritative.
- Every resource owns the full account/session-generation/role/tier/jurisdiction key. Late credentials/reads/writes cannot publish into another owner. There is no mock/cached live-source fallback.

## Inspection and allowed changes

The bounded cursor queue includes only server-confirmed unresolved reports, including locked records for read-only inspection. Opening a row fetches fresh detail rather than editing its list snapshot. The purpose-specific report projection exposes reference/title/description/address/community/current geography/issue coordinates/evidence/status/timestamps, not citizen identity or trust/device GPS.

Saved pin inspection reuses ReportLocationMapScreen without an invented fallback. Evidence reuses the selected-index swipe/zoom/share gallery. Routing never edits the report content, pin or evidence. Region/Assembly choices reuse the native canonical directory; a checked-in contract fixture compares all16 exact region keys and261 short assembly names against the existing API directory. Changing Region clears Assembly; a present officer is not a geography authority. Automatic citizen routing remains server-owned from the REPORT PIN; citizens never choose an assembly.

The only write fields are region, assembly, trimmed reason (10–200 characters) and expectedUpdatedAt (the original canonical millisecond UTC timestamp). Only canRoute=true unresolved SUBMITTED records can submit. A confirmation shows reference, previous/new locality and reason. Rapid/double actions, account changes during the dialog/token wait, changed/claimed/assigned records and old versions are fenced by client and existing server checks.

## Acknowledgment and uncertainty

A save acknowledgment must preserve report identity/reference/title/description/address/community/coordinates/evidence/creation time, select the exact requested pair, advance the version, stay SUBMITTED and become resolved/non-routable. Municipal officer count and auditRecorded must be correctly typed. A separate fresh GET must match that acknowledged report/version/geography before success appears.

Uncertain/conflicting/malformed responses and a failed/mismatching fresh read retain the reason and lock further writes until an authoritative reload. No automatic mutation retry. AdminResource now explicitly retains uncertainty after an acknowledged write whose refresh fails; session/owner changes cannot apply this flag or success to the new owner. Reloaded resolved/started records remain read-only. Zero officers does not invalidate the chosen locality; the success message explains future visibility. Audit-off wording does not falsely promise a recorded action.

## Alerts follow-up

Open alerts remains a server-filtered bounded queue. During a new filter request it retains only matching rows from a previously verified page for the same current owner. These are provisional current-page matches, not a new total or a locally complete result set. Cards/search/list state stay mounted and the current result range is retained until the response. Chips can replace an in-flight request without a disabled fade; disposed requests cannot win later. Confirmed totals/empty results come from the server. Missing current-page matches never claim a confirmed empty state; failure stays an error. Real refresh and cold loading keep their existing indicators. This does not repair the separate System Activity pull-to-refresh flicker.

## Verification and acceptance

1,386 native tests pass, analyzer/whitespace clean;18 existing API routing/geography tests pass. Coverage includes exact geography, malformed projections/coordinates/media/cursors/versions, request HTTP shapes, owner changes during reads/tokens/confirmation, duplicate writes, mismatched acknowledgments/fresh reads, zero officers/audit-off, note retention/reload, dependent fields, fresh detail/queue paging and layouts at320/390/412/1440 in light/dark. Alert checks cover held result geometry, rapid replacement/late completion, no orb/unconfirmed-empty, owner exclusion, exact search-close restoration and empty-result scroll-range release. Actual queue/editor/pending-alert renders were visually inspected at320/412 in both themes using local fixtures, not owner mutations.

DEV runtime throughad28085 is artifact/config-verified, replace-installed and launched with app data retained. Exact source/config/artifact/device evidence stays in the ignored private checklist. Installed/running is not physical acceptance. The owner still needs to confirm routing inspection/confirmation/conflict behavior and alert-filter feel. Do not route a real report solely for testing; no test accounts/roles/reports were manufactured. Prior pill/badge checks, Maintenance, real push and System Activity refresh flicker remain pending. No production deployment, merge or promotion. Next implementation is password hiding/padlock icons, then remaining consolidated consistency work.
