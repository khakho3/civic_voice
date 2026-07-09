/// Civic Glass Design System — Color Tokens.
///
/// Source: CivicVoice Design System Requirements §19.3 (Color System).
///
/// Rules enforced by these tokens (see source §19.3):
/// - Pure white shall not be used as the primary application background.
/// - AA contrast compliance is mandatory; AAA is the target whenever practical.
/// - Color shall never be the sole indicator of status — pair with an icon and label
///   (see [AppSemantics] and [AppIcons]).
///
/// No screen should reference a raw [Color] literal. Always import this file.
library;

import 'package:flutter/material.dart';

/// Brand and semantic colors shared by both the light and dark themes.
abstract final class AppColors {
  const AppColors._();

  // Primary brand — §19.3 "Primary Brand Color".
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryHover = Color(0xFF1D4ED8);
  static const Color primaryPressed = Color(0xFF1E40AF);

  // Semantic colors — §19.3 "Semantic Colors".
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Report status colors — §19.3 "Status Colors". Always pair with a label and
  // icon (see [AppIcons] status group) — color alone must never carry meaning.
  static const Color statusSubmitted = Color(0xFF2563EB);
  static const Color statusUnderReview = Color(0xFFF59E0B);
  static const Color statusAssigned = Color(0xFF8B5CF6);
  static const Color statusInProgress = Color(0xFF0EA5E9);
  static const Color statusResolved = Color(0xFF16A34A);
  static const Color statusRejected = Color(0xFFDC2626);
}

/// Light theme surface, text, and border tokens — §19.3 "Light Theme".
abstract final class AppColorsLight {
  const AppColorsLight._();

  static const Color canvas = Color(0xFFF8FAFC);
  static const Color primarySurface = Color(0xFFFFFFFF);
  static const Color secondarySurface = Color(0xFFF1F5F9);

  /// rgba(255,255,255,0.65) — permitted only on navigation panels, cards,
  /// dialogs, bottom sheets, filters, and search containers (§19.10 Glass
  /// Usage Rules). Prohibited on long-form content, input-heavy forms,
  /// analytics charts, and large text sections.
  static const Color glassSurface = Color.fromRGBO(255, 255, 255, 0.65);

  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF475569);
  static const Color border = Color(0xFFE2E8F0);
}

/// Dark theme surface, text, and border tokens — §19.3 "Dark Theme".
abstract final class AppColorsDark {
  const AppColorsDark._();

  static const Color canvas = Color(0xFF0F172A);
  static const Color primarySurface = Color(0xFF111827);
  static const Color secondarySurface = Color(0xFF1E293B);

  /// rgba(15,23,42,0.75) — see [AppColorsLight.glassSurface] usage rules.
  static const Color glassSurface = Color.fromRGBO(15, 23, 42, 0.75);

  static const Color primaryText = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFFCBD5E1);
  static const Color border = Color(0xFF334155);
}

/// Glass-surface blur tokens.
///
/// Not yet formally quantified by the Design System Requirements (flagged as
/// pending in CL-001 "Blur Tokens"). These sigma values follow the documented
/// principle that "glass surfaces must maintain subtle elevation" (§19.8) and
/// should be superseded by an approved CL once formally specified.
abstract final class AppGlassBlur {
  const AppGlassBlur._();

  static const double small = 10.0;
  static const double medium = 20.0;
  static const double large = 30.0;
}

/// Theme-aware semantic colors that fall outside Material's [ColorScheme]
/// (success / warning / info / report-status colors). Registered on
/// [ThemeData.extensions] by [AppLightTheme] and [AppDarkTheme] so any screen
/// can reach them via `Theme.of(context).extension<AppSemanticColors>()`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.statusSubmitted,
    required this.statusUnderReview,
    required this.statusAssigned,
    required this.statusInProgress,
    required this.statusResolved,
    required this.statusRejected,
    required this.glassSurface,
  });

  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color statusSubmitted;
  final Color statusUnderReview;
  final Color statusAssigned;
  final Color statusInProgress;
  final Color statusResolved;
  final Color statusRejected;
  final Color glassSurface;

  static const AppSemanticColors light = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    statusSubmitted: AppColors.statusSubmitted,
    statusUnderReview: AppColors.statusUnderReview,
    statusAssigned: AppColors.statusAssigned,
    statusInProgress: AppColors.statusInProgress,
    statusResolved: AppColors.statusResolved,
    statusRejected: AppColors.statusRejected,
    glassSurface: AppColorsLight.glassSurface,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    success: AppColors.success,
    warning: AppColors.warning,
    error: AppColors.error,
    info: AppColors.info,
    statusSubmitted: AppColors.statusSubmitted,
    statusUnderReview: AppColors.statusUnderReview,
    statusAssigned: AppColors.statusAssigned,
    statusInProgress: AppColors.statusInProgress,
    statusResolved: AppColors.statusResolved,
    statusRejected: AppColors.statusRejected,
    glassSurface: AppColorsDark.glassSurface,
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? statusSubmitted,
    Color? statusUnderReview,
    Color? statusAssigned,
    Color? statusInProgress,
    Color? statusResolved,
    Color? statusRejected,
    Color? glassSurface,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      statusSubmitted: statusSubmitted ?? this.statusSubmitted,
      statusUnderReview: statusUnderReview ?? this.statusUnderReview,
      statusAssigned: statusAssigned ?? this.statusAssigned,
      statusInProgress: statusInProgress ?? this.statusInProgress,
      statusResolved: statusResolved ?? this.statusResolved,
      statusRejected: statusRejected ?? this.statusRejected,
      glassSurface: glassSurface ?? this.glassSurface,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      statusSubmitted: Color.lerp(statusSubmitted, other.statusSubmitted, t)!,
      statusUnderReview:
          Color.lerp(statusUnderReview, other.statusUnderReview, t)!,
      statusAssigned: Color.lerp(statusAssigned, other.statusAssigned, t)!,
      statusInProgress:
          Color.lerp(statusInProgress, other.statusInProgress, t)!,
      statusResolved: Color.lerp(statusResolved, other.statusResolved, t)!,
      statusRejected: Color.lerp(statusRejected, other.statusRejected, t)!,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
    );
  }
}
