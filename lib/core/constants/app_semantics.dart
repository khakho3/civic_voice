/// Civic Glass Design System — Semantic Sizing & Accessibility Tokens.
///
/// Source: CivicVoice Design System Requirements §19.18 (State System) and
/// §19.19 (Accessibility Standards).
///
/// These tokens encode *policy* thresholds — accessibility minimums and the
/// universal screen-state vocabulary — as opposed to [AppDimensions], which
/// holds concrete component geometry.
library;

/// Accessibility compliance targets — §19.19 "Compliance Target".
abstract final class AppAccessibility {
  const AppAccessibility._();

  static const String complianceMinimum = 'WCAG 2.2 AA';
  static const String complianceTarget = 'WCAG 2.2 AAA';

  /// Minimum contrast ratio for normal-weight body text under WCAG 2.2 AA
  /// (Success Criterion 1.4.3) — applies wherever [AppColors] text tokens are
  /// paired with a surface token.
  static const double contrastRatioNormalText = 4.5;

  /// Minimum contrast ratio for large-scale text (≥24px regular or ≥19px
  /// bold) and UI component graphics under WCAG 2.2 AA (SC 1.4.3 / 1.4.11).
  static const double contrastRatioLargeText = 3.0;

  /// Minimum interactive touch target size, in logical pixels (both
  /// dimensions) — §19.19 "Touch Targets".
  static const double touchTargetMinimum = 48.0;

  /// Minimum permitted body text size, in logical pixels — §19.4 Typography
  /// Accessibility Rule 4. (See [AppFontSize.caption] for the one approved
  /// exception: 12px non-body microcopy such as captions and labels.)
  static const double minBodyTextSize = 14.0;
}

/// Navigation semantic constraints — §19.16 (Navigation Standards).
abstract final class AppNavigationSemantics {
  const AppNavigationSemantics._();

  /// Maximum number of destinations in Bottom Navigation — §19.16
  /// "Bottom Navigation" table.
  static const int bottomNavMaxItems = 5;
}

/// Universal screen states every screen must support where applicable —
/// §19.18 "State System". This is a UI-rendering vocabulary, not a domain
/// model: feature code maps its own business states onto these.
enum AppScreenState {
  /// Skeleton loaders, shimmer, or progress indicators. Blank screens while
  /// loading are prohibited.
  loading,

  /// No data to display (e.g. no reports, no notifications, no results).
  /// Requires an illustration/icon, a message, and a recommended action.
  empty,

  /// A user action completed successfully. Requires a success icon, a
  /// confirmation message, and a next action.
  success,

  /// An operation failed. Requires an error message, a recovery action, and
  /// a retry option.
  error,

  /// No connectivity. Requires a connectivity indicator, a retry action, and
  /// sync status.
  offline,

  /// The current user lacks permission to view this screen. Requires a
  /// friendly explanation and a navigation-back path.
  permission,

  /// The screen/control is present but not currently interactive.
  disabled,
}
