import 'package:civic_voice/features/ministry/models/ministry_analytics_data.dart';
import 'package:civic_voice/features/ministry/models/ministry_report_insights_data.dart';
import 'package:civic_voice/features/ministry/services/ministry_data_directory.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<IncomingReportItem> previous;

  setUp(() {
    previous = MunicipalReportDirectory.instance.reports.value;
    final now = DateTime.now();
    MunicipalReportDirectory.instance.reports.value = [
      IncomingReportItem(
        referenceId: 'CV-LIVE-1',
        title: 'Resolved drain',
        description: '',
        locationLabel: 'Accra',
        category: ReportCategory.sanitation,
        status: ReportStatus.resolved,
        timeAgo: 'Today',
        region: Region.greaterAccra,
        assembly: 'Accra',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      IncomingReportItem(
        referenceId: 'CV-LIVE-2',
        title: 'Open road issue',
        description: '',
        locationLabel: 'Kumasi',
        category: ReportCategory.infrastructure,
        status: ReportStatus.inProgress,
        timeAgo: 'Today',
        region: Region.ashanti,
        assembly: 'Kumasi',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      IncomingReportItem(
        referenceId: 'CV-OLD-1',
        title: 'Old safety report',
        description: '',
        locationLabel: 'Accra',
        category: ReportCategory.safety,
        status: ReportStatus.rejected,
        timeAgo: 'Old',
        region: Region.greaterAccra,
        assembly: 'Accra',
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 118)),
      ),
    ];
  });

  tearDown(() {
    MunicipalReportDirectory.instance.reports.value = previous;
  });

  test('all ministry surfaces derive from the shared live report snapshot', () {
    final directory = MinistryDataDirectory.instance;
    final reports = directory.reportOverview;

    expect(directory.dashboard.stats.totalReports, 3);
    expect(reports.stats.aggregatedReports, 3);
    expect(reports.stats.resolved, 1);
    expect(reports.reports, hasLength(3));
    expect(reports.reports.map((report) => report.status), containsAll(<ReportStatus>[
      ReportStatus.resolved,
      ReportStatus.inProgress,
      ReportStatus.rejected,
    ]));
    expect(directory.performance.regionalLeaders, hasLength(2));
    expect(directory.performance.hasReportData, isTrue);
    expect(directory.insights.resolutionPercent, 33);
  });

  test('analytics date range and insights filters change their data', () {
    final directory = MinistryDataDirectory.instance;

    final last7 = directory.analyticsFor(AnalyticsDateRange.last7Days);
    expect(last7.totalReports, 2);
    expect(last7.trendValues, [0, 100, 0, 0, 100, 0, 0]);
    expect(last7.trendStartLabel, '6 days ago');
    expect(last7.trendMidLabel, '3 days ago');
    expect(last7.trendEndLabel, 'Today');

    final last30 = directory.analyticsFor(AnalyticsDateRange.last30Days);
    expect(last30.trendValues, [0, 0, 0, 0, 100, 100]);
    expect(last30.trendStartLabel, '29 days ago');
    expect(last30.trendMidLabel, '14 days ago');
    expect(last30.trendEndLabel, 'Today');

    final last90 = directory.analyticsFor(AnalyticsDateRange.last90Days);
    expect(last90.trendValues, hasLength(6));
    expect(last90.trendStartLabel, '89 days ago');
    expect(last90.trendMidLabel, '44 days ago');
    expect(last90.trendEndLabel, 'Today');

    final thisYear = directory.analyticsFor(AnalyticsDateRange.thisYear);
    const monthLabels = [
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
    ];
    expect(thisYear.trendValues, hasLength(DateTime.now().month));
    expect(thisYear.trendStartLabel, 'Jan');
    expect(thisYear.trendEndLabel, monthLabels[DateTime.now().month - 1]);

    final filtered = directory.insightsFor(
      dateRange: InsightsDateRange.last7Days,
      category: InsightsCategoryFilter.sanitation,
      status: InsightsStatusFilter.resolved,
    );
    expect(filtered.categoryPeakLabel, 'Sanitation');
    expect(filtered.resolutionPercent, 100);
  });

  test('analytics empty periods retain their real zero activity', () {
    final reports = MunicipalReportDirectory.instance.reports.value;
    MunicipalReportDirectory.instance.reports.value = [reports.last];

    final analytics = MinistryDataDirectory.instance.analyticsFor(
      AnalyticsDateRange.last7Days,
    );

    expect(analytics.totalReports, 0);
    expect(analytics.trendValues, everyElement(0));
    expect(analytics.trendStartLabel, '6 days ago');
    expect(analytics.trendEndLabel, 'Today');
  });

  test('analytics preserves all seven statuses in genuine report data', () {
    final now = DateTime.now();
    final reports = MunicipalReportDirectory.instance.reports.value;
    MunicipalReportDirectory.instance.reports.value = [
      ...reports,
      IncomingReportItem(
        referenceId: 'CV-LIVE-3',
        title: 'Awaiting confirmation',
        description: '',
        locationLabel: 'Tamale',
        category: ReportCategory.other,
        status: ReportStatus.pendingApproval,
        timeAgo: 'Today',
        region: Region.northern,
        assembly: 'Tamale',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
    ];

    final analytics = MinistryDataDirectory.instance.analytics;

    expect(analytics.statusCounts.keys, containsAll(ReportStatus.values));
    expect(analytics.statusCounts[ReportStatus.pendingApproval], 1);
    expect(analytics.statusCounts[ReportStatus.rejected], 1);
    expect(analytics.totalReports, 4);
    expect(analytics.statusDistribution, hasLength(ReportStatus.values.length));

    final insights = MinistryDataDirectory.instance.insights;
    expect(insights.statusCounts.keys, containsAll(ReportStatus.values));
    expect(insights.count(ReportStatus.pendingApproval), 1);
    expect(insights.count(ReportStatus.rejected), 1);
    expect(insights.openBacklog, 2);
    expect(
      insights.criticalInsights.last.subtitle,
      contains('Awaiting Confirmation'),
    );
    expect(insights.strategicFocusText, isNot(contains('MapEntry')));

    final awaitingConfirmation = MinistryDataDirectory.instance.insightsFor(
      dateRange: InsightsDateRange.last7Days,
      category: InsightsCategoryFilter.all,
      status: InsightsStatusFilter.pendingApproval,
    );
    expect(awaitingConfirmation.totalReports, 1);
    expect(awaitingConfirmation.count(ReportStatus.pendingApproval), 1);
    expect(awaitingConfirmation.openBacklog, 1);
  });
}
