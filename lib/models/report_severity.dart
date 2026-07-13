/// Shared report severity model.
///
/// Cross-cutting across every module that triages reports (Municipal
/// Officer, Maintenance Team) — lives in shared `lib/models/` alongside
/// [ReportStatus] rather than a single feature module.
///
/// Reuses the existing semantic color tokens (error/warning/success) rather
/// than introducing new ones — confirmed against MUN-002 Incoming Reports:
/// High maps to the same red as [AppColors.error], Medium to the same amber
/// as [AppColors.warning], Low to the same green as [AppColors.success].
library;

import 'package:flutter/widgets.dart';

import '../core/theme/app_theme.dart';

enum ReportSeverity {
  high,
  medium,
  low;

  String get label => switch (this) {
    ReportSeverity.high => 'High',
    ReportSeverity.medium => 'Medium',
    ReportSeverity.low => 'Low',
  };

  Color get color => switch (this) {
    ReportSeverity.high => AppColors.error,
    ReportSeverity.medium => AppColors.warning,
    ReportSeverity.low => AppColors.success,
  };

  /// Text color for [color] rendered on its own low-alpha tint (severity
  /// badges) — see [ReportStatus.badgeTextColor] for why this isn't simply
  /// [color]. Medium reuses the exact same warning-amber shift since both
  /// draw from [AppColors.warning].
  Color badgeTextColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      ReportSeverity.high => AppColors.error, // AA-safe as-is
      ReportSeverity.medium =>
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      ReportSeverity.low => AppColors.success, // AA-safe as-is
    };
  }
}
