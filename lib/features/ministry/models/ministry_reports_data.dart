import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Report status — the full canonical six-value taxonomy (shared with
/// MIN-002 Analytics' "Status Distribution" breakdown), reusing the same
/// [AppColors]/[AppIcons] status tokens so a given status reads identically
/// everywhere it appears across the Ministry module.
enum ReportStatus {
  submitted('Submitted', AppColors.statusSubmitted, AppIcons.statusSubmitted),
  underReview(
    'Under Review',
    AppColors.statusUnderReview,
    AppIcons.statusUnderReview,
  ),
  assigned('Assigned', AppColors.statusAssigned, AppIcons.statusAssigned),
  inProgress(
    'In Progress',
    AppColors.statusInProgress,
    AppIcons.statusInProgress,
  ),
  resolved('Resolved', AppColors.statusResolved, AppIcons.statusResolved),
  rejected('Rejected', AppColors.statusRejected, AppIcons.statusRejected);

  const ReportStatus(this.label, this.color, this.icon);

  final String label;
  final Color color;
  final IconData icon;
}

/// Status filter chips — a coarser 4-way bucket ("All/Submitted/Review/
/// Resolved") than the full six-value [ReportStatus] taxonomy, matching the
/// approved MIN-004 frame's chip row exactly. [review] maps only to
/// [ReportStatus.underReview] (not also Assigned/In Progress) since that's
/// the specific bucket the approved frame's own "Under Review" stat card
/// counts — Assigned/In Progress/Rejected reports remain visible under
/// [all] without a dedicated chip of their own.
enum ReportStatusFilter {
  all('All'),
  submitted('Submitted'),
  review('Review'),
  resolved('Resolved');

  const ReportStatusFilter(this.label);

  final String label;

  bool matches(ReportStatus status) => switch (this) {
    ReportStatusFilter.all => true,
    ReportStatusFilter.submitted => status == ReportStatus.submitted,
    ReportStatusFilter.review => status == ReportStatus.underReview,
    ReportStatusFilter.resolved => status == ReportStatus.resolved,
  };
}

/// One row in the "Report Summary Cards" list.
class ReportSummaryItem {
  const ReportSummaryItem({
    required this.title,
    required this.municipality,
    required this.category,
    required this.status,
    required this.dateLabel,
  });

  final String title;
  final String municipality;
  final String category;
  final ReportStatus status;

  /// Precomputed relative-time text (e.g. "2 days ago") — mock data, so
  /// there's no live `DateTime` to format against.
  final String dateLabel;

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        municipality.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q);
  }
}

/// The "Aggregated Reports" stat row figures.
class MinistryReportsStats {
  const MinistryReportsStats({
    required this.aggregatedReports,
    required this.underReview,
    required this.resolved,
  });

  final int aggregatedReports;
  final int underReview;
  final int resolved;
}

/// Data backing MIN-004 Reports Overview's loaded state.
class MinistryReportsData {
  const MinistryReportsData({required this.stats, required this.reports});

  final MinistryReportsStats stats;
  final List<ReportSummaryItem> reports;

  /// Placeholder content matching the approved MIN-004 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency) is
  /// wired up. [MinistryReportsStats.aggregatedReports] deliberately matches
  /// MIN-002 Analytics Dashboard's own "Total Reports" figure — both screens
  /// report the same national all-reports aggregate, just sliced
  /// differently, so they should agree with each other the way they would
  /// against a real shared backend.
  static MinistryReportsData mock() {
    return const MinistryReportsData(
      stats: MinistryReportsStats(
        aggregatedReports: 24812,
        underReview: 3248,
        resolved: 18604,
      ),
      reports: [
        ReportSummaryItem(
          title: 'Pothole on Main Street',
          municipality: 'Accra Municipal',
          category: 'Road Infrastructure',
          status: ReportStatus.submitted,
          dateLabel: '2 days ago',
        ),
        ReportSummaryItem(
          title: 'Broken Streetlight',
          municipality: 'Kumasi Metro',
          category: 'Utilities',
          status: ReportStatus.resolved,
          dateLabel: '5 days ago',
        ),
        ReportSummaryItem(
          title: 'Overflowing Drainage',
          municipality: 'Tamale Metro',
          category: 'Sanitation',
          status: ReportStatus.underReview,
          dateLabel: '1 day ago',
        ),
        ReportSummaryItem(
          title: 'Illegal Dumping Site',
          municipality: 'Accra Municipal',
          category: 'Sanitation',
          status: ReportStatus.assigned,
          dateLabel: '3 days ago',
        ),
        ReportSummaryItem(
          title: 'Water Supply Interruption',
          municipality: 'Kumasi Metro',
          category: 'Water Services',
          status: ReportStatus.inProgress,
          dateLabel: '6 hours ago',
        ),
        ReportSummaryItem(
          title: 'Damaged Footbridge',
          municipality: 'Tamale Metro',
          category: 'Road Infrastructure',
          status: ReportStatus.resolved,
          dateLabel: '1 week ago',
        ),
        ReportSummaryItem(
          title: 'Noise Complaint - Construction',
          municipality: 'Accra Municipal',
          category: 'Public Order',
          status: ReportStatus.rejected,
          dateLabel: '4 days ago',
        ),
      ],
    );
  }
}
