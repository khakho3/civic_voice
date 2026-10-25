# Card and shared-sheet inventory - 25 October 2026

## Owner-reported Citizen Reports history cards - 25 October 2026

Native af4992c matches the web history-card override in ReportsPage.css: opaque
primary surface and the normal border, with the existing 20px corners, padding,
content/status/progress and whole-card tracking action. The old history fill was
already opaque but used the tinted secondary surface and faded glass border;
that did not match web. The local Ink decoration keeps the accepted Material tap
and focus feedback. This does not change the shared CivicGlassCard, totals,
empty/no-match cards, filters or collapsing search. Their web reference still
uses the shared/default treatment. No global quiet-card completion is implied.

Two rendered-pixel regressions failed on the old history fill and now match the
exact primary/border pixels in both themes. All 1,531 native tests and analyzer
pass; 110 focused Citizen and all-consumer search checks pass. Actual-font
320/412 light/dark renders at 1x/1.4x cover all seven status fixtures, long copy,
list top/bottom, no-match and empty states: 32 final captures. The 412px/1x
header-and-totals pixels are identical before/after in both themes. These are
automated/fixture checks; current DEV install/owner acceptance are in the handoff.

**New open issue, separate from this style repair:** at 412px and 1.5x actual
bundled fonts, Citizen bottom-navigation item Columns overflow by 1px at
lib/features/citizen/widgets/civic_app_chrome.dart:321 in both themes. This was
reproduced before the card edit; the fixed 56px item height cannot fit the
scaled label. The initial visual matrix passed 6/8, with those two cases blocked
by the existing nav issue. Final 1x/1.4x renders pass 8/8; do not call the 1.5x
full-screen case fixed. Log retained in the owner follow-ups/private checklist.

Owner's Citizen Reports report was handled ahead of the queued Alert review
slice. Return to Open Alerts review/detail next; retain the separate Citizen
navigation issue and every remaining mapped screen/state and C01/P04 feature.

## Open Alerts list slice - 25 October 2026

Native af5754b checks the first mapped list only. Existing alert cards already
use an opaque surface with zero elevation and keep their accepted appearance.
The empty result now uses that same card, matching the web grouping. A fixed
24px result-summary slot clipped larger text; it now measures the actual width,
font/text scale, direction and locale, reserving both count and updating labels
so a same-owner preview does not shift during filtering. Normal short summaries
at 1x retain 24px. Alert review/detail, search, filters, data/ownership guards,
continuation, loading/refresh and error wording were not redesigned.

All 1,529 native tests and analyzer pass. Twenty-four new width/theme/text-scale
cases cover 320/390/412/1440, light/dark, 1x/1.5x/2x; initial loading, long title
and count, quiet filtering, grouped empty results, failure/refresh and recovery.
Thirty-five focused alert layout/filter/navigation checks pass. Separate actual
font renders cover eight 320/412 light/dark 1.5x/2x combinations and five states,
top/bottom: 80 before and 80 after captures. The baseline 320px/1.5x count needed
72px but received 24px; after renders show it fully. These are fixture checks;
owner phone acceptance remains pending.

Next one-screen slice: Open Alerts review/detail, including note/history,
loading/failure and narrow/large-text/keyboard states. The remainder of this map,
all-role card sweep and C01/P04 standing integration remain open. Current DEV
artifact/install status is recorded in CURRENT_STATUS.md and the private checklist.

## Current auth/sheet visual follow-up and open feature debt - 25 October 2026

Native runtime **b7f58eb** includes three scoped repairs: **4b68b56** groups Forgot Password's code screen using the existing recovery card; **4b2dcc8** measures the Municipal detail header's two text lines at the actual text scale and gives all six consumers the same body inset; **b7f58eb** retains shared typography on onboarding's Guest action. The normal-scale header height, Back/menu behavior, default registration-code layout, OTP timing/verification/resend, Guest final-page gating, accepted hero layouts, and shared search/filter behavior remain. Correction to the previous note: only Forgot Password's phone step and Change Password's OTP step were grouped at the preceding checkpoint; Forgot Password's own OTP step was still using the default layout and is fixed now.

**1,499 native tests and analyzer pass.** New regression checks cover8 Forgot OTP keyboard/large-text cases,24 Municipal header cases with all six titles/reference contexts at1x/1.5x/2x text and four widths/both themes, and4 Guest typography/gating cases. Actual auth renders cover11 compositions/states (Login ready/service error, Register ready/phone-used, three onboarding pages, unavailable biometric fallback, forgot/registration OTP and test selector) at320/412, both themes,1x/1.5x:88 combinations/176 top-bottom captures. Representative before/after/extreme renders inspected. Biometric fallback uses a test-host plugin absence, not a device hardware test.

The remaining8 sheet surfaces were rendered at320/412 with1.5x text on a700px screen and24px safe areas, including long Nearby/duplicate lists, region top/bottom/selection, Ministry date/category/status, Municipal sort and Send Back with simulated300px keyboard/cancel.48 private captures;45 combined consumer/shared-sheet/Nearby/duplicate checks pass. Together with the prior photo/Profile slice, all10 launch surfaces have representative fixture checks. This does not complete every entry path/state or physical sheet/keyboard/picker/permission acceptance. The only reproduced overflow was in the Municipal header behind Send Back, now fixed; no sheet content redesign was introduced.

**Flutter's feature backlog is not cleared. C01/P04 rating/standing integration remains unfinished.** Source recheck finds the shared TrustStanding parser/display and optional Profile input, but no Citizen model/auth-sync trustRating mapping, Home standing placement or live Profile standing wiring. Those display pieces are not end-to-end delivery. The older C01 completion row is corrected to partial. No rating feature is implemented or marked complete by this sweep.

DEV profile APK throughb7f58eb is verified, replace-installed and open with app data retained. Three runtime files copied explicitly;40 source hashes match review and14 protected DEV config hashes remain unchanged. Same DEV package/label/signature, compiled local API and DEV Firebase verified; production targets absent. Exact artifact/device evidence remains private. Web runtime remains81f4ad0 (last415 tests/lint/build); API d00b6c6 and original native/owner SVG remain untouched. No API process changes, real account/report mutations, merge, promotion or production deployment.

Next: remaining all-role card/data-state comparisons, then supported password last-character masking investigation, continuing the consolidated open feature backlog including C01/P04. Owner device checks, Maintenance/real push, uncertain-save wording and Francis-owned success/Activity Detail remain open.


## First rendered slice and final password card repair

Native runtime **6f7ea7f** adds the existing grouped AuthScreenLayout option to SetNewPasswordScreen. The Forgotten Password phone step was already grouped, but the final password step still left its heading/message outside the card. This now groups heading, message, fields, action and footer for forgot/change/first-login purposes; brand stays outside. The first-login warning and absence of Back remain; other purpose callbacks, secure input/autofill/Show-Hide, validation, failure input retention and save behavior are unchanged. Web already uses this grouping; no web runtime change.

**1,463 native tests and analyzer pass.** Twenty-four new cases cover three purposes, four widths (320/390/412/1440), both themes, 1.5x text and keyboard inset; they check grouping, Show, submission/failure input retention, reachable actions and purpose-appropriate Back. Eight private render cases exercised four actual screens (32 screen/theme/width/scale combinations, 64 top/bottom captures) at320/412, both themes and1x/1.5x text. Before/after password and representative narrow/high-text renders inspected. Maintenance Update Progress, Citizen Create Report and About retain their prior direct-form/editorial composition: no recent card removal was established from their compared source/history and rendered sample. This finding does not approve every possible workflow state.

Actual Maintenance photo-source and shared Profile-name edit sheets were opened at320/412 in both themes with1.5x text. Twelve private captures cover photo source, profile idle and simulated keyboard300px. Cancel/barrier returned without writes; profile does not request the keyboard on open. Four consumer render checks plus11 existing shared-sheet selection/barrier/drag/reduced-motion checks pass (15 total). Native platform picker/GPS/maps/push/biometric/physical keyboard behavior was not exercised. The shared-profile failed-save wording should be reviewed alongside the already recorded Admin Profile uncertainty issue; it is not fixed by this layout change.

DEV build/install status is recorded in LATIF_PROGRESS.md and web CURRENT_STATUS.md. Exact artifact/raster/device evidence stays private. The overall59-screen/all-state sweep and owner phone acceptance remain open.


Scope: source discovery at native runtime 6f2fe41 (test-only follow-up c9db7e0). This lists all 59 current `lib/features/*/screens/*screen.dart` files and the 10 shared-sheet launches in eight consumer files. It is a source map, not a claim that every screen/state has been rendered or accepted on a phone. Shared widgets and routing still require their consumer checks. No runtime layout was changed by this inventory.

The earlier repaired Admin identity/create/details/Settings/overview groups remain in source. Citizen report summaries/review/photos/location and Municipal/Ministry/Maintenance detail groups still delegate to their named cards. All five profile families use ProfileHeaderCard/ProfileSection. All five notification entries delegate to NotificationInboxPanel. Card names alone do not prove correct visual containment, spacing or state behavior.

Exceptions require context, not automatic wrapping: Change/Forgot Password and OTP delegate to AuthScreenLayout (Forgot OTP grouping was missing at the initial inventory and is repaired in4b68b56; registration OTP retains its earlier composition); Login/Register/Set New Password use that shared layout too. About, biometric lock, onboarding and the test role selector have separate compositions. Maintenance Update Progress's outer form is a ListView/Column; its earlier source before ca225c8 also used that structure, so this is not evidence of a card removed by the recent Admin repair. Keep it on the visual comparison list rather than inventing a new card design. Citizen Create Report intentionally mixes direct fields with location/action cards. Settings' groups use shaped Material surfaces, not a class named Card.

## Screen source map

All rows below mean **source located; full visual/state/device check still pending**, except the narrow owner confirmations recorded in the current handoff. Group names are discovery clues, not an acceptance result.

| Feature / screen | Named surface or composition |
| --- | --- |
| [admin/screens/admin_alerts_screen.dart](../../lib/features/admin/screens/admin_alerts_screen.dart) | List slice checked above; review/detail still pending. Card, _AlertCard |
| [admin/screens/admin_create_user_screen.dart](../../lib/features/admin/screens/admin_create_user_screen.dart) | FormSectionCard, _Section |
| [admin/screens/admin_dashboard_screen.dart](../../lib/features/admin/screens/admin_dashboard_screen.dart) | GlassCard |
| [admin/screens/admin_maintenance_teams_screen.dart](../../lib/features/admin/screens/admin_maintenance_teams_screen.dart) | GlassCard, _Section, _TeamCard |
| [admin/screens/admin_notifications_screen.dart](../../lib/features/admin/screens/admin_notifications_screen.dart) | NotificationInboxPanel |
| [admin/screens/admin_overview_screen.dart](../../lib/features/admin/screens/admin_overview_screen.dart) | _DashboardCard |
| [admin/screens/admin_profile_screen.dart](../../lib/features/admin/screens/admin_profile_screen.dart) | ProfileHeaderCard, ProfileSection, ProfileSessionSection |
| [admin/screens/admin_report_routing_screen.dart](../../lib/features/admin/screens/admin_report_routing_screen.dart) | _RoutingCard |
| [admin/screens/admin_role_management_screen.dart](../../lib/features/admin/screens/admin_role_management_screen.dart) | GlassCard, _TierCard |
| [admin/screens/admin_system_activity_screen.dart](../../lib/features/admin/screens/admin_system_activity_screen.dart) | GlassCard, _ActivityCard, _HealthStatCard |
| [admin/screens/admin_system_settings_screen.dart](../../lib/features/admin/screens/admin_system_settings_screen.dart) | Three shaped Material groups via _SystemPreferencesSection |
| [admin/screens/admin_user_details_screen.dart](../../lib/features/admin/screens/admin_user_details_screen.dart) | Card, FormSectionCard, _Section |
| [admin/screens/admin_user_management_screen.dart](../../lib/features/admin/screens/admin_user_management_screen.dart) | GlassCard, _UserCard |
| [authentication/screens/about_screen.dart](../../lib/features/authentication/screens/about_screen.dart) | Static About composition |
| [authentication/screens/bio_lock_screen.dart](../../lib/features/authentication/screens/bio_lock_screen.dart) | AuthBackdrop / biometric lock |
| [authentication/screens/change_password_screen.dart](../../lib/features/authentication/screens/change_password_screen.dart) | AuthScreenLayout; implemented grouped recovery flow |
| [authentication/screens/forgot_password_screen.dart](../../lib/features/authentication/screens/forgot_password_screen.dart) | AuthScreenLayout; implemented grouped recovery flow |
| [authentication/screens/login_screen.dart](../../lib/features/authentication/screens/login_screen.dart) | AuthScreenLayout; _LoginStatusPanel |
| [authentication/screens/otp_verification_screen.dart](../../lib/features/authentication/screens/otp_verification_screen.dart) | AuthScreenLayout; recovery grouping |
| [authentication/screens/registration_screen.dart](../../lib/features/authentication/screens/registration_screen.dart) | AuthScreenLayout; _RegistrationStatusPanel |
| [authentication/screens/set_new_password_screen.dart](../../lib/features/authentication/screens/set_new_password_screen.dart) | AuthScreenLayout / SetNewPasswordForm |
| [authentication/screens/test_role_selector_screen.dart](../../lib/features/authentication/screens/test_role_selector_screen.dart) | Test role-selector composition |
| [authentication/screens/welcome_screen.dart](../../lib/features/authentication/screens/welcome_screen.dart) | AuthBackdrop / onboarding pager |
| [citizen/screens/citizen_alerts_screen.dart](../../lib/features/citizen/screens/citizen_alerts_screen.dart) | NotificationInboxPanel |
| [citizen/screens/citizen_dashboard_screen.dart](../../lib/features/citizen/screens/citizen_dashboard_screen.dart) | CivicGlassCard, CivicStatusPanel, NearbySecondingCard, _DashboardStatePanel, _EmptyRecentReportsCard, _QuickActionCard, _RecentReportsSection, _ReportHeroCard |
| [citizen/screens/citizen_profile_screen.dart](../../lib/features/citizen/screens/citizen_profile_screen.dart) | ProfileHeaderCard, ProfileSection, ProfileSessionSection |
| [citizen/screens/citizen_reports_screen.dart](../../lib/features/citizen/screens/citizen_reports_screen.dart) | History-card surface repaired above; shared stats/empty treatment retained. _ReportHistoryCard, _ReportsStatCard |
| [citizen/screens/create_report_screen.dart](../../lib/features/citizen/screens/create_report_screen.dart) | CivicGlassCard, _LocationCard |
| [citizen/screens/location_picker_screen.dart](../../lib/features/citizen/screens/location_picker_screen.dart) | CivicGlassCard, _SearchPanel, _SelectedLocationCard |
| [citizen/screens/photo_upload_screen.dart](../../lib/features/citizen/screens/photo_upload_screen.dart) | CivicGlassCard, _PhotoActionsCard, _PhotoTipsCard, _UploadedPhotosSection |
| [citizen/screens/report_submitted_screen.dart](../../lib/features/citizen/screens/report_submitted_screen.dart) | CivicGlassCard, _ActionCard, _NextInfoCard, _ReferenceCard |
| [citizen/screens/report_tracking_screen.dart](../../lib/features/citizen/screens/report_tracking_screen.dart) | CivicGlassCard, _CurrentStatusCard, _LatestUpdateCard, _ReportSummaryCard |
| [citizen/screens/review_report_screen.dart](../../lib/features/citizen/screens/review_report_screen.dart) | CivicGlassCard, _CategoryCard, _LocationCard, _PhotosCard, _ReportDetailsCard, _ReviewCard, _SubmitCard |
| [maintenance/screens/assigned_tasks_screen.dart](../../lib/features/maintenance/screens/assigned_tasks_screen.dart) | GlassCard, _NoMatchesCard, _TaskCard |
| [maintenance/screens/dashboard_screen.dart](../../lib/features/maintenance/screens/dashboard_screen.dart) | GlassCard, _StatCard, _WeeklyCompletionCard |
| [maintenance/screens/maintenance_notifications_screen.dart](../../lib/features/maintenance/screens/maintenance_notifications_screen.dart) | NotificationInboxPanel |
| [maintenance/screens/profile_screen.dart](../../lib/features/maintenance/screens/profile_screen.dart) | ProfileHeaderCard, ProfileSection, ProfileSessionSection |
| [maintenance/screens/task_completed_screen.dart](../../lib/features/maintenance/screens/task_completed_screen.dart) | GlassCard |
| [maintenance/screens/task_details_screen.dart](../../lib/features/maintenance/screens/task_details_screen.dart) | GlassCard |
| [maintenance/screens/update_progress_screen.dart](../../lib/features/maintenance/screens/update_progress_screen.dart) | Direct outer form; status/evidence controls, no recent card-loss evidence |
| [ministry/screens/ministry_analytics_screen.dart](../../lib/features/ministry/screens/ministry_analytics_screen.dart) | GlassCard, _StatCard |
| [ministry/screens/ministry_dashboard_screen.dart](../../lib/features/ministry/screens/ministry_dashboard_screen.dart) | GlassCard, _QuickInsightCard, _ReportStatisticsCard |
| [ministry/screens/ministry_municipal_performance_screen.dart](../../lib/features/ministry/screens/ministry_municipal_performance_screen.dart) | GlassCard, _StatCard |
| [ministry/screens/ministry_municipality_detail_screen.dart](../../lib/features/ministry/screens/ministry_municipality_detail_screen.dart) | GlassCard, _OfficerContactCard, _StatCard |
| [ministry/screens/ministry_notifications_screen.dart](../../lib/features/ministry/screens/ministry_notifications_screen.dart) | NotificationInboxPanel |
| [ministry/screens/ministry_profile_screen.dart](../../lib/features/ministry/screens/ministry_profile_screen.dart) | ProfileHeaderCard, ProfileSection, ProfileSessionSection |
| [ministry/screens/ministry_report_insights_screen.dart](../../lib/features/ministry/screens/ministry_report_insights_screen.dart) | GlassCard, _StatCard, _StrategicFocusCard |
| [ministry/screens/ministry_reports_screen.dart](../../lib/features/ministry/screens/ministry_reports_screen.dart) | GlassCard, _ReportCard, _StatCard |
| [municipal/screens/municipal_active_reports_screen.dart](../../lib/features/municipal/screens/municipal_active_reports_screen.dart) | GlassCard, _ActiveReportCard |
| [municipal/screens/municipal_assign_team_screen.dart](../../lib/features/municipal/screens/municipal_assign_team_screen.dart) | GlassCard, _AssignmentSummaryCard, _ReportSummaryCard, _TeamCard |
| [municipal/screens/municipal_dashboard_screen.dart](../../lib/features/municipal/screens/municipal_dashboard_screen.dart) | GlassCard, _AssignmentSummaryCard, _RecentReportsCard, _StatCard |
| [municipal/screens/municipal_inbox_screen.dart](../../lib/features/municipal/screens/municipal_inbox_screen.dart) | GlassCard, MunicipalInboxScreen, _InboxContent, _InboxEmpty, _InboxNoResults, _MunicipalInboxScreenState, _ReportCard, _ReportCardSkeleton |
| [municipal/screens/municipal_notifications_screen.dart](../../lib/features/municipal/screens/municipal_notifications_screen.dart) | NotificationInboxPanel |
| [municipal/screens/municipal_profile_screen.dart](../../lib/features/municipal/screens/municipal_profile_screen.dart) | ProfileHeaderCard, ProfileSection, ProfileSessionSection |
| [municipal/screens/municipal_report_progress_screen.dart](../../lib/features/municipal/screens/municipal_report_progress_screen.dart) | GlassCard, _CaseSummaryCard, _FailureNoticeCard, _RecentActivityCard, _StatusTimelineCard, _SummaryCard, _SyncPendingCard |
| [municipal/screens/municipal_report_review_screen.dart](../../lib/features/municipal/screens/municipal_report_review_screen.dart) | GlassCard, _SectionCard |
| [municipal/screens/municipal_resolution_details_screen.dart](../../lib/features/municipal/screens/municipal_resolution_details_screen.dart) | GlassCard, _EvidenceCard, _SummaryCard, _TimelineCard |
| [municipal/screens/municipal_resolved_reports_screen.dart](../../lib/features/municipal/screens/municipal_resolved_reports_screen.dart) | GlassCard, _ResolvedReportCard, _StatCard |
| [municipal/screens/municipal_verification_screen.dart](../../lib/features/municipal/screens/municipal_verification_screen.dart) | GlassCard |

## Shared sheets

Every actual native modal-bottom-sheet launch found in `lib` uses showCivicBottomSheet. The only direct showModalBottomSheet call is inside its implementation; comment references are not consumers. The helper retains the shared surface, native barrier/Back/drag, 200/100ms motion and reduced-motion handling. This source fact does not establish physical feel, keyboard or dismissal acceptance.

| Consumer | Launches | Preserved responsibility |
| --- | --- | --- |
| Citizen dashboard | 1 | Nearby results and confirmation |
| Citizen Create Report | 1 | Duplicate decision; drag disabled; result/session guards |
| Maintenance Update Progress | 1 | Photo source selection |
| Municipal Active Reports | 1 | Sort result |
| Municipal Report Progress | 1 | Send-back reason form |
| Ministry Report Insights | 3 | Date range, category, status |
| Shared Ministry region picker | 1 | Region selection |
| Shared profile name editor | 1 | Opaque form, drag disabled, save/discard guard |

## Remaining work

- [x] Render the first direct-form slice: Maintenance Update Progress, Citizen Create Report, Set New Password and About. Final password grouping repaired in6f7ea7f; other sampled compositions preserved. Scope and automated evidence are above; physical acceptance remains separate.
- [x] Render representative remaining auth compositions/states and all remaining shared-sheet surfaces. Scoped evidence above; physical and exhaustive workflow checks remain pending.
- [x] Open Alerts list fixture slice: opaque populated/empty cards, larger count/updating text, loading/failure/recovery. Owner phone acceptance remains pending.
- [x] Citizen Reports history-card surface corrected against web; scoped pixel/search/fixture checks above. Owner phone acceptance pending.
- [ ] Citizen bottom-navigation 1px overflow at 412px/1.5x text (separate open issue); no fix included in the history-card repair.
- [ ] Open Alerts review/detail is next; inspect this screen before moving to later mapped screens.
- [ ] Continue all-role card/data-state comparisons; the C01/P04 rating/standing feature remains explicitly unfinished.
- [ ] Continue all-role visual/state comparisons for the mapped cards, including long content, narrow/large text, light/dark, loading/failure and keyboard. Keep each confirmed defect scoped to its screen; do not infer a global redesign from this map.
- [ ] Device-check sheet selection/results, barrier/Back/drag, form keyboard, save/discard, reduced motion and restored search/scroll. Preserve existing accepted collapsing search and Flutter-only chip motion.
- [ ] Retain the previously recorded Admin Profile failed-save uncertainty wording issue for its own repair; do not mark it fixed here.
- [ ] Broader password/device/IME/autofill and native iOS checks remain open. Owner moved masking ahead of cards and confirmed Android/web hidden typing; do not repeat the old masking queue or infer every platform/flow is complete.

Maintenance/real push and Francis-owned success/Activity Detail remain open. See web docs/CURRENT_STATUS.md and LATIF_PROGRESS.md for current runtime/install/owner checks. Automated source discovery and prior test totals are separate from current owner acceptance.
