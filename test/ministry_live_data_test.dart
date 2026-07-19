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

    expect(directory.dashboard.stats.totalReports, 3);
    expect(directory.reportOverview.stats.resolved, 1);
    expect(directory.performance.regionalLeaders, hasLength(2));
    expect(directory.insights.resolutionPercent, 33);
  });

  test('analytics date range and insights filters change their data', () {
    final directory = MinistryDataDirectory.instance;

    expect(
      directory.analyticsFor(AnalyticsDateRange.last7Days).totalReports,
      2,
    );
    final filtered = directory.insightsFor(
      dateRange: InsightsDateRange.last7Days,
      category: InsightsCategoryFilter.sanitation,
      status: InsightsStatusFilter.resolved,
    );
    expect(filtered.categoryPeakLabel, 'Sanitation');
    expect(filtered.resolutionPercent, 100);
  });
}
