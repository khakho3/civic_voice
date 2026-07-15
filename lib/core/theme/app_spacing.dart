/// Civic Glass Design System — Spacing Tokens.
///
/// Source: CivicVoice Design System Requirements §19.6 (Spacing System).
///
/// Rules enforced by these tokens (see source §19.6):
/// - The entire platform uses an 8-point spacing system; arbitrary spacing
///   values are prohibited.
/// - Components shall align to this scale and keep internal spacing consistent
///   so visual rhythm is maintained across screens.
///
/// Always build [EdgeInsets], `SizedBox` gaps, and `Gap`/`spacing` arguments
/// from [AppSpacing] — never a raw numeric literal.
library;

/// 8-point spacing scale — §19.6 "Spacing Tokens".
abstract final class AppSpacing {
  const AppSpacing._();

  /// 4px — hairline gaps (e.g. icon-to-label spacing inside a chip).
  static const double xs = 4;

  /// 8px — the base unit; tight internal component padding.
  static const double sm = 8;

  /// 16px — standard internal padding and inter-element spacing.
  static const double md = 16;

  /// 24px — spacing between grouped sections within a screen.
  static const double lg = 24;

  /// 32px — spacing between major sections.
  static const double xl = 32;

  /// 40px — screen-level vertical rhythm.
  static const double xxl = 40;

  /// 48px — large screen-level separation.
  static const double xxxl = 48;

  /// 64px — maximum spacing token, reserved for hero/empty-state layouts.
  static const double xxxxl = 64;
}
