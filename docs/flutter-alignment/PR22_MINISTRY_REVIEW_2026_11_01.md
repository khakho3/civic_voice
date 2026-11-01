# PR22 Ministry review and integration - 1 November 2026

Verdict: **APPROVE after integrator repairs.** Confidence: high for reviewed code
and automated checks; physical/owner acceptance remains pending.

PR: https://github.com/khakho3/civic_voice/pull/22
Contributor head:78e12e01e9f7c12a1e61c87e28e113067bc397ad.
Working target baseline:ee979bc18e40b1621626d02b4566fddcda60a347.
Verified combined source:871ca629573f1d9d002007e321caf37032ed74cf.
Source fixes:bd94ee1 (route recovery),871ca62 (shared-header lifecycle).

## Contributor work

Kingsben changed five Ministry screens, six fixture/test files and his progress
record. The changes constrain narrow/large-text headings, make long state content
scrollable, wrap loading chips and municipality labels, disable blank-phone
contact actions, catch failed refresh/retry callbacks and preserve filters through
authoritative recovery. Views remain read-only and insights deterministic.
The work stays within the issued assignment; no API, web, Firebase, signing,
dependency or production configuration was changed. His source clearly records
failed checks and physical acceptance gaps rather than claiming a passing suite.

## Integrator followups

| Concern | Resolution / evidence |
| --- | --- |
| Real Analytics/Performance/Reports/Insights routes did not follow directory state/revision or consistently wire refresh | Four route regressions failed before repair. All four factories now listen to the existing shared directory, pass only its confirmed projection and expose the existing authenticated refresh. Missing/unavailable data is an error; confirmed empty data remains distinguishable. |
| Performance/Insights retained local error state after a parent recovered, and could claim retry success before authoritative publication | They accept changed parent state without clearing selected filters. A completed callback alone does not establish loaded data. |
| Ordinary shared-header disposal could lazily construct the unused rail controller during teardown | Controller/curve are created in initState and disposed normally; two ordinary/rail no-scroll lifecycle regressions pass. Motion, tokens and accepted scroll behavior are unchanged. |
| Existing route fixture expected an empty result without a confirmed snapshot | Assertions now require unavailable/error feedback; route navigation and absence of invented records remain checked. |

The directory keeps its confirmed snapshot on a failed refresh. Existing Dashboard
error presentation is preserved and the other routes now follow it consistently;
recovery reuses the retained data/filter state. This does not claim a new cached
content banner or broader offline/platform acceptance. API scope and session13
ownership checks remain unchanged.

## Validation

The contributor reported100 failures on his environment. The combined candidate
here passed all29 recovery/shared-filter checks before integrator changes; those
100 failures were not independently reproduced here. The lazy lifecycle hazard
was still corrected directly. The four new real-route regressions were red before
the route repair, then passed. All35 focused route/recovery/lifecycle/shared-filter
checks pass.

Final exact source: **2,354 full Flutter tests pass**, analyzer reports no issues,
and git whitespace check passes. This includes all298 contributor cases, the
current2,050-test working baseline and six integrator regressions. The first full
integration run had2,353 passes/one outdated route assertion failure; the final
full run was repeated after correcting that expectation and passed completely.
No test was skipped, removed or weakened to hide an exception.

Contributor matrix: six populated screens at320/390/412/768px, both themes and
1x/1.5x/2x text;120 loading/empty/error cases;24 search/keyboard cases; five
simulated contact failures/blank-phone checks and five recovery sequences. These
are labelled isolated fixtures, not screenshots or live provider/device proof.

No phone input, capture, OS preference change, account/role/report mutation or
installation occurred. Phone availability remains unconfirmed. Pending DEV2d142ca
contains session13 but not this Ministry integration; build/verify/install the
current merged native source only after resuming and confirming availability.
No main merge, promotion, migration or deployment is authorized by this review.
