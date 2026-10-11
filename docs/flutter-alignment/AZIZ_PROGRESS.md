# Aziz foundation progress

## F01 — shared tokens and theme foundation

- **Changed:** `lib/core/theme/app_colors.dart`, `app_light_theme.dart`, and
  `app_dark_theme.dart` now use the approved gold action fills, dark action
  ink, charcoal light/dark surfaces, neutral borders, and matte dark shadows.
  Shared theme foregrounds no longer put gold text directly on light surfaces.
- **Preserved:** Existing semantic success/warning/error/information values,
  real auth/API flows, Ghana-native page loading, and all status lifecycle
  semantics. `statusPendingApproval` is a palette token only; it does not
  change the report enum or serialization contract owned by the workflow team.
- **Automated evidence:** `flutter test test/theme_tokens_test.dart
  --dart-define=API_BASE_URL=http://127.0.0.1:1 --reporter expanded` passed
  (2 tests). The test verifies 4.5:1 action-ink contrast and both theme token
  mappings.
- **Human device evidence:** Pending. Check a filled, outlined, and text
  action in Light/Dark; then check keyboard focus, large text, and a screen
  reader announcement on a physical device.
- **Deferred:** Full role-by-role foreground audit, status text/tint adoption,
  and visual device review remain open. The supplied local web reference was
  read at `http://localhost:5173/`; no web files were modified.

## F10 — shared About wording

- **Changed:** The About screen now uses the accepted wording: “District,
  Municipal, and Metropolitan Assemblies.” Existing verified acknowledgments
  and destinations remain unchanged; no placeholder links were added.

## F01 follow-up — action-text contrast

- **Changed:** Light-theme text links and onboarding brand text now use the
  accessible action-text token instead of gold-on-light-surface. Dark theme
  retains the brighter gold action color. Profile avatar initials now use
  dark action ink in light theme and bright gold in dark theme.
- **Automated evidence:** `flutter test test/authentication_widget_test.dart
  test/profile_field_row_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:1
  --reporter expanded` passed (33 tests).

## P03 — theme preference control

- **Changed:** `ThemePreferenceRow` is now a compact menu-style preference
  row. It has a leading theme icon, a trailing chevron, and a menu with
  System (Default), Light, and Dark choices. The current selection is marked
  inside the menu rather than repeated in the row. Language now has a leading
  language icon and a neutral far-right Coming Soon badge. App Lock and the
  Citizen-only Nearby Reports control now use their biometric/location icons.
- **Preserved:** The existing `ThemeController` remains the single source of
  truth, so selections still persist and System continues to defer to the OS.
- **Changed:** First launch and a missing saved preference now default to
  System (Default), so the app-wide `MaterialApp` follows the device Light or
  Dark setting across every role, route, dialog, and loading screen until a
  manual preference is saved. Outlined actions use the approved gold control
  border while structural card/divider borders remain neutral.
- **Automated evidence:** `flutter test test/theme_preference_row_test.dart
  --dart-define=API_BASE_URL=http://127.0.0.1:1 --reporter expanded` passed
  (1 test). It verifies the menu choices and a Dark selection.
  `flutter test test/biometric_lock_preference_row_test.dart
  test/citizen_widget_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:1
  --reporter expanded` passed (15 tests).
- **Human device evidence:** Pending. Check the row in each role profile on a
  narrow and wide screen, then restart the app to confirm persisted selection
  and verify System responds to an OS theme change.

## P01 — profile row-system foundation

- **Changed:** Shared profile section labels no longer render duplicated
  decorative icons. The leading icons now belong to the rows that convey the
  actual action or preference, preserving a quieter grouped-list hierarchy.
  Registered Citizen, Maintenance, and Admin Profiles now use the compact
  avatar-mounted edit pencil rather than placing it in a section heading.
- **Automated evidence:** `flutter test test/maintenance_widget_test.dart
  test/admin_widget_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:1
  --reporter expanded` passed (146 tests).
- **Changed:** Municipal and Ministry now also use the avatar-mounted edit
  pencil, retaining each role's existing navigation, validation, cancellation,
  save, and failure behavior.
- **Deferred:** Full role-specific content/device review remains open.

## P02 — permission-aware sheet editing

- **Changed:** Registered Citizen Profile now opens the shared name-only
  bottom-sheet editor. It does not focus automatically, keeps phone and other
  administrator/account-controlled fields outside the editor, validates an
  empty name in semantic error styling, and retains explicit Cancel/Save.
- **Preserved:** The existing `ProfileCrudService` remains responsible for
  persistence; guest users still receive Create Account rather than editing.
- **Automated evidence:** `flutter test test/citizen_widget_test.dart
  --dart-define=API_BASE_URL=http://127.0.0.1:1 --reporter expanded` passed
  (13 tests).
- **Deferred:** The equivalent role-specific editor adoption, genuine save
  failure handling against the approved environment, keyboard/device review,
  and return-focus verification remain open.

## F09 — shared haptic preference

- **Changed:** Added one persisted, device-local Haptic feedback preference
  row to Citizen, Municipal, Ministry, Maintenance, and Admin Profiles. It
  uses a leading vibration icon and remains opt-out; enabling it provides one
  restrained native selection haptic.
- **Automated evidence:** Added persistence and widget coverage. The
  haptics/cache and all role-profile regression test selection ran under the
  isolated configuration without a reported failure.
- **Deferred:** Existing action controls do not yet consume this preference,
  and real haptic feel/capability still needs physical-device verification.

## U02 — onboarding navigation

- **Changed:** Onboarding now follows the accepted navigation: Report has no
  Previous control, Track alone has Previous, and Resolve retains the final
  action choices.
- **Automated evidence:** `flutter test test/authentication_widget_test.dart
  --dart-define=API_BASE_URL=http://127.0.0.1:1 --reporter expanded` passed
  (33 tests), including the navigation rule.

## U02 — native brand configuration

- **Changed:** Launcher and Android splash configuration now use the accepted
  light/dark neutral surfaces (`#FAFAF7`, `#101110`, and `#191B19`) rather
  than the earlier blue-grey values. Existing approved adaptive foreground
  and splash assets are registered through `AppAssets` and `pubspec.yaml`.
- **Deferred:** Android round/squircle masks, Android 12+ cold start, iOS
  launch presentation, and the status-bar rendering of the monochrome
  notification icon require physical-device validation.

## F07 — Android notification icon

- **Verified:** FCM's Android manifest uses the dedicated monochrome
  `@drawable/ic_stat_civic_voice` vector rather than the full launcher mark.
  Its configured tint now uses the accepted gold action color.
- **Deferred:** The actual Android status-bar rendering, including contrast in
  light/dark system chrome, requires a physical-device notification test.

## U02 — approved brand-artifact replacement

- **Changed:** Replaced the obsolete blue circular logo, launcher artwork,
  splash mark, favicon, and all three blue onboarding JPEGs with the approved
  gold CivicVoice bubble/Arch assets and Ghana onboarding artwork from the
  read-only web reference. Onboarding now uses the approved WebP files:
  Report (faulty streetlight), Track (report milestones), and Resolve
  (repair celebration). `AppAssets` and `pubspec.yaml` now register only
  those shipped onboarding assets.
- **Verified:** SHA-256 checksums match the approved reference artifacts for
  the master logo, app logo, launcher foreground, launcher icon, favicon,
  and all three onboarding images. `flutter test
  test/authentication_widget_test.dart --dart-define=API_BASE_URL=http://127.0.0.1:1
  --reporter expanded` passed (33 tests). `flutter analyze` completed without
  diagnostics and `git diff --check` found no whitespace errors (only existing
  CRLF warnings).
- **Human device evidence:** Pending. Test launcher round/squircle masks,
  Android 12+ cold start, Light/Dark splash backgrounds, header marks,
  Report/Track/Resolve imagery, text scaling, swipe/Previous behavior, and
  the separate Android notification icon.
- **Native resources:** Rebuilt each Android launcher, adaptive foreground,
  and Android 12 splash density asset from the approved sources. Added the
  required themed monochrome adaptive-icon layer using the approved bubble/
  Arch silhouette. Static dimensions match Android density contracts:
  launcher 48â€“192px, foreground 108â€“432px, and splash 128â€“512px.

## Workspace notes

- Preserved pre-existing changes in the generated Linux and Windows plugin
  registrant headers; they are not part of this task.
- No commits, pushes, API/Firebase changes, or credentials changes were made.
