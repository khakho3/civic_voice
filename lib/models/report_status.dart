/// Shared report-lifecycle status model.
///
/// Cross-cutting across every module that displays report status (Citizen,
/// Municipal Officer, Maintenance Team, Ministry Supervisor) — lives in the
/// shared `lib/models/` location rather than a single feature module.
///
/// Maps 1:1 onto the approved Status Colors (Design System Requirements
/// §19.3) and the matching [AppIcons] status group. Per [AppSemantics],
/// color is never the sole indicator: always render [icon] and [label]
/// alongside [color].
library;

import 'package:flutter/widgets.dart';

import '../core/theme/app_theme.dart';

enum ReportStatus {
  submitted,
  underReview,
  assigned,
  inProgress,
  pendingApproval,
  resolved,
  rejected;

  static ReportStatus fromApi(String? value) {
    for (final status in values) {
      if (status.apiValue == value) return status;
    }
    throw FormatException('Unsupported report status');
  }

  bool get isClosed => this == resolved || this == rejected;

  String get label => switch (this) {
    ReportStatus.submitted => 'Submitted',
    ReportStatus.underReview => 'Under Review',
    ReportStatus.assigned => 'Assigned',
    ReportStatus.inProgress => 'In Progress',
    ReportStatus.pendingApproval => 'Awaiting Confirmation',
    ReportStatus.resolved => 'Resolved',
    ReportStatus.rejected => 'Rejected',
  };

  Color get color => switch (this) {
    ReportStatus.submitted => AppColors.statusSubmitted,
    ReportStatus.underReview => AppColors.statusUnderReview,
    ReportStatus.assigned => AppColors.statusAssigned,
    ReportStatus.inProgress => AppColors.statusInProgress,
    ReportStatus.pendingApproval => AppColors.statusPendingApproval,
    ReportStatus.resolved => AppColors.statusResolved,
    ReportStatus.rejected => AppColors.statusRejected,
  };

  IconData get icon => switch (this) {
    ReportStatus.submitted => AppIcons.statusSubmitted,
    ReportStatus.underReview => AppIcons.statusUnderReview,
    ReportStatus.assigned => AppIcons.statusAssigned,
    ReportStatus.inProgress => AppIcons.statusInProgress,
    ReportStatus.pendingApproval => AppIcons.verify,
    ReportStatus.resolved => AppIcons.statusResolved,
    ReportStatus.rejected => AppIcons.statusRejected,
  };

  int get progressPercent => switch (this) {
    ReportStatus.submitted => 15,
    ReportStatus.underReview => 30,
    ReportStatus.assigned => 50,
    ReportStatus.inProgress => 70,
    ReportStatus.pendingApproval => 90,
    ReportStatus.resolved => 100,
    ReportStatus.rejected => 100,
  };

  String get apiValue => switch (this) {
    ReportStatus.submitted => 'SUBMITTED',
    ReportStatus.underReview => 'UNDER_REVIEW',
    ReportStatus.assigned => 'ASSIGNED',
    ReportStatus.inProgress => 'IN_PROGRESS',
    ReportStatus.pendingApproval => 'PENDING_APPROVAL',
    ReportStatus.resolved => 'RESOLVED',
    ReportStatus.rejected => 'REJECTED',
  };

  /// Text color for [color] rendered on its own low-alpha tint (status
  /// badges/chips) — confirmed against MUN-001 Dashboard, both themes.
  /// [color] itself is tuned for icons/borders/full-strength use; on a
  /// tinted badge background some hues (warning amber, assigned violet,
  /// in-progress sky) need a shifted shade to hold WCAG AA contrast — darker
  /// in light mode, lighter in dark mode — so this is not simply [color].
  Color badgeTextColor(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return switch (this) {
      ReportStatus.submitted => AppColors.statusSubmitted, // AA-safe as-is
      ReportStatus.underReview =>
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
      ReportStatus.assigned =>
        isDark ? const Color(0xFFC4B5FD) : const Color(0xFF7C3AED),
      ReportStatus.inProgress =>
        isDark ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
      ReportStatus.pendingApproval =>
        isDark
            ? AppColors.statusPendingApprovalTextDark
            : AppColors.statusPendingApprovalTextLight,
      ReportStatus.resolved => AppColors.statusResolved, // AA-safe as-is
      ReportStatus.rejected => AppColors.statusRejected, // AA-safe as-is
    };
  }
}
