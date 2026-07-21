/// Civic Glass Design System — Motion Tokens.
///
/// The Design System Requirements mandate "Reduced Motion" accessibility
/// support (§19.19 Assistive Technologies) but do not yet publish explicit
/// millisecond values — CL-001 lists "Motion Guidelines" under Accessibility
/// Recipes as pending formal definition. Civic Glass is explicitly benchmarked
/// against Material Design (§19.1), so the durations and curves below follow
/// the standard Material 3 motion scale until an approved CL supersedes them.
///
/// Always animate with [AppMotion] tokens — never a raw `Duration` literal —
/// and prefer [AppMotion.duration] over a bare token so reduced-motion users
/// are respected automatically.
library;

import 'package:flutter/material.dart';

/// Standard animation durations, aligned to the Material 3 motion scale.
abstract final class AppMotionDuration {
  const AppMotionDuration._();

  /// 100ms — micro-interactions (ripple, icon toggle).
  static const Duration fast = Duration(milliseconds: 100);

  /// 200ms — default control state changes (button press, chip select).
  static const Duration standard = Duration(milliseconds: 200);

  /// 300ms — small surface transitions (card expand, snackbar in/out).
  static const Duration moderate = Duration(milliseconds: 300);

  /// 400ms — large surface transitions (dialogs, bottom sheets).
  static const Duration emphasized = Duration(milliseconds: 400);

  /// 500ms — full-screen transitions (page routes).
  static const Duration pageTransition = Duration(milliseconds: 500);
}

/// Standard easing curves, aligned to the Material 3 motion scale.
abstract final class AppMotionCurve {
  const AppMotionCurve._();

  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  /// A gentle overshoot — settles slightly past 100% before easing back.
  /// Reserved for Citizen's central "Report" tab (see `tabRoute`'s
  /// `primary` flag) so that one destination's transition reads as more
  /// emphatic than the plain settle every other bottom-nav tab uses.
  static const Curve overshoot = Curves.easeOutBack;
}

/// Motion helpers that honor the platform's "reduce motion" accessibility
/// setting, satisfying the Design System's Reduced Motion requirement
/// (§19.19) at the token level rather than leaving it to each screen.
abstract final class AppMotion {
  const AppMotion._();

  /// Returns [Duration.zero] when the platform requests reduced motion,
  /// otherwise returns [base]. Use for any non-essential animation.
  static Duration duration(BuildContext context, Duration base) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : base;
  }

  /// The one route-transition builder every platform target uses — wired
  /// into both [AppLightTheme] and [AppDarkTheme] so it applies to every
  /// `MaterialPageRoute` app-wide with no per-route changes. Material 3's
  /// Fade-Forwards transition (incoming page fades+slides in from the
  /// trailing edge, outgoing page fades back) — subtle and modern rather
  /// than the platform-default zoom. Framework-level, so it honors
  /// `MediaQuery.disableAnimations` automatically without needing
  /// [duration] above.
  static const PageTransitionsTheme pageTransitionsTheme =
      PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
        },
      );
}
