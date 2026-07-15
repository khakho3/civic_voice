import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

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
  roadInfrastructure('Road Infrastructure'),
  sanitation('Sanitation'),
  waterServices('Water Services'),
  publicOrder('Public Order');

  const InsightsCategoryFilter(this.label);

  final String label;
}

/// Status quick-filter — same placeholder-becomes-value chip behavior as
/// [InsightsCategoryFilter].
enum InsightsStatusFilter {
  all('Status'),
  submitted('Submitted'),
  underReview('Under Review'),
  resolved('Resolved');

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
/// charts.
class MinistryReportInsightsData {
  const MinistryReportInsightsData({
    required this.categoryPeakLabel,
    required this.categoryPeakSharePercent,
    required this.resolutionPercent,
    required this.resolutionDeltaLabel,
    required this.criticalInsights,
    required this.strategicFocusText,
  });

  final String categoryPeakLabel;
  final int categoryPeakSharePercent;
  final int resolutionPercent;
  final String resolutionDeltaLabel;

  final List<CriticalInsightItem> criticalInsights;
  final String strategicFocusText;

  /// Placeholder content matching the approved MIN-005 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency) is
  /// wired up.
  static MinistryReportInsightsData mock() {
    return const MinistryReportInsightsData(
      categoryPeakLabel: 'Sanitation',
      categoryPeakSharePercent: 31,
      resolutionPercent: 74,
      resolutionDeltaLabel: '+6.2%',
      criticalInsights: [
        CriticalInsightItem(
          icon: AppIcons.trendUp,
          tint: AppColors.warning,
          title: 'Sanitation reports are rising',
          subtitle: '+18% from previous period',
        ),
        CriticalInsightItem(
          icon: AppIcons.pace,
          tint: AppColors.statusResolved,
          title: 'Resolution pace improved',
          subtitle: 'Average closure down 6 hours',
        ),
        CriticalInsightItem(
          icon: AppIcons.focusArea,
          tint: AppColors.primary,
          title: 'Infrastructure needs focus',
          subtitle: 'Highest backlog concentration',
        ),
      ],
      strategicFocusText:
          'Prioritize sanitation response capacity while maintaining gains '
          'in resolution time.',
    );
  }
}
