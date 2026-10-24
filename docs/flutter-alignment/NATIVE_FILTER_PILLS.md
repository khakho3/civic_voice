# Shared Flutter filter pills

Updated 24 October 2026.

## Scope

The owner narrowed this rollout to Flutter only on 24 October. Keep the accepted native alert ChoiceChip selection/checkmark motion. The attempted web animation flickered; all web runtime/test edits from that attempt were restored before committing. Existing web FilterChip, dropdowns and collapsible search remain unchanged. This supersedes the earlier cross-client rollout requirement.

CivicFilterChip is the single native filter-pill surface. Choices use the original ChoiceChip theme/native motion; picker triggers use RawChip with the same theme and keep their existing sheet actions. There is no global chip-theme or search-header rewrite. Reduced motion disables chip selection/checkmark/drawer transitions, including when that preference changes. Existing filter values, selection callbacks, nullable All values, query handling, haptics and search ownership remain with each consumer. Disabled/busy callbacks are null; 48 px touch areas retain keyboard/selected semantics.

## Consumer inventory

| Screens | Shared path | Behaviour retained |
| --- | --- | --- |
| Admin Alerts | CivicFilterChip | Server state/query and cursor reset; loading disables choices |
| Admin Users | CivicFilterChip | Existing role/status scope and focused search |
| Admin System Activity | CivicFilterChip | Activity categories and search; time range remains its dropdown |
| Citizen My Reports | CivicFilterChip | Existing status rules and focused search |
| Maintenance Assigned Tasks | TextFilterChips -> CivicFilterChip | Nullable All/status filtering; disabled screen disables chips |
| Municipal Inbox | TextFilterChips -> CivicFilterChip | Nullable category and shared search; disabled rows expose disabled semantics |
| Municipal Active Reports | TextFilterChips -> CivicFilterChip | Status, sort and focused-search ownership |
| Municipal Closed Reports | TextFilterChips -> CivicFilterChip | Existing outcome/status and focused-search rules |
| Municipal Assign Team | TextFilterChips -> CivicFilterChip | Team availability rules; busy/disabled choices remain unavailable |
| Ministry Reports | CivicFilterChip + shared RegionPickerChip | Status and exact existing region picker |
| Ministry Analytics | CivicFilterChip | Breakdown dimension; date dropdown unchanged |
| Ministry Municipal Performance | CivicFilterChip + shared RegionPickerChip | Scope and region; existing text metric controls unchanged |
| Ministry Report Insights | CivicFilterChip picker variant | Date/category/status sheets and cancel/selection results |

This covers all 13 native screens with filter pills. Read-only status/count/profile/permission chips, verification reason suggestions, ordinary dropdowns and text metric controls are not filter-pill consumers. Admin Teams retains its geography dropdowns. No remaining direct ChoiceChip/FilterChip implementations exist outside CivicFilterChip.

## Verification and acceptance

Runtime commits: d3bece1 / 7a796f6. Final checks: 1,320 native tests pass, analyzer/whitespace clean; 365 web tests, lint/build pass (209 PWA entries). Coverage includes controlled selection/checkmarks, keyboard/focus, disabled choices, picker dismissal, reduced motion, nullable values and long horizontal pills at 2x text size. The existing 80 held-gesture search-consumer cases retain collapse/reverse/true-top/focused-search restoration across ten screens at 320/390/412/1440 px in both themes. Twenty-four additional real Ministry screen cases cover both themes/four widths. Actual native alert widgets were rendered and visually inspected in light/dark using ignored QA fixtures; no owner records were changed.

Web source is restored. Its full suite/lint/build and an eight-case browser matrix of the actual shared search verify existing collapse/focused-search/exact restore with no horizontal page overflow or API calls.

No new DEV APK has been built or installed for these pills. The installed DEV runtime remains 93667f6; source changes and screenshot/test checks are not owner phone confirmation. Keep the ignored private checklist current. Maintenance and real push acceptance remain independent. The System Activity refresh flicker remains recorded and unfixed; do not infer a refresh repair from passing search tests. Next implementation stays the Super Admin unresolved-locality routing safeguard, followed by password hiding/padlock and the remaining consolidated backlog. No merge, promotion, deployment or API/config changes.
