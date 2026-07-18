import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The three breakdown dimensions MIN-002 Analytics Dashboard's filter chips
/// pivot the "Distribution" section between.
enum AnalyticsDimension {
  category('Category'),
  status('Status'),
  municipality('Municipality');

  const AnalyticsDimension(this.label);

  final String label;
}

/// One row in the pivoted "Distribution" section.
class AnalyticsBreakdownItem {
  const AnalyticsBreakdownItem({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;
}

/// One slice of the fixed "Report Status" donut — always Submitted/Under
/// Review/Resolved, regardless of which dimension chip is selected above
/// (that chip only pivots the Distribution section, not this fixed KPI).
class StatusSlice {
  const StatusSlice({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;
}

/// Data backing MIN-002 Analytics Dashboard's loaded state.
class MinistryAnalyticsData {
  const MinistryAnalyticsData({
    required this.dateRangeLabel,
    required this.totalReports,
    required this.totalReportsChangePercent,
    required this.resolutionRate,
    required this.resolutionRateChangePercent,
    required this.trendValues,
    required this.trendStartLabel,
    required this.trendMidLabel,
    required this.trendEndLabel,
    required this.breakdownsByDimension,
    required this.statusDistribution,
    required this.trendInsight,
  });

  final String dateRangeLabel;

  final int totalReports;
  final num totalReportsChangePercent;

  final double resolutionRate;
  final num resolutionRateChangePercent;

  /// Relative bar heights — proportions only, not absolute counts.
  final List<int> trendValues;
  final String trendStartLabel;
  final String trendMidLabel;
  final String trendEndLabel;

  final Map<AnalyticsDimension, List<AnalyticsBreakdownItem>>
  breakdownsByDimension;
  final List<StatusSlice> statusDistribution;
  final String trendInsight;

  /// Placeholder content matching the approved MIN-002 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency)
  /// is wired up.
  ///
  /// Every dimension's breakdown reads as "resolution rate within that
  /// segment" (why the approved frame's Category rows — 68/52/44 — don't
  /// sum to 100), except Status, where "share of reports currently in that
  /// status" is the only reading that isn't circular (a status's own
  /// "resolution rate" would trivially be 100% for Resolved). Municipality
  /// deliberately reuses the exact figures from MIN-001 Dashboard's
  /// Municipality Performance list, so the same entities read consistently
  /// everywhere they appear.
  static MinistryAnalyticsData mock() {
    return const MinistryAnalyticsData(
      dateRangeLabel: 'Last 30 Days',
      totalReports: 12482,
      totalReportsChangePercent: 12.5,
      resolutionRate: 74.8,
      resolutionRateChangePercent: 6.2,
      trendValues: [30, 42, 58, 34, 68, 88, 74, 52, 38],
      trendStartLabel: '01 May',
      trendMidLabel: '15 May',
      trendEndLabel: '30 May',
      breakdownsByDimension: {
        AnalyticsDimension.category: [
          AnalyticsBreakdownItem(
            label: 'Road Infrastructure',
            percent: 68,
            color: AppColors.primary,
          ),
          AnalyticsBreakdownItem(
            label: 'Sanitation',
            percent: 52,
            color: AppColors.statusInProgress,
          ),
          AnalyticsBreakdownItem(
            label: 'Water Services',
            percent: 44,
            color: AppColors.warning,
          ),
        ],
        AnalyticsDimension.status: [
          AnalyticsBreakdownItem(
            label: 'Submitted',
            percent: 45,
            color: AppColors.statusSubmitted,
          ),
          AnalyticsBreakdownItem(
            label: 'Under Review',
            percent: 25,
            color: AppColors.statusUnderReview,
          ),
          AnalyticsBreakdownItem(
            label: 'Resolved',
            percent: 30,
            color: AppColors.statusResolved,
          ),
        ],
        AnalyticsDimension.municipality: [
          AnalyticsBreakdownItem(
            label: 'Greater Accra',
            percent: 92,
            color: AppColors.primary,
          ),
          AnalyticsBreakdownItem(
            label: 'Kumasi Metro',
            percent: 86,
            color: AppColors.statusInProgress,
          ),
          AnalyticsBreakdownItem(
            label: 'Tamale Metro',
            percent: 71,
            color: AppColors.warning,
          ),
        ],
      },
      statusDistribution: [
        StatusSlice(
          label: 'Submitted',
          percent: 55,
          color: AppColors.statusSubmitted,
        ),
        StatusSlice(
          label: 'Under Review',
          percent: 15,
          color: AppColors.statusUnderReview,
        ),
        StatusSlice(
          label: 'Resolved',
          percent: 30,
          color: AppColors.statusResolved,
        ),
      ],
      trendInsight:
          'Aggregated reports increased over the last 30 days, with '
          'sanitation and infrastructure categories driving the highest '
          'review volume.',
    );
  }
}

/// Selectable presets for the date-range picker — the approved frame shows
/// "Last 30 Days" as the active selection but doesn't enumerate the other
/// options, so this uses the same preset shape as Municipal Officer's
/// existing sort/filter bottom sheets.
enum AnalyticsDateRange {
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  last90Days('Last 90 Days'),
  thisYear('This Year');

  const AnalyticsDateRange(this.label);

  final String label;
}
