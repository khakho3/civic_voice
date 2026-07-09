/// Civic Glass Design System — Elevation & Shadow Tokens.
///
/// Source: CivicVoice Design System Requirements §19.8 (Elevation System).
///
/// Rules enforced by these tokens (see source §19.8):
/// - Elevation shall be subtle; heavy shadows are prohibited.
/// - Elevation communicates hierarchy, not decoration.
/// - Glass surfaces must maintain subtle elevation.
///
/// Exact shadow blur/opacity values are not yet formally quantified by the
/// Design System Requirements (flagged as pending in CL-001 "Shadow Tokens").
/// The [AppShadow] values below implement the documented "subtle, no heavy or
/// decorative shadows" principle using the approved `primaryText` ink color
/// at low opacity, and should be superseded by an approved CL once the
/// exact tokens are formally specified.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material elevation (dp) per level — §19.8 "Elevation System" levels 0–3.
abstract final class AppElevation {
  const AppElevation._();

  /// Level 0 — no shadow. Usage: background surfaces.
  static const double level0 = 0;

  /// Level 1 — light shadow. Usage: standard cards.
  static const double level1 = 1;

  /// Level 2 — medium shadow. Usage: dialogs, bottom sheets.
  static const double level2 = 3;

  /// Level 3 — high-priority floating elements. Usage: FABs, critical
  /// overlays.
  static const double level3 = 6;
}

/// [BoxShadow] tokens for custom `Container`/`DecoratedBox` surfaces that
/// fall outside Material's built-in elevation system (e.g. glass cards).
/// Native Material widgets should prefer [AppElevation] + [ThemeData]
/// (Material 3 communicates elevation primarily through surface tint, which
/// remains legible in dark mode where flat shadows are not).
abstract final class AppShadow {
  const AppShadow._();

  static const List<BoxShadow> level0 = <BoxShadow>[];

  static final List<BoxShadow> level1 = <BoxShadow>[
    BoxShadow(
      color: AppColorsLight.primaryText.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> level2 = <BoxShadow>[
    BoxShadow(
      color: AppColorsLight.primaryText.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> level3 = <BoxShadow>[
    BoxShadow(
      color: AppColorsLight.primaryText.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}
