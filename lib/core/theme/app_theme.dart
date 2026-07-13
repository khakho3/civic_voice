/// Civic Glass Design System — Entry Point.
///
/// Import this single file from any screen to reach the entire design
/// system: colors, typography, spacing, radius, elevation, icons, motion,
/// breakpoints, and the light/dark [ThemeData] pair. This is the intended
/// "one import" referenced by the Design System Requirements' Visual
/// Consistency Rules (§19.10): "Every screen must use approved design
/// tokens."
///
/// Wire it up once in the app root:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
///   themeMode: AppTheme.themeMode,
///   ...
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'app_dark_theme.dart';
import 'app_light_theme.dart';

export '../constants/app_assets.dart';
export '../constants/app_dimensions.dart';
export '../constants/app_semantics.dart';
export 'app_breakpoints.dart';
export 'app_colors.dart';
export 'app_dark_theme.dart';
export 'app_elevation.dart';
export 'app_icons.dart';
export 'app_light_theme.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

/// Top-level accessors for the approved Civic Glass [ThemeData] pair.
abstract final class AppTheme {
  const AppTheme._();

  /// The approved Civic Glass light theme — §19.3 "Light Theme".
  static ThemeData get light => AppLightTheme.theme;

  /// The approved Civic Glass dark theme — §19.3 "Dark Theme".
  static ThemeData get dark => AppDarkTheme.theme;

  /// Every screen must support both Light Mode and Dark Mode (§19.20
  /// Governance Rule 7), so the app follows the platform brightness by
  /// default rather than forcing a single theme.
  static const ThemeMode themeMode = ThemeMode.light;
}
