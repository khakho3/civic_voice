/// Civic Glass Design System — Asset Path Constants.
///
/// Centralizes every asset path declared in `pubspec.yaml` so no screen ever
/// embeds a raw asset string literal. Add new entries here at the same time
/// you register the file under `flutter: assets:` in `pubspec.yaml`.
library;

/// Branding assets — see `assets/branding/` and the pubspec `assets:` list.
abstract final class AppAssets {
  const AppAssets._();

  /// Master vector logo — the single source of truth for the CivicVoice mark.
  /// Master raster logo for the approved CivicVoice mark.
  static const String logoPng = 'assets/branding/logo.png';

  /// In-app usage logo (e.g. app bar, splash, empty states).
  static const String logoApp = 'assets/branding/logo_app.png';

  /// Illustration hero used by the Login and Registration screens.
  static const String authHero = 'assets/branding/auth_hero.png';

  /// The same source as the app's launcher icon, for full-bleed in-app branding.
  static const String iconFlat = 'assets/branding/icon_flat.png';

  /// Transparent foreground used by native adaptive launcher icons.
  static const String iconForeground = 'assets/branding/icon_foreground.png';

  /// Alpha-only foreground used by Android's themed launcher icons.
  static const String iconMonochrome = 'assets/branding/icon_monochrome.png';

  /// Centered mark used by the native splash configuration.
  static const String splashIcon = 'assets/branding/splash_icon.png';

  /// App favicon exported from the approved brand master.
  static const String favicon = 'assets/branding/favicon.png';

  /// Onboarding illustration for reporting a community issue.
  static const String onboardingReport =
      'assets/branding/onboarding_report.webp';

  /// Onboarding illustration for tracking a submitted report.
  static const String onboardingTrack =
      'assets/branding/onboarding_track.webp';

  /// Onboarding illustration for resolving issues as a community.
  static const String onboardingResolve =
      'assets/branding/onboarding_resolve.webp';
}
