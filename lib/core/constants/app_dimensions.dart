/// Civic Glass Design System — Dimension Tokens.
///
/// Concrete component and layout geometry, composed from [AppSpacing],
/// [AppBreakpoints], and [AppAccessibility] rather than introducing new
/// arbitrary numbers — the Design System Requirements prohibit arbitrary
/// spacing values (§19.6) and this extends the same discipline to sizing.
///
/// For policy thresholds (touch target minimums, text-size minimums, screen
/// states) see [AppSemantics]; for icon sizing see [AppIconSize].
library;

import 'package:flutter/widgets.dart';

import '../theme/app_breakpoints.dart';
import 'app_semantics.dart';

/// Interactive element sizing, anchored to the accessibility touch-target
/// minimum (§19.19).
abstract final class AppDimensions {
  const AppDimensions._();

  /// Minimum tappable area for any interactive control — §19.19 "Touch
  /// Targets". Use as a `BoxConstraints` / `minimumSize` floor for buttons,
  /// icon buttons, and list controls.
  static const Size touchTarget = Size.square(
    AppAccessibility.touchTargetMinimum,
  );

  /// Standard control height (inputs, buttons) — equal to the touch target
  /// minimum, the smallest height that stays accessible.
  static const double controlHeightStandard = AppAccessibility.touchTargetMinimum;

  /// Large emphasis control height (primary CTA buttons, FAB diameter).
  static const double controlHeightLarge = AppAccessibility.touchTargetMinimum + 8;

  /// Hairline border/divider thickness.
  static const double borderWidthThin = 1.0;

  /// Emphasized border thickness (e.g. focused input outline).
  static const double borderWidthFocused = 2.0;

  /// Maximum readable content width once a layout crosses into the Tablet
  /// breakpoint (§19.9 Content Width Rules) — prevents unbounded single-column
  /// text measure on wide screens while leaving mobile widths unconstrained.
  static const double maxContentWidth = AppBreakpoints.tablet;

  /// Height of the glass header bar (screen title/brand mark + actions),
  /// shared by every Municipal Officer screen.
  static const double headerHeight = 64;

  /// Height of the glass bottom navigation bar.
  static const double bottomNavHeight = 80;
}
