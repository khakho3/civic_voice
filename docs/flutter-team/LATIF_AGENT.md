# Latif - Flutter alignment agent instructions

## READY — 15 October 2026: Latif may start

Aziz and Kingsbeng are reviewed and accepted. Kingsbeng's original PR commit 04dd917 and reviewed repair commits through a498f15 are included in integration. The refreshed codex/flutter-latif-modules branch starts from codex/flutter-web-alignment with this guide added. Work only on codex/flutter-latif-modules; PR base codex/flutter-web-alignment. Main remains unchanged. Remote publication has been verified for both branches; Latif may start. This readiness supersedes every older wait instruction in historical reports.

Sequence: Aziz -> reviewed integration -> Kingsbeng -> reviewed integration -> Latif. Start from the refreshed remote branch, never old main or an old local branch. If a local Latif branch already exists, inspect for unpushed work, fetch, and use git merge --ff-only origin/codex/flutter-latif-modules only when safe. Stop and report divergence; never reset/force-push contributor work.

Accepted baseline: 708 Flutter tests pass; flutter analyze and whitespace checks clean. DEV phone verified Municipal assignment, non-lead completion with three evidence photos, send-back validation/reason and final approval. Preserve all repairs, including Location.assembly propagation, the unique district resolver, unknown-coverage notice, report-reference/title notifications, account guards, first-start timestamps and pending-approval semantics. Fresh Citizen notification/coverage and photo removal/replacement device checks remain honest follow-ups.

Search follow-up (22 October 2026): the local review branch codex/flutter-latif-review-fixes now supplies shared compact/focused search across all ten list consumers (1a61e5b, 37a26de). Full suite 970 passed; analyze clean. See LATIF_REPAIR_REPORT.md for the current contract. Physical acceptance and integration promotion remain pending. Keep all future search behavior shared and test every consumer; map search and form member pickers remain separate.

API gate: local API branch codex/api-web-integration commit efe742e fixes same-assembly completion approval/return and removes staffing-based jurisdiction guesses (76 tests). This is not deployed to production. Do not mutate API/cloud/production or copy someone else's local Firebase settings. Arrange an approved isolated DEV environment for manual flows; never assume an approved Flutter merge deploys server fixes. Native Places HTTP search, evidence-minimum contract, durable inbox, checklist persistence, public sharing and owner-reserved Activity Detail remain explicit follow-ups. Production login investigation is paused.

The full self-contained allocation follows. No private Francis-PC status file is required. This guide is committed in the Flutter integration/task branches at docs/flutter-team/LATIF_AGENT.md; use that copy after fetching. Web remains read-only reference on test.

Issued 09 October 2026. Owner: Latif. Scope: **Citizen, Ministry and Admin module adoption**.
Task branch: **`codex/flutter-latif-modules`**. PR base: **`codex/flutter-web-alignment`** in khakho3/civic_voice.

Assigned primary IDs: C01, C02, C03, C04, V01, V02, V03, V04, A01, A02, A03, A04, A05. Future/gated work is separately recorded, never fabricated as complete.

## Non-negotiable instructions for the assisting agent

- Ask the human for **their local web repository path and Flutter repository path**. Use those supplied paths; this packet intentionally has no Francis-PC project paths. They may also supply the accepted asset folder. Do not require the private canonical status file: everything assigned is included below. Read current repository AGENTS/instructions and native handoff before edits, but the human's instructions and this current allocation supersede old backlog ownership/loader/design notes.
- Web repository https://github.com/FranzAfun/civic-voice-web is **read-only reference** on `test`. No source/docs/config edits, dependency upgrades/lockfile changes, commits, pushes or branch creation there. `npm ci`/dev server may generate ignored runtime output only. If tracked files change, stop and report; never blindly discard the human's work.
- Flutter repository https://github.com/khakho3/civic_voice: `main` and `codex/flutter-web-alignment` are read-only base branches for contributors. **Never edit, commit or push from either.** All changes belong on your named task branch below. PR target is `codex/flutter-web-alignment`, never `main`, never web `test`. Francis later promotes the integrated Flutter work to main after review/device acceptance. No contributor merges another person's PR.
- Confirm branch/HEAD/clean state in both repositories before starting. Do not switch with dirty files, reset/clean, force-push or overwrite unrecognized work. Web test now contains the required0977b96 reference; verify ancestry. Your task branch is refreshed from the accepted integration checkpoint; the old main snapshot is historical. Fetch your assigned branch and track it locally; never branch from main as a substitute. Shared/API prerequisites remain in force.
- Inspect current Flutter source then the actual web `test` implementation one screen at a time. Preserve the accepted gold/charcoal design and existing real Flutter auth/API flows; never replace them with web mocks. Runtime web states are previews, not API authority or native auth. Native future API gates must remain explicit.
- Reuse owned shared components. No local forks, all-repo formatting, unrelated refactors, generated platform churn, mass dependency upgrades or undocumented new navigation. Keep loading Ghana-native; busy-action animation is separate. Auth framed Back only; ordinary Back elsewhere. Status badges text-only; brand is not warning semantic.
- Do not touch API repo/cloud/database/Firebase/production settings. Francis handles API and separate development Firebase project first. Separate SQL databases do not isolate Firebase users. Until a safe test configuration is supplied, use isolated automated fixtures or approved local previews, **not mutating production-backed manual tests**. Never commit credentials, local.properties, signing secrets, service accounts or private environment files. Do not commit a different developer's personal machine paths.
- Use Flutter SDK compatible with checked-in pubspec, `flutter pub get`, existing tooling and genuine native semantics/navigation/keyboard/accessibility. Verify packages before adding; web React dependencies are not Flutter dependencies. Native biometrics/location/FCM already work: preserve them.
- Keep replies super simple: what changed, exact native screen/route and state/actions to test, what is blocked. For every UI checkpoint tell the human to test on a physical device in both themes, keyboard/Back, text scaling and relevant permission/error/offline states. Automated passing does not equal device confirmation.
- Run `flutter analyze`, relevant meaningful tests and `git diff --check`; distinguish existing baseline failures from new ones. Build/run on **your task branch** when the safe configuration is available. Never demand a release/signing credential just to test UI. Cover each real state; do not invent every generic preview state on every screen.
- **No commit until the human explicitly confirms tests and asks.** Then small scoped commits per shared foundation or screen. Before first push ask/obtain explicit human authorization; first push must set upstream (`git push --set-upstream origin YOUR_BRANCH`). Later normal push only after authorization. Open a PR to `codex/flutter-web-alignment` when human authorizes publication/PR; never merge or force-push it. Commit permission alone is not permission to deploy.
- On your task branch maintain only `docs/flutter-alignment/YOUR_NAME_PROGRESS.md`: backlog ID, screen/file, preserved contracts, tests/device evidence, accepted/broken/blocked/deferred, proposed shared-file request. Do not edit a global status/handoff owned by someone else. PR body includes completed IDs, changed-file ownership, web reference hash, tests, human device confirmation and API gates. Do not call a deferred item done.

## Setup commands (use your local folders)

Run only from a clean checkout. Web main is fetched for context, **test is the visual reference**:

```powershell
git fetch origin main test
git switch test
git pull --ff-only origin test
git merge-base --is-ancestor 0977b96604a13e365841aba0088f1c01594b74dc HEAD
npm ci
npm run dev -- --host 0.0.0.0
```

If local test does not exist, use `git switch --track origin/test` instead. If the ancestor check fails or origin lacks the reference, stop and ask Francis to publish/confirm it. Use Vite's printed HTTPS URL; phone uses your own LAN IP/printed port and may prompt for local certificate. Install the supported Node LTS; Maps may need a separately supplied restricted **development** key, do not copy production credentials. No API server is needed to inspect this mock web UI. Inspect through module role selector/routes; clear only this local site's stale PWA cache if it shows old assets.

In Flutter, first update the read-only main checkout, then fetch your already-published **task branch**:

```powershell
git fetch origin main
git switch main
git pull --ff-only origin main
git fetch origin codex/flutter-web-alignment
# The assigned guide supplies fetch/track commands for your existing remote task branch.
```

After switching to YOUR_BRANCH: `flutter pub get`, `flutter analyze`, relevant tests, then `flutter run` using Francis's approved isolated configuration. Dependency install is never followed by editing/committing on main/integration. If a command fails or the branch already exists, inspect it; do not reset/recreate blindly.

## Shared ownership and merge order

1. Aziz owns shared presentation primitives, themes, Profile/auth/About/branding and dependency/central-bootstrap edits. Module owners adopt his APIs inside their own files; F01/F02/F03/F04/F05/F06/F07/F09 are global **implementation by Aziz, adoption/testing by all**. Profile is Aziz's across every role; no competing module Profile rewrite.
2. Kingsbeng owns report status/serialization/workflow core and Municipal/Maintenance modules. Pending enum exhaustiveness/DTO compatibility must compile across the whole app before merge. He publishes field changes for Latif/Aziz to consume; other role model files keep their owner.
3. Latif owns Citizen/Ministry/Admin modules and their status/standing integrations. No shared-widget or Profile fork.
4. Shared `lib/main.dart`, global route/session/client plumbing, dependency locks and platform configuration: Aziz is single editor by default. If workflow needs a shared payload/service file, Kingsbeng owns that **narrow declared file/change** by agreement, not two concurrent editors. Document actual ownership before editing; ask Francis to coordinate clashes. NotificationDirectory base lifecycle is Aziz; Kingsbeng supplies Maintenance event-label/route changes, Latif supplies other-module call-site changes through narrow requests or after merge. No blind overwrite/cherry-pick across owners.
5. Work sequentially by complete assignment: Aziz first, then reviewed merge to integration and refreshed Kingsbeng branch, then Kingsbeng, then reviewed merge and refreshed Latif branch, then Latif. Francis/integrator owns start announcements and branch refresh; contributors never rewrite published branches. Small scoped PRs remain allowed within the active assignment.
6. Waiting contributors do not begin implementation, including independent screens, until their turn is announced. The active contributor records blocked API/dependency items honestly; no duplicate shared implementation or fabricated endpoint. Francis/replacement integrator alone merges PRs and promotes main.

## Current design/business decisions

Gold action fills/dark ink + neutral charcoal dark surfaces; semantic colors distinct; shared text-only status badges and chips; quiet dark elevation; compact confirmation actions. One inset/safe area owner. Avatar-mounted edit pencil, grouped Profile rows, preferences with leading icons, Theme selected value hidden and chevron trailing. Compact **left-aligned Admin user details**, not a Profile hero. Native Ghana page loader retained; no page Thinking Orb/skeleton rewrite. Pending approval open/teal/90%; seven statuses and 15/30/50/70/90/100 lifecycle. Report work percentage separate. No auto-approval, Archive or invented role-management editor. Haptics opt-out; motion respects reduced-motion and accessibility. Auth uses circular glass Back; ordinary details/Profiles/authoring use plain Back. Brand/logo assets accepted; don't use older drafts.

## API and unresolved choices (Francis-owned; do not implement guessed contracts)

Audit coverage/outcomes/filter/detail, verification persistence, required rejection category and evidence minimum; proximity/safe nearby detail; durable inbox/read sync and Ministry digest; integrity/AI; public domain/projection/OG; release/update mechanism and map provider/gesture policy remain gated. Existing scoped teams/reports, approval/timestamps/current-lead pushes, trustRating, Admin health/settings and native auth already exist. Integrate approved real contracts; no duplicate server work. If a required backend change is missing, show an honest guarded state and record blocked, not complete. Future AI must remain deterministic fallback until the real contract is delivered.

## Reference paths/screens

Web `src/theme/tokens.css`, `src/components/`, `src/pages/`, `src/layouts/`, `docs/BRAND_ASSETS.md`, `docs/GHANA_DESIGN_REVIEW.md`, `docs/FINAL_APP_SWEEP.md`, `docs/AUTHENTICATION_ALIGNMENT.md`; use current files, not older trial metadata. Assets are in web `src/assets/branding/` and `public/branding/`; prepared icon outputs are in public/icons/ and public/apple-touch-icon.png. Accepted artifact copies may be supplied separately. No SVG conversion service/account is mandatory. Relevant web routes `/welcome`, `/login`, `/register`, `/app`, `/app/reports`, `/app/profile`, and `/app/municipal`, `/app/maintenance`, `/app/ministry`, `/app/admin` families with real child routes discovered in src/App.jsx. Inspect exact route and supported `?state=` queries before listing them to human; do not fabricate routes. Native navigation names are discovered from current Flutter source.


## Your exclusive file scope

Own Citizen/Ministry/Admin module models/directories/scaffolds/screens except all Profile screens/Profile-only data and authentication. Own Citizen trustRating parsing, Home standing placement and draft/authoring/Track adoption; Aziz owns shared TrustStanding widget and Profile placement. Kingsbeng owns shared report status contract; consume it. Do not edit generic lib/widgets/, core theme/assets, dependency files, central bootstrap or other modules without agreed ownership transfer.

## Start and branch

Wait until Aziz and Kingsbeng have completed their assignments and their approved work is merged into integration. Start only after Francis refreshes your task branch and announces readiness. Consume the merged shared presentation and seven-state workflow contracts; never duplicate them.

Run these commands only after Francis confirms your sequential start gate and refreshed task branch are ready. After the clean-checkout setup above:

```powershell
git fetch origin codex/flutter-latif-modules
git switch --track origin/codex/flutter-latif-modules
git branch --show-current
flutter pub get
```

If the local task branch already exists, inspect it and use `git switch codex/flutter-latif-modules` instead; do not recreate/reset it. Verify its upstream is `origin/codex/flutter-latif-modules`, never the integration branch. The task branch already exists remotely; never overwrite other commits. After human device confirmation and commit/push approval:

```powershell
git push --set-upstream origin codex/flutter-latif-modules
```

Open PR in khakho3/civic_voice: **base `codex/flutter-web-alignment`**, compare `codex/flutter-latif-modules`. Progress file exclusively `docs/flutter-alignment/LATIF_PROGRESS.md`. Never create commits while checked out on main or integration.

## Particular boundaries

Citizen My Reports whole-card tap differs intentionally from Municipal View Details. Focus Create->Photos->Review with ordinary Back/no main nav or add FAB, preserve native draft/photos/location/origin; Submitted restores nav. Nearby safe detail/proximity changes are API-gated: preserve existing native features but do not fabricate a live safe endpoint. Track map pan/zoom remains undecided. Ministry stats/Analytics include pending=open, coherent real intervals/rates and percentage points; AI insight future. Admin profile is Aziz's file; do not redesign it again. Admin Users list accepted; create/edit/details calmer, compact left-aligned user identity. Alert events are scoped audit events, not open incidents. Actual API health exists for Super Admin only; preserve scope. Audit detail contract and Ministry digests remain Francis-owned future work.

## Your complete assigned requirements

The blocks below are extracted from the accepted consolidated backlog. `S` means the owner's historical status evidence; **you do not need access to that private file**. The requirements and current corrections are supplied here; current API exceptions/gates above take precedence. File names without a full directory are relative to their named module or shared web component directory.

### C01 — PORT: My Reports card interaction and standing

Whole accessible/tappable history card, quiet trailing 16px chevron, contextual semantics and touch feedback; remove repeated filled View Report CTA and avoid nested interactive targets. Keep reference/title/location/status/progress/truncation/empty/no-results and Track navigation. F03 supplies search; F04 badge; W01 seven-state lifecycle below.

Add shared **TrustStanding** compact Home and detailed Profile variants from the same `trustRating` payload. Home rewards with fractional stars, label and next milestone, taps through to Profile, no limit warnings. Detailed Profile explains what affects standing and restrictions only when lowStanding. Fractional fill must support arbitrary fractions, not fixed half-star cases. Guest gets no stars; never expose citizen standing on Municipal review screens. Parse `/auth/sync`'s `trustRating` instead of relying on obsolete raw `trustScore`; scoring remains server-owned.
Web: `ReportsPage.jsx`, `ReportHistoryCard`, `TrustStanding.jsx`, `DashboardPage.jsx`; S Citizen My Reports/standing rows.

### C02 — PORT with API gate: one Nearby Reports experience

Consolidate native quick-action Nearby Issues sheet and separate `NearbySecondingCard` into accepted shared experience. Discover **other citizens'** open candidates, accurate distance/reference/category/title/context; privacy-safe View details, Not sure, explicit Still there / Confirm it's still there, and **Report a different issue → Create Report** escape path.

Cover permission, loading, empty, offline, stale/closed, duplicate, busy, success/removal, dismissal/seen and progression. Confirmation optional/non-blocking; preserve Nearby preference and no background tracking claim. Native sheet dismissal remains native; explicit web Close is not a compulsory native UI change. **I03 server proximity validation/safe-detail endpoint is prerequisite**, not an afterthought.
Web: Nearby composition in `DashboardPage.jsx`; S Nearby consolidation and Phase 3 integrity requirements.

### C03 — PORT: focused authoring and safe Back

Create Report → Photos → Review becomes a focused flow: **plain Back**, no primary bottom navigation or middle add FAB. Submitted restores normal navigation. Preserve title/description/category, selected photos, exact location/address/community/accuracy, guest context and original Home/My Reports filters through Back and step edits. Native draft cache/persistence stays; web photo round-trip limitation is not desired behavior. Prevent Back bouncing into cancelled/completed steps. Native already uses actual keyboard insets; browser focus-only nav bug is excluded.
Web: `CreateReportPage.jsx`, `PhotoUploadPage.jsx`, `ReviewReportPage.jsx`, `ReportSubmittedPage.jsx`, `src/layouts/AppShell.jsx`; S focused-authoring row and `GHANA_DESIGN_REVIEW.md`.
State: web implementation recorded, its separate physical acceptance still explicitly pending in source records; do not mislabel that as completed native work.

### C04 — VERIFY / PORT: Track map interaction and guest continuity

- Seven-state Track timeline/current progress includes Awaiting Confirmation at 90% with copy: **The team finished the work and submitted it. A municipal officer is confirming it before the report closes.** W01 governs semantics.
- **Unresolved product choice:** native embedded Track map is draggable/zoomable; web preview is inert to avoid trapping page scroll. Decide one intended contract before assigning a native change. Fewer gestures is not automatically an approved native improvement. In-app exact-pin inspection vs external navigation stays distinct (I07).
- Guest account conversion already uses anonymous UID upgrade on native; preserve it. Never port web `guest=true` as authentication or expose guest conversion to staff/registered users. Same UID/user/report ownership, phone conflict/expiry/loss handling, safe origin return and guest biometric restriction need regression coverage during redesign.
Web: `ReportsPage.jsx`, `DashboardPage.jsx`, `ProfilePage.jsx`, `AuthPages.jsx`; S Guest wiring boundary, Track map decision and native CONTEXT_HANDOFF.

### V01 — PORT: Dashboard zero state and coherent open-work summary

Empty keeps **National Dashboard**, four zero-value summaries without delta percentages and inline welcome/Refresh; no fabricated chart/municipality list. Error/offline/unauthorized unavailable bodies recover appropriately. Do not add redundant permission alias or arbitrary disabled state that the screen does not model.
Include pending approval in QuickInsights/data directory and open-work total; coherent seven-status aggregates. Web reference fixture totals24,800: submitted744, underReview3,200, assigned744, inProgress232, pendingApproval1,240, resolved18,600, rejected40. Fixture illustrates coherence; don't substitute it for live metrics. Percentage comparisons need actual period definitions/previous data, not invented deltas.
Web: `MinistryDashboardPage.jsx`, `MinistryData` fixtures; S Dashboard states/approval/coherent-mock rows. Native `ministry_dashboard_data.dart`, `ministry_data_directory.dart`.

### V02 — PORT: Analytics filters, counts and honest comparisons

Date selector can collapse while **dimension pills remain accessible/pinned**, calendar expands selector; native currently hides whole filter area. Keep controls usable without flicker and correct geometry/states via shared foundations.
Both status charts include all seven statuses; slices and resolution KPI use the same count aggregation. Category Distribution stale chart and municipality labels corrected; category/municipality bars are **segment resolution rates**, not ambiguously labelled shares. Mock date presets visibly Sample and change data/dates; live records must use actual selected interval. Rate difference is **percentage points**, with a real previous-period baseline; native live path's zero changes must not become fabricated improvements.
Preserve deterministic selected-period insight until AI; future **AI-driven Ministry insight grounded in real aggregation** is an explicit requirement (I06), not a currently integrated feature.
Web: `MinistryAnalyticsPage.jsx`; native `ministry_analytics_screen.dart`/`ministry_analytics_data.dart`. Source: S three Analytics rows and AI requirement.

### V03 — PORT: Municipal Performance filter access

Region/scope controls remain pinned/accessible while explanatory subtitle collapses. **Dismissing region picker retains selection**, not reset. Metric buttons wrap with ≥44px touch targets, narrow score text readable. Scoped list/no-match and national/context stats remain honest; states/retry cancel safe. Native previews can exercise region/scope/metric without copying URL machinery.
Web: `MinistryMunicipalPerformancePage.jsx`; native equivalent screen/data, `region_picker_chip.dart`. Source: S Municipal Performance row.

### V04 — PORT / VERIFY: Reports, Insights and municipality contacts

- Reports share F03 search/history/chips; static report rows/results remain static, no invented detail actions. Badge/date move below title/icon row on phones so Awaiting Confirmation does not squeeze title. National summaries unaffected by filtering. Neutral leading icon F01/F04; correct canonical glyph/status map.
- Insights aggregates the same report dataset and all seven statuses/open backlog; fix focus text to **peak category label**, not MapEntry string, and explicitly name approval in active workload. No invented historic delta/AI claim. Disabled Focus Summary needs explanation until built. State/filter/retry foundation F06.
- Municipality drill-down preserves region/name/attention/status recap; no-contact empty retains recap, missing record honest. Current native contact/dial/SMS handling already exists: preserve launch-failure feedback and real contact permissions; web tel/sms limits are not a native deficit. Back restores originating Dashboard/filtered list.
- Profiles use P01–P05; notification lifecycle labels use shared status badge and real read/dismiss/return/deep-link contract F07. Do not copy browser session-only persistence.

Web: `MinistryReportsPage.jsx`, `MinistryReportInsightsPage.jsx`, `MinistryMunicipalityDetailPage.jsx`, shared Profile/Notifications; S Ministry close-out and Reports rows. Unbuilt summaries stay disabled; AI timing stays future I06.

### A01 — PORT: calmer Dashboard with truthful metrics

Quiet two-by-two overview, **vertical dividers only**, no horizontal cross, decorative stat icons or unsupported percent deltas. Counts from scoped users/active roles/audit records; Assembly stats never show platform totals. Open Alerts becomes **Alert events** and opens matching ALERT/CRITICAL Activity filter with Clear and scope preserved. Unknown/off-audit counts show unavailable/explanation, not fake zero. API status is **sample until live health is connected**; shared badge/appropriate dot only for meaningful health, no fabricated Online.
Web: `AdminDashboardPage.jsx`, `AdminSystemActivityPage.jsx`, `src/data/adminActivityData.js`; S Ghana overview feedback and Admin API badge rows.

### A02 — PORT / VERIFY: drawer and menus

Native already has left slide drawer: preserve it and animate **both entering and closing**; do not port obsolete centered web overlay. Inactive items neutral; only current destination primary, including Teams route family. Preserve navigation/Back/accessibility. User-card kebab menus must not be clipped by next card/viewport; native Overlay/menu placement equivalent, not a DOM body portal.
Web: `AdminChrome`/drawer, `KebabMenu.jsx`; S active-destination/device corrections. Native `admin_scaffold.dart`.

### A03 — PORT: Create/Edit User modernization and compact detail identity

Text-only Account Details/section headings (remove section icons), Profile-inspired grouped fields, calmer unboxed read-only rows, quiet permission/activity summary, clear Access/action hierarchy. Create underline identity fields; keyboard/autofill/error handling intact. **User Details is compact left-aligned** initials/name/phone/text-role/account badge; preserve actual saved record, don't restore earlier centered Profile-like hero.
Keep complete role/tier/region/assembly roster and guards, administrator-controlled credentials, scoped jurisdiction and dirty/discard/confirm/save/failure states. Changes appear after successful save; use actual API provisioning/SMS (native already live), not sample no-SMS web confirmation. Honor creation freeze/account settings on server as well as client. Protect authenticated current account; user removal must clean membership/lead transactionally (I01/W02).
Web: `AdminCreateUserPage.jsx`, `AdminUserDetailsPage.jsx`, `UserRecordSummary.jsx`, shared Profile primitives; S Create/Edit/header/User-details/Create User rows. Users list appearance otherwise remains accepted; native adopts shared F03/F04/state rules, not unrelated redesign.

### A04 — PORT / VERIFY: Teams selectors, forms and state handling

List: shared focused search may collapse; **region and assembly selectors scroll with body, full width**. Defaults exactly **Select region**, **Select Region first**, then **Select assembly** after valid region. Jurisdiction changes clear stale assembly/lead; detect dirty lead-only edits. Candidate scope and actual team membership/lead remain server-authorized. Adequate mock data for scroll tests is a test fixture, not fake production data.
Team Details proper shared header/inset, unavailable/not-found recovery; create/edit guarded save/cancel and dirty confirmation. Reusable add FAB uses native **GlassFab already present**; no new web portal implementation to port.
Web: `AdminMaintenanceTeamsPage.jsx`, `AdminMaintenanceTeamDetailsPage.jsx`, `AdminMaintenanceTeamFormPage.jsx`; native shared region/assembly picker, team directory/models/screens. Source: S list/details/forms/selectors/floating-add rows.

### A05 — PORT / VERIFY: Activity, Settings, Roles and Notifications

Activity **time range scrolls normally outside collapsible search**, same as Teams selectors; stable chips/search and centered category labels. Current sample API/DB latency/uptime must be labelled sample until live readings; no invented timestamps. Future audit details/filter contract I04 remains separate from current presentation.
Settings **Coming Soon neutral grey**, not warning yellow; this already matches native source baseline, verify don't create a false new debt. Real account creation/audit/idle-timeout settings persist and are enforced by API/session, not web mock toggles. Shared confirmation and disabled-action explanations F05/F06.
Role Management acknowledged incomplete in Flutter: retain honest samples/disabled unavailable features; no permission redesign invented. Admin Notifications real tier-scoped visibility/read/dismiss/deep links F07. Both Profile tiers P01–P05, only Administrator Information/System Preferences headings.
Web: `AdminSystemActivityPage.jsx`, `AdminSystemSettingsPage.jsx`, `AdminRoleManagementPage.jsx`, `AdminNotificationsPage.jsx`, shared admin state/data. Source: S Activity/Settings/Roles/Notifications/device corrections rows.

## Human test handoff before every commit

Citizen Home/My Reports/Track/focused authoring/draft/photo roundtrip/guest conversion/Nearby unavailable states. Ministry Dashboard/Analytics/performance/reports/insights/municipality contacts and filter cancellation; all seven statuses. Both Admin tiers: Dashboard/Users/create/edit/details/Teams list/form/details/Activity/Settings/Roles, drawer open+close, kebab placement, full-width region/assembly defaults, dirty lead changes and creation freeze. Both themes, keyboard/Back, scroll search cycles and large text.

Use a small checklist of exact screens and steps, test credentials/environment approval, actual device/platform, theme, viewport/text scale, failures and pending gates. Screenshot alone is not state/permission validation. Tell the human briefly what to test; wait for confirmation and commit request. Never claim all backlog complete when a future dependency is still blocked. Send PR to Francis only when authorized; do not message another teammate from tools without human authorization.
