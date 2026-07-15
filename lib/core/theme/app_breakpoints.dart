/// Civic Glass Design System — Responsive Breakpoint Tokens.
///
/// Source: CivicVoice Design System Requirements §19.10 (Responsive Design
/// Rules).
///
/// Rules enforced by these tokens (see source §19.9–§19.10):
/// - Mobile is the primary target; layouts must adapt gracefully across
///   Small, Standard, and Large phones, and Tablets.
/// - Components must scale proportionally; content clipping is prohibited.
/// - Navigation is Bottom Navigation on mobile, Sidebar Navigation on tablet.
library;

import 'package:flutter/widgets.dart';

/// Breakpoint widths, in logical pixels — §19.10 "Breakpoints".
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  static const double smallMobile = 320;
  static const double standardMobile = 375;
  static const double largeMobile = 428;
  static const double tablet = 768;
}

/// Device size classes derived from [AppBreakpoints], used to select layout
/// and navigation patterns (§19.10 "Navigation Responsiveness").
enum AppDeviceType {
  smallMobile,
  standardMobile,
  largeMobile,
  tablet;

  /// Classifies a logical-pixel [width] into the matching breakpoint tier.
  factory AppDeviceType.fromWidth(double width) {
    if (width >= AppBreakpoints.tablet) return AppDeviceType.tablet;
    if (width >= AppBreakpoints.largeMobile) return AppDeviceType.largeMobile;
    if (width >= AppBreakpoints.standardMobile) {
      return AppDeviceType.standardMobile;
    }
    return AppDeviceType.smallMobile;
  }

  /// True for [tablet] — the threshold at which navigation switches from
  /// Bottom Navigation to Sidebar Navigation (§19.10).
  bool get isTablet => this == AppDeviceType.tablet;
}

/// Convenience accessors for resolving the current [AppDeviceType] from a
/// [BuildContext], without every screen re-implementing breakpoint math.
extension AppBreakpointsContext on BuildContext {
  double get _screenWidth => MediaQuery.sizeOf(this).width;

  /// The current [AppDeviceType] for this context's screen width.
  AppDeviceType get deviceType => AppDeviceType.fromWidth(_screenWidth);

  /// True when the current layout should use Sidebar Navigation
  /// (Tablet, §19.10) rather than Bottom Navigation.
  bool get isTabletLayout => deviceType.isTablet;
}
