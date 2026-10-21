import 'package:flutter/material.dart';

import '../../../models/report_status.dart';

/// "Reporting Trends" date-range chip — same three-option shape as MIN-002
/// Analytics' own date range, default matching the approved MIN-005 frame's
/// selected "30 days" chip.
enum InsightsDateRange {
  last7Days('7 days'),
  last30Days('30 days'),
  last90Days('90 days');

  const InsightsDateRange(this.label);

  final String label;
}

/// Category quick-filter — [all]'s label ("Category") is the chip's
/// unselected placeholder text, matching the approved frame exactly; picking
/// a specific category swaps the chip's own label to that category's name.
enum InsightsCategoryFilter {
  all('Category'),
  infrastructure('Infrastructure'),
  safety('Safety'),
  sanitation('Sanitation'),
  other('Other');

  const InsightsCategoryFilter(this.label);

  final String label;
}

/// Status quick-filter — same placeholder-becomes-value chip behavior as
/// [InsightsCategoryFilter].
enum InsightsStatusFilter {
  all('Status'),
  submitted('Submitted'),
  underReview('Under Review'),
  assigned('Assigned'),
  inProgress('In Progress'),
  pendingApproval('Awaiting Confirmation'),
  resolved('Resolved'),
  rejected('Rejected');

  const InsightsStatusFilter(this.label);

  final String label;
}

/// One row in the "Critical Insights" list.
class CriticalInsightItem {
  const CriticalInsightItem({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
}

/// Data backing MIN-005 Report Insights' loaded state.
///
/// No trend chart or raw trend figure here deliberately — MIN-002 Analytics
/// Dashboard already owns that visualization (it's this screen's own entry
/// point), and the "Sanitation reports are rising +18%" entry in
/// [criticalInsights] already covers the spec's "Trend Analysis" output
/// more specifically and more usefully than a generic aggregate percentage
/// would. This screen's job is synthesis, not a second copy of Analytics'
/// charts. Current insights contain no historic comparison or AI-generated
/// narrative.
class MinistryReportInsightsData {
  const MinistryReportInsightsData({
    required this.categoryPeakLabel,
    required this.categoryPeakCount,
    required this.resolutionPercent,
    required this.statusCounts,
    required this.criticalInsights,
    required this.strategicFocusText,
  });

  final String categoryPeakLabel;
  final int categoryPeakCount;
  final int resolutionPercent;
  final Map<ReportStatus, int> statusCounts;

  final List<CriticalInsightItem> criticalInsights;
  final String strategicFocusText;

  int count(ReportStatus status) => statusCounts[status] ?? 0;

  int get totalReports => statusCounts.values.fold(0, (sum, count) => sum + count);

  int get openBacklog =>
      count(ReportStatus.submitted) +
      count(ReportStatus.underReview) +
      count(ReportStatus.assigned) +
      count(ReportStatus.inProgress) +
      count(ReportStatus.pendingApproval);
}
