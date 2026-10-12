# Aziz assignment — progress

Branch: `codex/flutter-aziz-review-fixes` (local repair of Aziz's submission
`693c59c`, base `75e43b3`). Repair pass and owner device-feedback follow-up:
12 October 2026. Small local commits made after Francis authorized them; no
push, PR or merge. No API, database, Firebase or production changes.

Status words: **Done** (implemented and covered by automated tests; device
check still pending), **Existing-correct** (verified, no change needed),
**Partial** (shared part done; listed remainder open), **Blocked** (waits on
an API/domain/owner dependency), **Adoption** (shared API delivered; the
module owner adopts it in their own screens during their turn).

Automated evidence for every row: `flutter analyze` clean, full
`flutter test --dart-define=API_BASE_URL=http://127.0.0.1:1` passing, and
`git diff --check` clean (see `AZIZ_REPAIR_REPORT.md` for counts).

Device evidence (Francis, development app, 12 October): avatar pencil/edit,
auth Back, confirmation dialogs and the Citizen dark-mode plus confirmed
working; action haptics confirmed after clearing dev app data. These are
targeted confirmations, not acceptance of every role/state. Everything else
still awaits the device checklist in the report.

## Owner device feedback — follow-up (12 October)

| Item | Resolution | Commit |
| --- | --- | --- |
| Launcher logo small | Cause was double padding: the adaptive foreground already carries safe-zone padding (0.261 of canvas, safe circle 0.306) and `ic_launcher.xml` added a further 16% inset. Inset now 0% and `adaptive_icon_foreground_inset: 0` in pubspec so regeneration keeps it. Themed monochrome layer rebuilt from the approved foreground (Arch cut out, star kept) — it was a plain bubble. Module-header logos untouched; iOS icon already uses the web Apple-icon proportion (mark ≈78% of the tile), so no iOS change. | `75b512a` |
| Theme row icon | Leading icon follows the chosen option (System / sun / moon); System keeps its icon while the OS flips; value stays hidden and announced. Tested on all five Profiles. | `4232607` |
| Onboarding feel | Onboarding-only motion: ease in/out over the emphasized duration (Skip over two slides uses the page duration), slides fade slightly off-centre, fixed Previous slot (artwork no longer jumps), crossfading Next/Get Started, final actions and dots. Rapid taps step from the pending target and never overshoot. Reduced motion now jumps instead of passing a zero duration to `animateToPage` (which tripped Flutter's scroll assertion). | `4883aa6` |
| Haptics info | Permanent caption removed; device guidance in a dialog from an info button beside the label (shared `ProfileInfoButton`, now a 48px target, never toggles the switch). | `eb21e62` |
| Unavailable haptics | No capability probe (Flutter has none; not inferred from a missing pulse). Tests: opt-out, persisted across restart, throttling, and a throwing vibrator not blocking a confirmed action. | `eb21e62` |

## Shared foundations

| ID | Status | What exists now | Still open |
| --- | --- | --- | --- |
| F01 | Partial | Theme-aware ink roles ported from web `tokens.css` (`actionFill`/`onAction`/`actionText`, focus, control border, `onError`, error/success/warning/info and all seven status text inks, inverse surface) on `AppSemanticColors`, with `foregroundFor(hue)` and `onFillFor(fill)`. Component defaults no longer draw gold as foreground (spinners, cursor, focused labels, radios, checkboxes, list selection, nav). Every `AppColors.primary` / `colorScheme.primary` foreground across all roles, auth and onboarding reviewed (≈250 sites): gold stays only as fill/tint/progress value; text/icons use the readable ink; selected chips use gold + dark ink. Raw semantic hues used as *text* (≈25 sites) use their text ink; destructive fills use white ink. Ministry report leading icons neutral. Dark error text readable. **Inter 400/500/600/700 bundled as assets** (Google Fonts static files, SHA-256 verified), `google_fonts` removed, OFL licence registered. No near-white shadow source exists (all shadows charcoal/black) — existing-correct. `test/theme_contrast_test.dart` checks the rendered pairs in both themes. | Device visual review both themes. ~15 module icons still tinted with raw amber/blue hue (non-text, 2.2:1) — module owners. `SimpleBarChart` light-mode gold bars are below 3:1 as graphics — owner decision. Offline cold-start font check on a device. |
| F02 | Partial | 32px brand mark on every brand-bearing header (Citizen, Municipal, Ministry, Admin incl. drawer, Maintenance); neutral wordmark (logo carries colour). Maintenance header verified notification-only in source (no Profile action) — existing-correct. All five Profiles end with one 16px gap above nav/safe area. Header height token is 64px (matches web). | Inset audit of every module screen at device widths (double padding) — measure on device; module scaffolds belong to their owners. Municipal keeps its own `MunicipalDetailHeader` fork of `DetailHeader`. |
| F03 | Adoption | Shared focused search `showFocusedSearch` (visible Close, Back/fog close, background blocked, results, per-screen account-scoped history with removal and confirm-before-clear, recorded on submit/activation only), non-editable `SearchTriggerField` (Close/Back never refocus an editable field), text-only `TextFilterChips` (40px stadium, 14px/500, no icons, hidden scrollbar, 48px targets), and opt-in collapsed-rail mode on `CollapsibleListHeader` (full header only at true top; upward scrolling does not re-expand). List position preserved across repeated cycles (tested). | Adoption on Citizen My Reports, Municipal Inbox/Active/Closed/Assign Team, Maintenance Assigned Tasks, Ministry Reports, Admin Users/Activity/Teams (Kingsbeng/Latif). Without `collapsedHeader` those screens keep today's behaviour. |
| F04 | Partial | Shared `ReportStatusBadge` is text-only with readable status ink and a "Status: …" label; `TintedBadge` maps any brand/semantic/status hue to its readable ink (fixes callers passing raw hues, incl. Maintenance task badges). | Local badge forks (e.g. Ministry Reports `_StatusBadge`, Municipal `_ClosedBadge`/`_NewBadge`) and the Municipal View Details+chevron / Citizen whole-card affordances (C01/M02) — module owners. Pending-approval status (W01) is Kingsbeng's model change. |
| F05 | Partial | `showConfirmDialog`: compact intrinsic-width trailing actions that stack when narrow, 48px height, destructive = error fill + white ink, neutral Cancel in dark, optional icon, no per-role colour. Exit input blocking verified in the SDK (`ModalRoute` ignores pointer/focus while reversing) — existing-correct. New shared motion: `ErrorShake` (one-shot), `SuccessCheck`, reactive red unread badge entrance; all honour reduced motion (`AppMotion.reduceMotion`). Notifications "Clear all" now confirms. | Native dropdown reveal/morph left as Material's own `MenuAnchor` animation (not a custom morph). Focus beam / Accordion / TogglePanel are opt-in lab components with no current screen need — not built. |
| F06 | Partial | Native `BusyIndicator` (≈20px searching orb, host ink from the button, static frame under reduced motion, stops ticking when hidden/disposed, announced once) and `BusyLabel` (keeps label footprint). Adopted in the Profile name sheet, App Lock verification and all auth submit buttons. Ghana page loaders untouched. Mounted guards present on every async path in the touched flows. | Module busy buttons still using raw spinners: Admin Create User/Teams/Settings/User Details, Citizen Create Report/Location Picker/Nearby card, Maintenance Assigned Tasks/Dashboard/Task Details, Municipal Dashboard — owners. Module-wide cancellation audit is per-owner. |
| F07 | Partial | One shared `NotificationListView` used by all five roles (verified); swipe-delete separate from tap/navigation; read on open; Clear all confirms; reactive unread dot. Android small icon refined from the accepted identity (filled bubble, arch and star cutouts, alpha-only) with theme-aware accent (`#765400` light shade, `#FFD84D` dark). | Status-bar rendering on device. Durable inbox/read sync and Ministry digest are backend-gated (I05) — **Blocked**. Per-role deep links unchanged (owners). |
| F08 | Blocked / Adoption | `PublicCaseShare`: allowlist-only `PublicCaseSummary`, status-aware recipient copy matching web, canonical `/case/<reference>` URL only when `--dart-define=PUBLIC_SITE_URL` is set (no hardcoded domain), real outcomes (shared / dismissed / unknown / copied / failed) with quiet dismissal and recovery copy. | Municipal Progress/Resolution adoption (Kingsbeng). Production domain, public projection and OG image service (I08) — **Blocked**. |
| F09 | Partial | `AppHaptics.activate()` (opt-out aware, throttled, never fails the action). Wired into shared actions: confirm, Citizen nav/Create FAB, Profile action/preference rows and theme menu, filter chips, focused-search results. Device guidance sits behind an info button (no permanent caption); turning haptics off never buzzes. Owner confirmed action haptics on the dev app. | Module action adoption (owners). |
| F10 | Done | "District, Municipal, and Metropolitan Assemblies"; test expectation updated. | — |

## Profile

| ID | Status | What exists now | Still open |
| --- | --- | --- | --- |
| P01 | Done | One grouped-list system (`ProfileSection`/`ProfileGroupTile`): plain inset labels, 2px row gaps, first/middle/last corners, 64px rows, avatar-mounted pencil (24px disc, 48px target), neutral pills, standalone destructive "Log out" row with no chevron, one 16px end gap. Adopted by Citizen, Guest, Municipal, Ministry, Maintenance and both Admin tiers. `ProfileEditActionBar` removed (no users left). | Device: large text, TalkBack/VoiceOver, both themes. |
| P02 | Done | Shared name-only `showProfileNameEditSheet` on all five roles: no autofocus, keyboard inset/scroll, explicit Save/Cancel, red validation with first-error focus and one shake, busy Save, Back/barrier blocked while saving, failed save keeps the sheet open with the entered name, Admin confirms before discarding, saved record shown afterwards. Phone, department, IDs, jurisdiction never editable. | Drag-to-dismiss during an in-flight save closes the sheet (the save still completes and updates the screen). Device keyboard/Back review. |
| P03 | Done | Shared `ProfilePreferenceRow`/`ProfileSwitchRow`: Theme menu (leading icon showing the chosen theme, far-right chevron, check in menu, value in semantics), Haptic feedback with info dialog, Language with far-right Coming Soon, App Lock (checking / on / off / not set up / unavailable, real biometric gate, **Unavailable for guests**), Citizen Nearby Reports with info dialog. | Device: system theme live follow, biometrics, large text. |
| P04 | Partial | Admin: only "Administrator Information" and "System Preferences" titled; About/Change Password untitled; scope behind info button; tier behaviour kept. Guest: Guest identity, no phone/edit/standing, carry-over callout, guest logout copy. Maintenance: Team Lead pill only for the current lead (live team record first), honest "Not assigned to a team". Municipal: Officer ID, Assembly, Region. Ministry: phone, supervisor ID, access info. Shared `TrustStanding` (compact + detailed, arbitrary fractional stars) built and placed on Citizen Profile. | Citizen standing shows nothing until the Citizen model parses `/auth/sync` `trustRating` (Latif, C01) — **Blocked**. Municipal "current permissions" has no field in the officer model — not invented. |
| P05 | Partial | Automated coverage: edit/validation/save success/save failure/cancel/system Back for Citizen, Municipal, Ministry, Admin, Maintenance; guest variant; lead / non-lead / unassigned; Admin Super/Assembly tiers; About and Change Password callbacks. | Device verification of origin returns (Notifications/About/Change Password), scroll reset on entry, offline/unauthorized on real data. |

## Auth and brand

| ID | Status | What exists now | Still open |
| --- | --- | --- | --- |
| U01 | Partial | One shared 48px circular glass `AuthBackButton` on every auth screen (hero variant keeps the accepted look over the illustration); no Back control at all where none applies (forced first-login). Login/Register labels 12px medium, other auth labels 14px medium; focus underline uses the focus ink; submit buttons use `BusyLabel`. Real auth, OTP, recovery, guest upgrade and biometrics untouched. | Device: password visibility caret, autofill, OTP paste, keyboard, offline/blocked states. |
| U02 | Partial | Aziz's Android launcher/Android 12 splash and gold onboarding (Report no Previous, Track Previous, Resolve final actions) kept; launcher double padding removed and themed icon rebuilt with the Arch (follow-up); onboarding motion refined (follow-up). **iOS** app icon set regenerated from the approved master (charcoal, web Apple-icon composition, opaque) and iOS launch images/backgrounds replaced (approved mark; `#FAFAF7`/`#101110`); filenames, sizes and `Contents.json` unchanged. | Physical checks: launcher size and masks, themed icon, Android 12+ cold start, onboarding feel, iOS home screen/launch (no iOS device test available here). |

## Cross-contract reference

C01 TrustStanding: shared widget and Profile placement delivered (above);
Home placement and `trustRating` parsing stay with Latif.

## Integrator follow-up - 12 October 2026 (owner retest pending)

Owner reports low-contrast Citizen hero Report Now, inconsistent bottom-nav haptics, Admin alert accent unchanged by theme, and onboarding still abrupt. Integrator changes on codex/flutter-aziz-review-fixes are currently uncommitted:
- Citizen hero button uses gold foreground on its fixed charcoal/onPrimary fill rather than the light theme's brown actionText. Hero gold fill and content remain unchanged.
- Admin/Ministry/Municipal/Maintenance bottom-nav callbacks now invoke shared AppHaptics; Citizen already did. Missing adoption explains these silent controls; no evidence justifies requiring cache/data clearing. Existing preference, throttle and unsupported-platform handling retained. Four new tests verify immediate off/on behaviour and navigation without clearing data.
- Admin Open Alerts icon and Review text use theme-aware warningText (dark orange ink on light; light amber on dark).
- Onboarding uses a 500ms easeOutCubic slide, preloads all illustrations once and isolates slide repainting. Reduced-motion jumps, rapid taps, layout and final actions preserved. Device preview uses a profile/performance APK so debug overhead does not distort motion judgement.

Independent checks this pass: Flutter analyze clean; 674 complete-suite tests pass; native whitespace check clean. Prior report's 670 count describes the previous committed repair, not these new changes. Physical acceptance of this follow-up remains pending. No commit/push/merge/main promotion; Kingsbeng still waits until approved foundation review/integration and branch refresh.

## Owner acceptance and integration preparation - 12 October 2026

Francis confirms all four integrator follow-ups on the physical DEV app: Report Now contrast, navigation haptics without data reset, onboarding motion and alert theme styling. Amber Review/Open Alerts is intentionally a warning semantic distinct from brand-gold metrics, explained and accepted. This supersedes the pending-device status above. Owner authorizes small commits and promotion to codex/flutter-web-alignment, then refreshing Kingsbeng's task branch. Fresh fetch shows integration, Kingsbeng and main still at75e43b3; Kingsbeng has no extra commits or open PR to preserve. Full674tests/analyzer/whitespace and inspected profile APK evidence from this follow-up pass retained. Main and production/native Firebase configs remain protected; all DEV overrides are outside Git. Remaining partial/backlog/API gates in this report stay open for their assigned owners. Latif waits until Kingsbeng is reviewed and integrated.
