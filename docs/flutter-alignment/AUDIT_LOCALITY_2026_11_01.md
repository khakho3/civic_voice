# Audit actor and event locality - 1 November 2026

Owner report: a Super Admin acting on local staff appeared to inherit the target
locality in the Actor area. Source reproduction: detail grouped `region` and
`assembly` under "Actor and scope", although the API uses those fields as event
jurisdiction. It records actor ID/public ID/name/role separately and has no actor
geography/tier snapshot. Historical records must not be reinterpreted or rewritten.

Native a6c9f66 separates Actor from Event jurisdiction and explains the locality.
Web fc50be7 makes the same separation and labels jurisdiction explicitly in list
captions. Missing identity/locality remains "Not recorded". No API schema, access,
event data or PTR behavior changed.

Two native and two web regressions failed before the repair and pass after it.
Validation: 1,979 full Flutter tests, analyzer, 435 web tests, lint/build and six
existing API contract checks pass. Native detail's existing actual-font/theme/
320/412/1440px and 1x/1.5x/2x text cases pass within that suite. These are automated
checks, not owner acceptance. DEV install/device evidence is tracked separately
in the private device checklist and canonical web CURRENT_STATUS.

Owner authorizes autonomous queue work, integrator edits in all three repos and
DEV testing with two approved mutable accounts. Keep their identifiers and all
credentials private. The separate approved Super Admin's role must never change.
Keep fixes scoped, test before pushing, retain existing production isolation and
do not merge, promote or deploy. Work one issue at a time; keep external device
and policy gates explicit while continuing independent ready work.

Next: Activity initial Last24 failure, then local staff mutation, then queue06.
Kingsben's Ministry assignment remains independent. Owner-accepted PTR stays closed.
