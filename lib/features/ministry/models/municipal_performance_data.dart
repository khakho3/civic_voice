import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Scope filters for the "Regional Leaders" list — single-select, matching
/// the approved frame's chip row.
enum PerformanceFilter {
  all('All'),
  top10('Top 10'),
  regions('Regions'),
  thisMonth('This Month');

  const PerformanceFilter(this.label);

  final String label;
}

/// Which series the "Efficiency Trend" bar chart plots.
enum EfficiencyMetric {
  response('Response'),
  resolution('Resolution');

  const EfficiencyMetric(this.label);

  final String label;
}

/// The four National Summary-style stat cards.
class MunicipalPerformanceStats {
  const MunicipalPerformanceStats({
    required this.avgResponseLabel,
    required this.resolutionPercent,
    required this.slaMetPercent,
    required this.backlogLabel,
  });

  final String avgResponseLabel;
  final int resolutionPercent;
  final int slaMetPercent;
  final String backlogLabel;
}

/// One row in the "Regional Leaders" list.
class RegionalLeaderItem {
  const RegionalLeaderItem({
    required this.name,
    required this.resolvedPercent,
    required this.responseTimeLabel,
    required this.rankColor,
  });

  final String name;
  final int resolvedPercent;
  final String responseTimeLabel;
  final Color rankColor;
}

/// Data backing MIN-003 Municipal Performance's loaded state.
class MunicipalPerformanceData {
  const MunicipalPerformanceData({
    required this.stats,
    required this.regionalLeaders,
    required this.responseTrend,
    required this.resolutionTrend,
    required this.trendCaption,
  });

  final MunicipalPerformanceStats stats;

  /// Same three entities and figures shown on MIN-001 Dashboard's
  /// Municipality Performance list, so the same municipalities read
  /// consistently everywhere they appear.
  ///
  /// The chip row above (All/Top 10/Regions/This Month) is genuinely
  /// interactive — it toggles which chip is selected — but doesn't reshape
  /// this specific list further: with only three placeholder municipalities
  /// (matching Dashboard's own mock dataset), "Top 10" vs "All" has nothing
  /// real to differentiate until there's a live backend with more than a
  /// handful of municipalities to page through.
  final List<RegionalLeaderItem> regionalLeaders;

  /// Relative bar heights — proportions only, not absolute counts.
  final List<int> responseTrend;
  final List<int> resolutionTrend;
  final String trendCaption;

  /// Placeholder content matching the approved MIN-003 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency)
  /// is wired up.
  static MunicipalPerformanceData mock() {
    return const MunicipalPerformanceData(
      stats: MunicipalPerformanceStats(
        avgResponseLabel: '18h',
        resolutionPercent: 76,
        slaMetPercent: 84,
        backlogLabel: '1.2K',
      ),
      regionalLeaders: [
        RegionalLeaderItem(
          name: 'Greater Accra',
          resolvedPercent: 92,
          responseTimeLabel: '14h',
          rankColor: AppColors.statusResolved,
        ),
        RegionalLeaderItem(
          name: 'Kumasi Metro',
          resolvedPercent: 86,
          responseTimeLabel: '18h',
          rankColor: AppColors.statusInProgress,
        ),
        RegionalLeaderItem(
          name: 'Tamale Metro',
          resolvedPercent: 71,
          responseTimeLabel: '26h',
          rankColor: AppColors.warning,
        ),
      ],
      responseTrend: [46, 62, 54, 88, 66, 40, 28],
      resolutionTrend: [58, 70, 64, 92, 78, 52, 44],
      trendCaption: 'Last 7 reporting periods · aggregated only',
    );
  }
}
