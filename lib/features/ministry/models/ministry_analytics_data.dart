import 'package:flutter/material.dart';

import '../../../models/report_status.dart';

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

/// One slice of the fixed seven-status "Report Status" donut.
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

/// Data backing MIN-002 Ministry Analytics' loaded state.
class MinistryAnalyticsData {
  const MinistryAnalyticsData({
    required this.dateRangeLabel,
    required this.totalReports,
    required this.resolutionRate,
    required this.trendValues,
    required this.trendStartLabel,
    required this.trendMidLabel,
    required this.trendEndLabel,
    required this.breakdownsByDimension,
    required this.statusCounts,
    required this.statusDistribution,
    required this.trendInsight,
  });

  final String dateRangeLabel;
  final int totalReports;
  final double resolutionRate;

  /// Relative bar heights from the selected genuine interval.
  final List<int> trendValues;
  final String trendStartLabel;
  final String trendMidLabel;
  final String trendEndLabel;

  /// Category and municipality values are segment resolution rates; status
  /// values are shares of the same selected report interval.
  final Map<AnalyticsDimension, List<AnalyticsBreakdownItem>>
  breakdownsByDimension;

  /// Complete selected-interval lifecycle aggregation, including pending
  /// approval and rejected reports.
  final Map<ReportStatus, int> statusCounts;
  final List<StatusSlice> statusDistribution;

  /// Deterministic summary derived from the selected genuine interval. I06 AI
  /// summaries are intentionally not represented by this model.
  final String trendInsight;
}

/// Selectable presets for the date-range picker.
enum AnalyticsDateRange {
  last7Days('Last 7 Days'),
  last30Days('Last 30 Days'),
  last90Days('Last 90 Days'),
  thisYear('This Year');

  const AnalyticsDateRange(this.label);

  final String label;
}
