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
  static const String logoSvg = 'assets/branding/logo.svg';

  /// 1024×1024 master raster logo, rendered from [logoSvg].
  static const String logoPng = 'assets/branding/logo.png';

  /// In-app usage logo (e.g. app bar, splash, empty states).
  static const String logoApp = 'assets/branding/logo_app.png';

  /// App favicon, rendered from [logoSvg].
  static const String favicon = 'assets/branding/favicon.png';

  /// Illustration used on the Authentication Welcome screen.
  static const String welcomeIllustration =
      'assets/branding/welcome_illustration.png';
}
