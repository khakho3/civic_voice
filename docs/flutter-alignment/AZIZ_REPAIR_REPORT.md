# Aziz submission — repair report

Prepared 12 October 2026 for the integration reviewer, in response to
`AZIZ_REVIEW_2026-10-12.md` (verdict: request changes), and updated the same
day for the owner device-feedback follow-up in that review.

## Where things stand

| | |
| --- | --- |
| Repository | khakho3/civic_voice, local checkout `C:/Projects/mobile/civic_voice` |
| Branch | `codex/flutter-aziz-review-fixes` (local only, no upstream) |
| Base reviewed | `693c59c3b9b3d68e1e5828ee8c9180f76c18dd24` (Aziz) on integration `75e43b3c80f9cacc037c5b4f0bf41d3778520938` |
| Repaired HEAD | latest code commit `75b512a` — 15 small local commits on top of `693c59c` (list below), with the docs commits recording this report on top; working tree clean |
| Commits | made after Francis authorized small commits on 12 October |
| Pushes / PRs / merges | none |
| API repo, database, Firebase cloud, production targets | untouched |
| Web checkout | read only; its uncommitted docs untouched |
| Device installs | none |

## Commits (oldest first)

| Commit | Scope |
| --- | --- |
| `a05d630` | chore: carried analyzer excludes and SDK lock bumps |
| `c4444f1` | test(about): accepted assemblies punctuation (F10) |
| `c96fbec` | feat(theme): readable ink roles and bundled Inter (F01) |
| `e188a88` | feat(widgets): shared confirm, busy, motion, haptics (F05/F06/F09) |
| `b3bf55f` | fix(ui): accessible foregrounds across every role (F01/F02) |
| `93fe529` | feat(profile): shared grouped Profile and name sheet (P01–P04) |
| `830eb4b` | feat(auth): shared glass Back, labels, busy actions (U01) |
| `e9cf97f` | feat(search): focused search, history, text chips (F03) |
| `455485e` | feat(share): allowlisted public case share helper (F08) |
| `7062440` | feat(brand): notification mark and iOS launch assets (F07/U02) |
| `43789b5` | docs: progress and report |
| `4232607` | follow-up: Theme row icon follows the chosen theme |
| `eb21e62` | follow-up: haptics guidance behind an info button |
| `4883aa6` | follow-up: gentler onboarding motion |
| `75b512a` | follow-up: launcher double padding removed; themed icon shows the Arch |

Every commit was checked out in a disposable detached worktree and
analyzes clean on its own (first 12 checked; the follow-ups are verified
by the full run at HEAD).

## Owner device feedback follow-up

| Item | Resolution |
| --- | --- |
| Launcher logo small | Cause: double padding. The adaptive foreground already has safe-zone padding (content at 0.261 of the 108dp canvas, inside the 0.306 safe circle) and `ic_launcher.xml` added a further 16% inset (~0.18 effective). Inset is now 0%, and `pubspec.yaml` sets `adaptive_icon_foreground_inset: 0` so regenerating doesn't re-pad. The themed monochrome layer was a plain bubble; it is now derived from the approved foreground with the Arch cut out. Circle/squircle/themed masks simulated. Header logos untouched. iOS already uses the web Apple-icon proportion (mark ≈78% of the tile), which the Android mark now matches inside its mask; no iOS change, no iOS device validation claimed. |
| Theme row icon | Leading icon = chosen option (System/sun/moon); System keeps its icon while the OS appearance flips; value hidden in the row, announced in semantics; all five Profiles tested. |
| Onboarding motion | Onboarding-only (no global change): ease in/out over the emphasized duration (Skip across two slides uses the page duration), slight fade off-centre, fixed Previous slot so artwork doesn't jump, crossfades for Next/Get Started, final actions and dots. Rapid taps step from the pending target and never overshoot. Found and fixed: reduced motion passed a zero duration to `animateToPage`, which trips Flutter's scroll assertion — it now jumps. Swipe, Skip, final actions and the Previous rule kept; `PageController` disposed. |
| Haptics info | Permanent caption removed; guidance ("Gentle vibration for supported actions. Your phone must support haptics, and device settings may silence it.") opens from an info button beside the label — the shared `ProfileInfoButton`, now a 48px target that never toggles the switch. |
| Unavailable haptics | No capability probe (Flutter offers none, and a missing pulse proves nothing). `AppHaptics` stays fire-and-forget. New tests: opt-out, persisted across restart, throttling, and a throwing vibrator not blocking a confirmed action. |

Device confirmations reported by Francis (dev app): avatar pencil/edit,
auth Back, confirmation dialogs, Citizen dark-mode plus, and action haptics
after clearing dev app data. Targeted confirmations only.

## Results

| Check | Base (Aziz `693c59c`) | Repaired working tree |
| --- | --- | --- |
| `flutter analyze` | clean | **clean** |
| `flutter test --dart-define=API_BASE_URL=http://127.0.0.1:1` | 602 passed, 9 failed | **670 passed, 0 failed** (at `75b512a`) |
| `git diff --check` | clean | **clean** |

No behaviour test was deleted to get green. Tests whose *selectors* targeted
the superseded inline editor/kebab or old copy were updated to the accepted
pencil-and-sheet flow with the same edit / validation / save / cancel
assertions, plus new failure-path coverage. One presentation test was
replaced on purpose: "recovery glass back button visibly disables without
onBack" asserted a visible disabled Back; U01 requires no Back control where
a screen has none (forced first-login), so it now asserts exactly that, and a
new test asserts the shared 48px glass Back on the standard screens.

New test files: `theme_contrast_test.dart` (11 checks of rendered colour
pairs × both themes), `focused_search_test.dart` (7), `public_case_share_test.dart` (5),
`notification_list_view_test.dart` (1), `onboarding_motion_test.dart` (5);
follow-up cases for the Theme row icon (all five Profiles) and haptics
(info dialog, opt-out, restart, throttling, platform failure); new Profile
cases for save failure,
system Back, guest, Maintenance lead / non-lead / unassigned.

## Review findings — resolution

| Priority | Finding | Resolution |
| --- | --- | --- |
| P1 | Gold palette leaves essential controls unreadable (white plus on gold 1.47:1; gold nav label on light) | Fixed at the source: theme-aware ink roles ported from web `tokens.css` and a `foregroundFor`/`onFillFor` mapper on `AppSemanticColors`. Citizen Create FAB = gold + dark ink (11.47:1); selected nav = action ink (6.91:1). Every gold foreground across all roles, auth and onboarding reviewed (~250 call sites); selected chips now gold + dark ink; white spinners inside disabled buttons removed; component defaults (spinners, cursor, focused labels, radio, checkbox, list selection) moved off gold. Raw semantic hues used as text now use their readable text ink. Contrast tests cover the actual pairs. |
| P1 | Destructive confirmation inherits dark ink on red (3.50:1) | `showConfirmDialog` destructive confirm now sets white ink explicitly (4.83:1); three Maintenance red buttons and `AppStateMessage` error actions fixed the same way. Covered in both themes by `theme_contrast_test.dart` (rendered dialog). |
| P1 | Light snackbar action `#765400` on `#172019` (2.42:1) | Light snackbar uses the inverse surface/ink tokens with the bright gold action (12.08:1); tooltip moved to the same tokens. Tested. |
| P1 | Full suite fails (602/9) | Fixed: About punctuation expectation updated; Ministry and Municipal Profile tests rewritten for the accepted pencil + sheet (and the "English" language-value assertion now expects no value). Full suite 654/0. |

## The 17 assigned IDs

Full per-ID detail (what exists, what is open) is in `AZIZ_PROGRESS.md`.

| ID | Status |
| --- | --- |
| F01 | Partial — palette/foreground audit, contrast tests, bundled offline Inter done; ~15 module icons with raw amber/blue tint and light-mode chart bars remain; device review pending |
| F02 | Partial — 32px marks, neutral wordmark, Profile 16px end gap; Maintenance notification-only header verified; per-screen inset measurement on device pending |
| F03 | Adoption — shared focused search, history, trigger, text chips, collapsed rail delivered and tested; 10 module screens adopt in Kingsbeng/Latif turns |
| F04 | Partial — shared badge text-only with readable ink; local forks and card affordances are module adoption |
| F05 | Partial — compact confirmations, exit input blocking (existing-correct), shake, success check, reactive unread badge, reduced motion; custom dropdown morph and opt-in lab components not built |
| F06 | Partial — native busy orb + label, adopted in Profile sheet, App Lock, auth; module busy buttons are adoption |
| F07 | Partial — shared list verified for all roles, Clear all confirms, small icon refined + theme tint; durable inbox **Blocked** (I05); status-bar check pending |
| F08 | Blocked / Adoption — allowlisted share helper with outcomes delivered; domain/projection/OG **Blocked** (I08); Municipal adoption Kingsbeng |
| F09 | Partial — `AppHaptics` in shared actions; module adoption and hardware feel pending |
| F10 | Done |
| P01 | Done (device pending) |
| P02 | Done (device pending) |
| P03 | Done (device pending) |
| P04 | Partial — Admin headings fixed, guest/lead/role content done; Citizen standing **Blocked** on `trustRating` parsing (Latif C01); Municipal permissions field does not exist |
| P05 | Partial — automated state/variant coverage done; origin returns and real-data states need device |
| U01 | Partial — shared glass Back, no Back on first-login, 12px/14px medium labels, focus ink, busy labels; device keyboard/autofill pending |
| U02 | Partial — iOS icon/launch assets regenerated from the approved master; physical mask/splash checks pending (no iOS device here) |

## Changed files

136 tracked files modified, 1 deleted, 19 new files (counts from
`git status` / `git ls-files --others`). By area:

- **Theme/tokens (Aziz-owned):** `lib/core/theme/app_colors.dart`,
  `app_light_theme.dart`, `app_dark_theme.dart`, `app_typography.dart`,
  `app_icons.dart`, `app_motion.dart`, `lib/core/constants/app_assets.dart`.
- **Shared widgets/services (Aziz-owned):** new `busy_indicator.dart`,
  `focused_search.dart`, `motion_feedback.dart`,
  `profile_preference_row.dart`, `profile_status_banner.dart`,
  `text_filter_chips.dart`, `trust_standing.dart`,
  `services/app_haptics.dart`, `services/public_case_share.dart`; rebuilt
  Profile widgets (`profile_section`, `profile_field_row`,
  `profile_action_row`, `profile_session_section`, `profile_header_card`,
  `profile_edit_button`, `profile_name_edit_sheet`, all preference rows);
  `confirm_dialog`, `collapsible_list_header`, `notification_list_view`,
  `unread_dot_badge`, `status_badge`, `stat_tile`, `app_state_message`,
  `app_dropdown_field`, `glass_fab`, `in_app_notification_banner`,
  `settings_section`, `simple_bar_chart`, `profile_info_button`,
  `pending_coverage_notice`; `services/app_cache_service.dart` (search
  history). Deleted unused `profile_edit_action_bar.dart`.
- **Profiles and auth (Aziz-owned):** all five Profile screens, Nearby row,
  `auth_presentation.dart`, login, registration, forgot password, OTP,
  change password, set-new-password form, bio lock, test role selector.
- **Module screens touched for colour only (owners please review):**
  Admin, Citizen, Maintenance, Ministry and Municipal screens and scaffolds
  listed in `git status` — token swaps (gold foreground → action ink, chip
  label ink, destructive ink, spinner ink), 32px header marks, neutral
  wordmark, and the Ministry Reports neutral leading icon. No workflow,
  model, route or data change in any module file.
- **Bootstrap:** `lib/main.dart` (registers the Inter licence; colour tokens
  for two banner/icon sites).
- **Dependencies:** `pubspec.yaml` (Inter `fonts:` + licence asset; removed
  `google_fonts`), `pubspec.lock` (see below), `assets/fonts/` (four Inter
  TTFs + `Inter-OFL.txt`).
- **Native resources:** `android/.../drawable/ic_stat_civic_voice.xml`,
  `values/colors.xml`, `values-night/colors.xml`; 29 iOS
  `Assets.xcassets` PNGs (same names/sizes, `Contents.json` unchanged).
- **Tests:** 7 updated, 4 new (above).
- **Docs:** `docs/flutter-alignment/AZIZ_PROGRESS.md`, this report.

Formatting: only lines I changed were formatted. Files that were not
formatter-clean at the base keep their original formatting outside my edits.
Working-copy line endings follow the repo's `autocrlf` (CRLF).

## Carried tooling files

| File | Disposition |
| --- | --- |
| `analysis_options.yaml` | Kept byte-for-byte (matches the backup). Flutter-generated analyzer exclusions for build/platform folders; analyzer is clean with it. Recommend its own small tooling commit. |
| `pubspec.lock` | Kept the four SDK-resolved bumps (matcher 0.12.20, meta 1.19.0, test_api 0.7.12, vector_math 2.4.3) — `flutter pub get` under Flutter 3.47.7 reproduces them and makes no other change. **Plus** one deliberate change from this repair: `google_fonts` removed (F01 offline fonts). No other package moved. Recommend: tooling commit for `analysis_options.yaml` + the four bumps; the `google_fonts` removal travels with the F01 font commit. |

Backups of both original files remain at
`C:/Users/Suku/Documents/Civic Voice/Flutter backlog/local-change-backup-2026-10-12/`.

## Remaining risks and gates

- Device testing so far is limited to the targeted confirmations above;
  everything else is automated only.
- Commits are local; first push, when authorized, must be
  `git push --set-upstream origin codex/flutter-aziz-review-fixes`, and any
  PR targets `codex/flutter-web-alignment`, never main.
- Do not install this tracked branch on a phone with its production Firebase
  settings; device testing needs the disposable development snapshot.
- Blocked on others: Citizen `trustRating` parsing (Latif), Municipal share
  adoption and pending-approval status (Kingsbeng), public domain/projection
  (I08), durable notification inbox (I05).
- Module adoption is still owed for F03, F04 forks, F06 busy buttons, F09
  haptics and ~15 raw-hue icons; these belong to Kingsbeng/Latif turns.
- Light-mode gold chart bars (`SimpleBarChart`) are below 3:1 as graphics —
  needs an owner design decision.
- Drag-dismissing the Profile sheet mid-save closes it while the save
  finishes in the background (Back and the barrier are blocked).
- New Android small icon, launcher sizing/themed icon and iOS assets are
  generated, not yet seen on a real status bar, launcher mask or iPhone.

## Device checklist (for Francis, on the development snapshot)

Test each in **Light and Dark**, with **large text**, and use **system
Back**.

1. **All five Profiles + Guest + Admin Super + Admin Assembly:** grouped
   rows with tight gaps; pencil on the avatar; tap it — sheet opens with
   no keyboard; clear the name → red error + shake; Cancel; save a new name
   → banner; turn on airplane mode, save → "Changes not saved", sheet stays.
2. **Admin Profile:** only "Administrator Information" and "System
   Preferences" have headings; edit, change name, Cancel → "Discard
   changes?". Super: bottom nav stays. Assembly: Back, no bottom nav.
3. **Maintenance Profile** as a team lead, a team member and an unassigned
   technician: "Team Lead" only for the lead; "Not assigned to a team".
4. **Guest Profile:** "Guest", no phone, no pencil, Create Account card,
   App Lock off and "Unavailable for guests"; log out copy mentions guest.
5. **Preferences:** Theme menu System/Light/Dark (switch phone theme while
   on System); Haptic feedback on/off (off must not buzz); App Lock with real
   biometrics; Nearby info dialog.
6. **Citizen nav:** Create (+) button dark plus on gold; selected tab text
   readable.
7. **Log out everywhere** and **Notifications → Clear all:** red confirm
   button with white text; Cancel keeps everything.
8. **A snackbar with an action** (e.g. after a notification delete in light
   theme): action text readable.
9. **Auth:** Login/Register, Forgot Password, OTP, Change Password —
   round glass Back on each; forced first-login password screen has **no**
   Back; field labels small; Sign In shows the small orb while busy.
10. **Onboarding:** Report (no Previous) → Next → Track (Previous) →
    Next → Resolve; feel should be smooth, artwork must not jump when
    Previous appears; tap Next quickly three times (lands on Resolve, no
    overshoot); Previous from Track; Skip from Report; swipe both ways.
    Then turn on the phone's **Remove animations** and repeat: slides
    change instantly, nothing breaks.
11. **Launcher and launch:** fresh install of the dev app — mark visibly
    larger in its tile with the full tail; check round and squircle shapes
    and Themed icons on; cold start splash; one push notification — small
    status-bar icon.
12. **Theme row icon:** in each Profile pick System, Light, Dark — the
    row's icon changes (System icon stays while the phone theme flips).
13. **Haptics info:** the row has no grey caption; the small info button
    opens the help dialog and does not flip the switch.
14. **Fonts offline:** fresh install with network off — text still renders
    in Inter.
15. **iPhone (if available):** home-screen icon and launch screen.

Report back what fails, with screen and theme.
