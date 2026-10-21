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
///
/// A [loaded] state, including an empty report list, is a complete server
/// response. [unavailable] means that no such response has been confirmed.
/// [failed] retains the most recent confirmed snapshot when one exists.
enum MinistryDataDirectoryState { unavailable, loading, loaded, failed }

class MinistryDataDirectory {
  MinistryDataDirectory._({
    bool Function()? firebaseAvailable,
    Future<String?> Function()? tokenProvider,
    Future<List<Map<String, dynamic>>> Function(String token)? reportsFetcher,
    Future<List<Map<String, dynamic>>> Function(String token)? contactsFetcher,
    ValueNotifier<List<IncomingReportItem>>? reportsNotifier,
    void Function(bool hasLiveSnapshot)? sourceSnapshotPublisher,
  }) : _firebaseAvailable = firebaseAvailable ?? (() => Firebase.apps.isNotEmpty),
       _tokenProvider = tokenProvider ?? _firebaseIdToken,
       _reportsFetcher = reportsFetcher ??
           ((token) => ApiClient.instance.listReports(idToken: token)),
       _contactsFetcher = contactsFetcher ??
           ((token) =>
               ApiClient.instance.listMinistryMunicipalContacts(idToken: token)),
       _reportsNotifier =
           reportsNotifier ?? MunicipalReportDirectory.instance.reports,
       _sourceSnapshotPublisher = sourceSnapshotPublisher ??
           ((hasLiveSnapshot) =>
               MunicipalReportDirectory.instance.hasLiveSnapshot =
                   hasLiveSnapshot);

  static final instance = MinistryDataDirectory._();

  static Future<String?> _firebaseIdToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return currentUser.getIdToken();
  }

  /// Isolated request hooks for deterministic directory tests. Production
  /// always uses Firebase plus the approved Ministry endpoints; this
  /// constructor cannot provide a production fallback dataset.
  @visibleForTesting
  factory MinistryDataDirectory.forTesting({
    required bool Function() firebaseAvailable,
    required Future<String?> Function() tokenProvider,
    required Future<List<Map<String, dynamic>>> Function(String token)
    reportsFetcher,
    required Future<List<Map<String, dynamic>>> Function(String token)
    contactsFetcher,
    required ValueNotifier<List<IncomingReportItem>> reportsNotifier,
  }) => MinistryDataDirectory._(
    firebaseAvailable: firebaseAvailable,
    tokenProvider: tokenProvider,
    reportsFetcher: reportsFetcher,
    contactsFetcher: contactsFetcher,
    reportsNotifier: reportsNotifier,
    sourceSnapshotPublisher: (_) {},
  );

  final bool Function() _firebaseAvailable;
  final Future<String?> Function() _tokenProvider;
  final Future<List<Map<String, dynamic>>> Function(String token)
  _reportsFetcher;
  final Future<List<Map<String, dynamic>>> Function(String token)
  _contactsFetcher;
  final ValueNotifier<List<IncomingReportItem>> _reportsNotifier;
  final void Function(bool hasLiveSnapshot) _sourceSnapshotPublisher;

  final ValueNotifier<int> revision = ValueNotifier(0);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<MinistryDataDirectoryState> state = ValueNotifier(
    MinistryDataDirectoryState.unavailable,
  );
  final Map<String, List<MinistryOfficerContact>> _contacts = {};

  /// This provenance belongs specifically to a complete Ministry refresh.
  /// A local report mutation or a partial list must not establish it.
  bool hasLiveSnapshot = false;

  /// A session generation fences in-flight reads after [clearSession].
  int _sessionRevision = 0;

  /// Last-started read wins. A later read or session clear prevents older
  /// responses from changing reports, contacts, state, errors, or loading.
  int _refreshRevision = 0;

  List<IncomingReportItem> get reports => _reportsNotifier.value;

  bool _isCurrent(int session, int refresh) =>
      session == _sessionRevision && refresh == _refreshRevision;

  void _publishFailure(int session, int refresh, Object exception) {
    if (!_isCurrent(session, refresh)) return;
    error.value = exception.toString();
    state.value = hasLiveSnapshot
        ? MinistryDataDirectoryState.failed
        : MinistryDataDirectoryState.unavailable;
  }

  Future<void> refresh() async {
    final session = _sessionRevision;
    final refresh = ++_refreshRevision;
    loading.value = true;
    state.value = MinistryDataDirectoryState.loading;
    error.value = null;
    try {
      if (!_firebaseAvailable()) {
        throw StateError('Ministry data is unavailable without Firebase');
      }
      final token = await _tokenProvider();
      if (!_isCurrent(session, refresh)) return;
      if (token == null) throw StateError('A signed-in supervisor is required');
      final results = await Future.wait([
        _reportsFetcher(token),
        _contactsFetcher(token),
      ]);
      // Parse both endpoint responses before publishing either one. A report
      // list and its municipal contacts are one Ministry snapshot.
      final fetchedReports = results[0].map(IncomingReportItem.fromApi).toList();
      final fetchedContacts = <String, List<MinistryOfficerContact>>{};
      for (final json in results[1]) {
        final region = _regionFromName(json['region'] as String?);
        final assembly = json['assembly'] as String?;
        final phone = json['phone'] as String?;
        if (region == null || assembly == null || phone == null) continue;
        fetchedContacts
            .putIfAbsent(_key(region, assembly), () => [])
            .add(
              MinistryOfficerContact(
                publicId: json['publicId'] as String? ?? 'Municipal Officer',
                name: json['fullName'] as String? ?? 'Municipal Officer',
                phone: phone,
              ),
            );
      }
      if (!_isCurrent(session, refresh)) return;
      _contacts
        ..clear()
        ..addAll(fetchedContacts);
      hasLiveSnapshot = true;
      _sourceSnapshotPublisher(true);
      // The report notifier is the shared projection's visible publication
      // point. Update contacts first so synchronous listeners never observe
      // new reports paired with contacts from the previous snapshot.
      _reportsNotifier.value = fetchedReports;
      state.value = MinistryDataDirectoryState.loaded;
      error.value = null;
      revision.value++;
    } catch (exception) {
      _publishFailure(session, refresh, exception);
      rethrow;
    } finally {
      if (_isCurrent(session, refresh)) loading.value = false;
    }
  }

  void clearSession() {
    ++_sessionRevision;
    ++_refreshRevision;
    _reportsNotifier.value = const <IncomingReportItem>[];
    _sourceSnapshotPublisher(false);
    hasLiveSnapshot = false;
    _contacts.clear();
    error.value = null;
    loading.value = false;
    state.value = MinistryDataDirectoryState.unavailable;
    revision.value++;
  }

  MinistryDashboardData get dashboard {
    final statusCounts = <ReportStatus, int>{
      for (final status in ReportStatus.values) status: _countStatus(status),
    };
    final total = statusCounts.values.fold(0, (sum, value) => sum + value);
    return MinistryDashboardData(
      stats: MinistryDashboardStats(
        statusCounts: statusCounts,
        activeMunicipalities: _assemblyGroups().length,
      ),
      reportStatistics: ReportStatistics(
        monthlyValues: _monthlyVolumes(6),
        rangeLabel: 'Last 6 months',
        totalLabel: '$total total',
      ),
      insights: QuickInsights(statusCounts: statusCounts),
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
      hasReportData: reports.isNotEmpty,
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
    return _buildAnalytics(_reportsSince(days), range.label, range: range);
  }

  MinistryAnalyticsData _buildAnalytics(
    List<IncomingReportItem> source,
    String rangeLabel, {
    AnalyticsDateRange? range,
  }) {
    final total = source.length;
    int count(ReportStatus status) =>
        source.where((r) => r.status == status).length;
    final statusCounts = <ReportStatus, int>{
      for (final status in ReportStatus.values) status: count(status),
    };
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
    final trend = _analyticsTrend(source, range);
    return MinistryAnalyticsData(
      dateRangeLabel: rangeLabel,
      totalReports: total,
      resolutionRate: _percent(resolved, total).toDouble(),
      trendValues: trend.values,
      trendStartLabel: trend.startLabel,
      trendMidLabel: trend.midLabel,
      trendEndLabel: trend.endLabel,
      breakdownsByDimension: {
        AnalyticsDimension.category: categoryBreakdown,
        AnalyticsDimension.status: statusItems,
        AnalyticsDimension.municipality: municipalityBreakdown,
      },
      statusCounts: statusCounts,
      statusDistribution: [
        for (final status in ReportStatus.values)
          StatusSlice(
            label: status.label,
            percent: _percent(statusCounts[status]!, total),
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
    final statusCounts = <ReportStatus, int>{
      for (final status in ReportStatus.values)
        status: source.where((report) => report.status == status).length,
    };
    if (source.isEmpty) {
      return MinistryReportInsightsData(
        categoryPeakLabel: '',
        categoryPeakCount: 0,
        resolutionPercent: 0,
        statusCounts: statusCounts,
        criticalInsights: const [],
        strategicFocusText: '',
      );
    }
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
    final peak = sorted.first;
    final resolution = _percent(
      source.where((r) => r.status == ReportStatus.resolved).length,
      source.length,
    );
    final backlog =
        statusCounts[ReportStatus.submitted]! +
        statusCounts[ReportStatus.underReview]! +
        statusCounts[ReportStatus.assigned]! +
        statusCounts[ReportStatus.inProgress]! +
        statusCounts[ReportStatus.pendingApproval]!;
    return MinistryReportInsightsData(
      categoryPeakLabel: peak.key,
      categoryPeakCount: peak.value,
      resolutionPercent: resolution,
      statusCounts: statusCounts,
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
          title: '$backlog reports are in the open backlog',
          subtitle:
              'Submitted, Under Review, Assigned, In Progress, and Awaiting Confirmation',
        ),
      ],
      strategicFocusText:
          '${peak.key} has the highest report volume in the selected reports.',
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

  _AnalyticsTrend _analyticsTrend(
    Iterable<IncomingReportItem> source,
    AnalyticsDateRange? range,
  ) {
    return switch (range) {
      AnalyticsDateRange.last7Days => _periodTrend(
        source,
        days: 7,
        bucketDays: 1,
      ),
      AnalyticsDateRange.last30Days => _periodTrend(
        source,
        days: 30,
        bucketDays: 5,
      ),
      AnalyticsDateRange.last90Days => _periodTrend(
        source,
        days: 90,
        bucketDays: 15,
      ),
      AnalyticsDateRange.thisYear => _yearTrend(source),
      null => _allHistoryTrend(source),
    };
  }

  _AnalyticsTrend _periodTrend(
    Iterable<IncomingReportItem> source, {
    required int days,
    required int bucketDays,
  }) {
    final today = DateTime.now();
    final bucketCount = (days / bucketDays).ceil();
    final counts = List<int>.filled(bucketCount, 0);
    for (final report in source) {
      final date = report.createdAt;
      if (date == null) continue;
      final distance = _dayDistance(today, date);
      if (distance < 0 || distance >= days) continue;
      counts[bucketCount - 1 - (distance ~/ bucketDays)]++;
    }
    return _AnalyticsTrend(
      values: _normalize(counts),
      startLabel: _daysAgoLabel(days - 1),
      midLabel: _daysAgoLabel((days - 1) ~/ 2),
      endLabel: 'Today',
    );
  }

  _AnalyticsTrend _yearTrend(Iterable<IncomingReportItem> source) {
    final now = DateTime.now();
    final counts = List<int>.filled(now.month, 0);
    for (final report in source) {
      final date = report.createdAt;
      if (date == null || date.year != now.year || date.month > now.month) {
        continue;
      }
      counts[date.month - 1]++;
    }
    return _AnalyticsTrend(
      values: _normalize(counts),
      startLabel: _monthLabel(1),
      midLabel: _monthLabel(((now.month - 1) ~/ 2) + 1),
      endLabel: _monthLabel(now.month),
    );
  }

  _AnalyticsTrend _allHistoryTrend(Iterable<IncomingReportItem> source) {
    final now = DateTime.now();
    final dates = source
        .map((report) => report.createdAt)
        .whereType<DateTime>()
        .where((date) => _dayDistance(now, date) >= 0)
        .toList();
    if (dates.isEmpty) {
      return const _AnalyticsTrend(
        values: [0],
        startLabel: 'No activity',
        midLabel: 'No activity',
        endLabel: 'Today',
      );
    }
    dates.sort();
    final days = _dayDistance(now, dates.first) + 1;
    final bucketDays = math.max(1, (days / 6).ceil());
    final bucketCount = (days / bucketDays).ceil();
    final counts = List<int>.filled(bucketCount, 0);
    for (final date in dates) {
      final distance = _dayDistance(now, date);
      counts[bucketCount - 1 - (distance ~/ bucketDays)]++;
    }
    return _AnalyticsTrend(
      values: _normalize(counts),
      startLabel: _shortDate(dates.first),
      midLabel: _shortDate(
        DateTime(now.year, now.month, now.day).subtract(
          Duration(days: (days - 1) ~/ 2),
        ),
      ),
      endLabel: 'Today',
    );
  }

  int _dayDistance(DateTime from, DateTime to) =>
      DateTime(from.year, from.month, from.day)
          .difference(DateTime(to.year, to.month, to.day))
          .inDays;

  String _daysAgoLabel(int days) => days == 0 ? 'Today' : '$days days ago';

  String _monthLabel(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  String _shortDate(DateTime date) => '${_monthLabel(date.month)} ${date.day}';

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

class _AnalyticsTrend {
  const _AnalyticsTrend({
    required this.values,
    required this.startLabel,
    required this.midLabel,
    required this.endLabel,
  });

  final List<int> values;
  final String startLabel;
  final String midLabel;
  final String endLabel;
}
