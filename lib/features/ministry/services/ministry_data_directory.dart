import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../../../core/theme/app_theme.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import '../../municipal/models/incoming_report.dart';
import '../../municipal/services/municipal_report_directory.dart';
import '../models/ministry_analytics_data.dart';
import '../models/ministry_dashboard_data.dart';
import '../models/ministry_report_insights_data.dart';
import '../models/ministry_reports_data.dart';
import '../models/municipal_performance_data.dart';

/// National, read-only Ministry projection built from the same live reports
/// the operational modules update. This prevents dashboard, analytics,
/// reports, and performance screens from drifting into separate datasets.
class MinistryDataDirectory {
  MinistryDataDirectory._();

  static final instance = MinistryDataDirectory._();

  final ValueNotifier<int> revision = ValueNotifier(0);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final Map<String, List<MinistryOfficerContact>> _contacts = {};

  List<IncomingReportItem> get reports =>
      MunicipalReportDirectory.instance.reports.value;

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    loading.value = true;
    error.value = null;
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('A signed-in supervisor is required');
      final results = await Future.wait([
        ApiClient.instance.listReports(idToken: token),
        ApiClient.instance.listMinistryMunicipalContacts(idToken: token),
      ]);
      MunicipalReportDirectory.instance.reports.value = results[0]
          .map(IncomingReportItem.fromApi)
          .toList();
      MunicipalReportDirectory.instance.hasLiveSnapshot = true;
      _contacts.clear();
      for (final json in results[1]) {
        final region = _regionFromName(json['region'] as String?);
        final assembly = json['assembly'] as String?;
        final phone = json['phone'] as String?;
        if (region == null || assembly == null || phone == null) continue;
        _contacts
            .putIfAbsent(_key(region, assembly), () => [])
            .add(
              MinistryOfficerContact(
                publicId: json['publicId'] as String? ?? 'Municipal Officer',
                name: json['fullName'] as String? ?? 'Municipal Officer',
                phone: phone,
              ),
            );
      }
      revision.value++;
    } catch (exception) {
      error.value = exception.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  MinistryDashboardData get dashboard {
    final total = reports.length;
    final resolved = _countStatus(ReportStatus.resolved);
    final underReview = _countStatus(ReportStatus.underReview);
    final now = DateTime.now();
    final recent = reports
        .where(
          (r) => _after(r.createdAt, now.subtract(const Duration(days: 30))),
        )
        .length;
    final previous = reports.where((r) {
      final date = r.createdAt;
      return date != null &&
          date.isBefore(now.subtract(const Duration(days: 30))) &&
          date.isAfter(now.subtract(const Duration(days: 60)));
    }).length;
    return MinistryDashboardData(
      stats: MinistryDashboardStats(
        totalReports: total,
        totalReportsChangePercent: previous == 0
            ? (recent == 0 ? 0 : 100)
            : (((recent - previous) / previous) * 100).round(),
        underReview: underReview,
        underReviewPercent: _percent(underReview, total),
        resolved: resolved,
        resolvedPercent: _percent(resolved, total),
        activeMunicipalities: _assemblyGroups().length,
      ),
      reportStatistics: ReportStatistics(
        monthlyValues: _monthlyVolumes(6),
        rangeLabel: 'Last 6 months',
        totalLabel: '$total total',
      ),
      insights: QuickInsights(
        submittedPercent: _percent(_countStatus(ReportStatus.submitted), total),
        underReviewPercent: _percent(underReview, total),
        assignedPercent: _percent(_countStatus(ReportStatus.assigned), total),
        inProgressPercent: _percent(
          _countStatus(ReportStatus.inProgress),
          total,
        ),
      ),
      topMunicipalities: performance.regionalLeaders.take(3).toList(),
    );
  }

  MinistryReportsData get reportOverview => MinistryReportsData(
    stats: MinistryReportsStats(
      aggregatedReports: reports.length,
      underReview: _countStatus(ReportStatus.underReview),
      resolved: _countStatus(ReportStatus.resolved),
    ),
    reports: [
      for (final report in reports)
        ReportSummaryItem(
          title: report.title,
          municipality: _assemblyLabel(report.region, report.assembly),
          region: report.region,
          category: report.category.label,
          status: report.status,
          dateLabel: report.timeAgo,
        ),
    ],
  );

  MunicipalPerformanceData get performance {
    final groups = _assemblyGroups();
    final leaders = <RegionalLeaderItem>[];
    for (final entry in groups.entries) {
      final items = entry.value;
      final first = items.first;
      final region = first.region!;
      final assembly = first.assembly!;
      final resolved = items
          .where((r) => r.status == ReportStatus.resolved)
          .length;
      final contacts = _contacts[_key(region, assembly)] ?? const [];
      final primary = contacts.isEmpty ? null : contacts.first;
      leaders.add(
        RegionalLeaderItem(
          name: _assemblyLabel(region, assembly),
          region: region,
          resolvedPercent: _percent(resolved, items.length),
          responseTimeLabel: _averageResponse(items),
          officerName: primary?.name ?? 'No officer assigned',
          officerPhone: primary?.phone ?? '',
          officers: contacts,
        ),
      );
    }
    // Contacts must remain reachable even before their assembly receives its
    // first report.
    for (final entry in _contacts.entries) {
      final parts = entry.key.split('|');
      final region = _regionFromName(parts.first);
      final assembly = parts.length > 1 ? parts[1] : null;
      if (region == null || assembly == null || groups.containsKey(entry.key)) {
        continue;
      }
      final primary = entry.value.first;
      leaders.add(
        RegionalLeaderItem(
          name: _assemblyLabel(region, assembly),
          region: region,
          resolvedPercent: 0,
          responseTimeLabel: 'No reports',
          officerName: primary.name,
          officerPhone: primary.phone,
          officers: entry.value,
        ),
      );
    }
    leaders.sort((a, b) => b.resolvedPercent.compareTo(a.resolvedPercent));
    final resolved = _countStatus(ReportStatus.resolved);
    final completed = reports
        .where(
          (r) =>
              r.status == ReportStatus.resolved &&
              r.createdAt != null &&
              r.updatedAt != null,
        )
        .toList();
    final withinSla = completed
        .where((r) => r.updatedAt!.difference(r.createdAt!).inHours <= 48)
        .length;
    return MunicipalPerformanceData(
      stats: MunicipalPerformanceStats(
        avgResponseLabel: _averageResponse(reports),
        resolutionPercent: _percent(resolved, reports.length),
        slaMetPercent: _percent(withinSla, completed.length),
        backlogLabel: '${reports.length - resolved}',
      ),
      regionalLeaders: leaders,
      responseTrend: _dailyVolumes(7, resolvedOnly: false),
      resolutionTrend: _dailyVolumes(7, resolvedOnly: true),
      trendCaption: 'Last 7 days · live national reports',
    );
  }

  MinistryAnalyticsData get analytics =>
      _buildAnalytics(reports, 'All live reports');

  MinistryAnalyticsData analyticsFor(AnalyticsDateRange range) {
    final days = switch (range) {
      AnalyticsDateRange.last7Days => 7,
      AnalyticsDateRange.last30Days => 30,
      AnalyticsDateRange.last90Days => 90,
      AnalyticsDateRange.thisYear =>
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays + 1,
    };
    return _buildAnalytics(_reportsSince(days), range.label);
  }

  MinistryAnalyticsData _buildAnalytics(
    List<IncomingReportItem> source,
    String rangeLabel,
  ) {
    final total = source.length;
    int count(ReportStatus status) =>
        source.where((r) => r.status == status).length;
    final resolved = count(ReportStatus.resolved);
    final categoryGroups = <String, List<IncomingReportItem>>{};
    for (final report in source) {
      categoryGroups.putIfAbsent(report.category.label, () => []).add(report);
    }
    final categoryBreakdown =
        categoryGroups.entries
            .map(
              (entry) => AnalyticsBreakdownItem(
                label: entry.key,
                percent: _percent(
                  entry.value
                      .where((r) => r.status == ReportStatus.resolved)
                      .length,
                  entry.value.length,
                ),
                color: _colorForIndex(
                  categoryGroups.keys.toList().indexOf(entry.key),
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.percent.compareTo(a.percent));
    final municipalityGroups = _assemblyGroupsFor(source);
    final municipalityBreakdown = municipalityGroups.values.map((items) {
      final first = items.first;
      final rate = _percent(
        items.where((r) => r.status == ReportStatus.resolved).length,
        items.length,
      );
      return AnalyticsBreakdownItem(
        label: _assemblyLabel(first.region, first.assembly),
        percent: rate,
        color: rate >= 85
            ? AppColors.statusResolved
            : rate >= 75
            ? AppColors.statusInProgress
            : AppColors.warning,
      );
    }).toList()..sort((a, b) => b.percent.compareTo(a.percent));
    final statusItems = ReportStatus.values.map((status) {
      final statusCount = count(status);
      return AnalyticsBreakdownItem(
        label: status.label,
        percent: _percent(statusCount, total),
        color: status.color,
      );
    }).toList();
    return MinistryAnalyticsData(
      dateRangeLabel: rangeLabel,
      totalReports: total,
      totalReportsChangePercent: 0,
      resolutionRate: _percent(resolved, total).toDouble(),
      resolutionRateChangePercent: 0,
      trendValues: _dailyVolumesFor(source, 9, resolvedOnly: false),
      trendStartLabel: '8 days ago',
      trendMidLabel: '4 days ago',
      trendEndLabel: 'Today',
      breakdownsByDimension: {
        AnalyticsDimension.category: categoryBreakdown,
        AnalyticsDimension.status: statusItems,
        AnalyticsDimension.municipality: municipalityBreakdown,
      },
      statusDistribution: [
        for (final status in ReportStatus.values)
          StatusSlice(
            label: status.label,
            percent: _percent(count(status), total),
            color: status.color,
          ),
      ],
      trendInsight: total == 0
          ? 'No national report activity is available yet.'
          : '$resolved of $total reports are resolved nationally. Performance updates automatically as municipalities and maintenance teams work reports.',
    );
  }

  MinistryReportInsightsData get insights => _buildInsights(reports);

  MinistryReportInsightsData insightsFor({
    required InsightsDateRange dateRange,
    required InsightsCategoryFilter category,
    required InsightsStatusFilter status,
  }) {
    final days = switch (dateRange) {
      InsightsDateRange.last7Days => 7,
      InsightsDateRange.last30Days => 30,
      InsightsDateRange.last90Days => 90,
    };
    final source = _reportsSince(days).where((report) {
      final categoryMatches =
          category == InsightsCategoryFilter.all ||
          report.category.name == category.name;
      final statusMatches =
          status == InsightsStatusFilter.all ||
          report.status.name == status.name;
      return categoryMatches && statusMatches;
    }).toList();
    return _buildInsights(source);
  }

  MinistryReportInsightsData _buildInsights(List<IncomingReportItem> source) {
    final groups = <String, int>{};
    for (final report in source) {
      groups.update(
        report.category.label,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final sorted = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final peak = sorted.isEmpty
        ? const MapEntry('No category data', 0)
        : sorted.first;
    final resolution = _percent(
      source.where((r) => r.status == ReportStatus.resolved).length,
      source.length,
    );
    final backlog = source
        .where(
          (r) =>
              r.status != ReportStatus.resolved &&
              r.status != ReportStatus.rejected,
        )
        .length;
    return MinistryReportInsightsData(
      categoryPeakLabel: peak.key,
      categoryPeakSharePercent: _percent(peak.value, source.length),
      resolutionPercent: resolution,
      resolutionDeltaLabel: 'Live',
      criticalInsights: [
        CriticalInsightItem(
          icon: AppIcons.focusArea,
          tint: AppColors.warning,
          title: '${peak.key} has the highest report volume',
          subtitle: '${peak.value} national reports',
        ),
        CriticalInsightItem(
          icon: AppIcons.pace,
          tint: AppColors.statusResolved,
          title: '$resolution% national resolution rate',
          subtitle:
              '${source.where((r) => r.status == ReportStatus.resolved).length} reports completed',
        ),
        CriticalInsightItem(
          icon: AppIcons.statusUnderReview,
          tint: AppColors.primary,
          title: '$backlog reports remain active',
          subtitle: 'Submitted through in-progress workload',
        ),
      ],
      strategicFocusText: source.isEmpty
          ? 'No reports match the selected filters.'
          : 'Prioritize $peak while supporting assemblies with resolution rates below 75%.',
    );
  }

  Map<String, List<IncomingReportItem>> _assemblyGroups() =>
      _assemblyGroupsFor(reports);

  Map<String, List<IncomingReportItem>> _assemblyGroupsFor(
    Iterable<IncomingReportItem> source,
  ) {
    final groups = <String, List<IncomingReportItem>>{};
    for (final report in source) {
      if (report.region == null || report.assembly == null) continue;
      groups
          .putIfAbsent(_key(report.region!, report.assembly!), () => [])
          .add(report);
    }
    return groups;
  }

  List<IncomingReportItem> _reportsSince(int days) {
    final boundary = DateTime.now().subtract(Duration(days: days));
    return reports
        .where((report) => _after(report.createdAt, boundary))
        .toList();
  }

  int _countStatus(ReportStatus status) =>
      reports.where((r) => r.status == status).length;
  int _percent(num value, num total) =>
      total == 0 ? 0 : ((value / total) * 100).round().clamp(0, 100);
  bool _after(DateTime? value, DateTime boundary) =>
      value != null && value.isAfter(boundary);

  List<int> _monthlyVolumes(int months) {
    final now = DateTime.now();
    final counts = List<int>.filled(months, 0);
    for (final report in reports) {
      final date = report.createdAt;
      if (date == null) continue;
      final distance = (now.year - date.year) * 12 + now.month - date.month;
      if (distance >= 0 && distance < months) counts[months - 1 - distance]++;
    }
    return _normalize(counts);
  }

  List<int> _dailyVolumes(int days, {required bool resolvedOnly}) {
    return _dailyVolumesFor(reports, days, resolvedOnly: resolvedOnly);
  }

  List<int> _dailyVolumesFor(
    Iterable<IncomingReportItem> source,
    int days, {
    required bool resolvedOnly,
  }) {
    final today = DateTime.now();
    final counts = List<int>.filled(days, 0);
    for (final report in source) {
      if (resolvedOnly && report.status != ReportStatus.resolved) continue;
      final date = resolvedOnly ? report.updatedAt : report.createdAt;
      if (date == null) continue;
      final distance = DateTime(
        today.year,
        today.month,
        today.day,
      ).difference(DateTime(date.year, date.month, date.day)).inDays;
      if (distance >= 0 && distance < days) counts[days - 1 - distance]++;
    }
    return _normalize(counts);
  }

  List<int> _normalize(List<int> values) {
    final maximum = values.fold<int>(0, math.max);
    if (maximum == 0) return List<int>.filled(values.length, 0);
    return values.map((value) => ((value / maximum) * 100).round()).toList();
  }

  String _averageResponse(Iterable<IncomingReportItem> items) {
    final hours = <int>[];
    for (final report in items) {
      if (report.createdAt == null) continue;
      final end = report.reviewedAt ?? report.updatedAt;
      if (end != null) {
        hours.add(math.max(0, end.difference(report.createdAt!).inHours));
      }
    }
    if (hours.isEmpty) return 'Pending';
    return '${(hours.reduce((a, b) => a + b) / hours.length).round()}h';
  }

  String _assemblyLabel(Region? region, String? assembly) {
    if (assembly == null || assembly.trim().isEmpty) {
      return 'Assembly unassigned';
    }
    if (region != null) {
      for (final item in ghanaAssemblies[region] ?? const []) {
        if (item.name == assembly) return item.fullName;
      }
    }
    return assembly;
  }

  String _key(Region region, String assembly) => '${region.name}|$assembly';
  Region? _regionFromName(String? value) {
    for (final region in Region.values) {
      if (region.name == value) return region;
    }
    return null;
  }

  static const _colors = [
    AppColors.primary,
    AppColors.statusInProgress,
    AppColors.warning,
    AppColors.statusResolved,
    AppColors.statusAssigned,
    AppColors.statusRejected,
  ];
  Color _colorForIndex(int index) => _colors[index % _colors.length];
}
