import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/region.dart';

/// Scope filters for the Regional Leaders list.
enum PerformanceFilter {
  all('All'),
  top10('Top 10'),
  needsAttention('Needs Attention');

  const PerformanceFilter(this.label);

  final String label;
}

/// Which series the Efficiency Trend bar chart plots.
enum EfficiencyMetric {
  response('Response'),
  resolution('Resolution');

  const EfficiencyMetric(this.label);

  final String label;
}

/// The four national performance statistics.
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

/// A genuine per-assembly performance aggregate.
class RegionalLeaderItem {
  const RegionalLeaderItem({
    required this.name,
    required this.region,
    required this.resolvedPercent,
    required this.responseTimeLabel,
    required this.officerName,
    required this.officerPhone,
    this.officers = const [],
  });

  final String name;
  final Region region;
  final int resolvedPercent;
  final String responseTimeLabel;
  final String officerName;
  final String officerPhone;
  final List<MinistryOfficerContact> officers;

  Color get rankColor {
    if (resolvedPercent >= 85) return AppColors.statusResolved;
    if (resolvedPercent >= 75) return AppColors.statusInProgress;
    return AppColors.warning;
  }

  bool get needsAttention => resolvedPercent < 75;
}

class MinistryOfficerContact {
  const MinistryOfficerContact({
    required this.publicId,
    required this.name,
    required this.phone,
  });

  final String publicId;
  final String name;
  final String phone;
}

/// Data backing MIN-003 Municipal Performance's loaded state.
///
/// Production callers provide this from genuine report aggregation. Sample
/// data belongs in test fixtures, never in this model or screen.
class MunicipalPerformanceData {
  const MunicipalPerformanceData({
    required this.stats,
    required this.regionalLeaders,
    required this.responseTrend,
    required this.resolutionTrend,
    required this.trendCaption,
    required this.hasReportData,
  });

  final MunicipalPerformanceStats stats;
  final List<RegionalLeaderItem> regionalLeaders;
  final List<int> responseTrend;
  final List<int> resolutionTrend;
  final String trendCaption;

  /// Whether this aggregate is based on at least one genuine report.
  final bool hasReportData;
}
