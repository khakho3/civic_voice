import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/models/ministry_analytics_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/models/ministry_dashboard_data.dart';
import 'package:civic_voice/features/ministry/models/ministry_reports_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/models/municipal_performance_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipality_detail_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_notifications_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/ministry/models/ministry_report_insights_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/features/ministry/widgets/region_picker_chip.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/widgets/glass_dialog_backdrop.dart';
import 'package:civic_voice/widgets/profile_edit_button.dart';

/// Stands in for the real platform channel implementation, which never
/// resolves in a widget test — there's no host app registered to answer
/// `plugins.flutter.io/url_launcher`, so an unmocked `launchUrl()` call just
/// hangs forever rather than throwing, and a test awaiting it would time
/// out. Swapped in via [UrlLauncherPlatform.instance] for the tests that
/// exercise Call/Message, then restored via `addTearDown`.
class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  _FakeUrlLauncherPlatform({this.launchResult = true});

  final bool launchResult;
  Uri? lastLaunchedUri;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => launchResult;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    lastLaunchedUri = Uri.parse(url);
    return launchResult;
  }
}

MinistryDashboardData ministryDashboardFixture() {
  const statusCounts = <ReportStatus, int>{
    ReportStatus.submitted: 744,
    ReportStatus.underReview: 3200,
    ReportStatus.assigned: 744,
    ReportStatus.inProgress: 232,
    ReportStatus.pendingApproval: 1240,
    ReportStatus.resolved: 18600,
    ReportStatus.rejected: 40,
  };
  return const MinistryDashboardData(
    stats: MinistryDashboardStats(
      statusCounts: statusCounts,
      activeMunicipalities: 216,
    ),
    reportStatistics: ReportStatistics(
      monthlyValues: [62, 78, 54, 92, 68, 100],
      rangeLabel: 'Jan–Jun reports',
      totalLabel: '24.8K total',
    ),
    insights: QuickInsights(statusCounts: statusCounts),
    topMunicipalities: [
      RegionalLeaderItem(
        name: 'Accra Metropolitan',
        region: Region.greaterAccra,
        resolvedPercent: 92,
        responseTimeLabel: '14h',
        officerName: 'Kwame Owusu',
        officerPhone: '+233 24 555 0101',
      ),
      RegionalLeaderItem(
        name: 'Kumasi Metropolitan',
        region: Region.ashanti,
        resolvedPercent: 86,
        responseTimeLabel: '18h',
        officerName: 'Abena Boateng',
        officerPhone: '+233 24 555 0102',
      ),
      RegionalLeaderItem(
        name: 'Sunyani Municipal',
        region: Region.bono,
        resolvedPercent: 83,
        responseTimeLabel: '17h',
        officerName: 'Comfort Osei',
        officerPhone: '+233 24 555 0114',
      ),
    ],
  );
}

MinistryAnalyticsData ministryAnalyticsFixture() {
  const statusCounts = <ReportStatus, int>{
    ReportStatus.submitted: 744,
    ReportStatus.underReview: 3200,
    ReportStatus.assigned: 744,
    ReportStatus.inProgress: 232,
    ReportStatus.pendingApproval: 1240,
    ReportStatus.resolved: 18600,
    ReportStatus.rejected: 40,
  };
  return const MinistryAnalyticsData(
    dateRangeLabel: 'Last 30 Days',
    totalReports: 24800,
    resolutionRate: 75,
    trendValues: [62, 78, 54, 92, 68, 100],
    trendStartLabel: '29 days ago',
    trendMidLabel: '14 days ago',
    trendEndLabel: 'Today',
    breakdownsByDimension: {
      AnalyticsDimension.category: [
        AnalyticsBreakdownItem(
          label: 'Road Infrastructure',
          percent: 68,
          color: AppColors.primary,
        ),
        AnalyticsBreakdownItem(
          label: 'Sanitation',
          percent: 74,
          color: AppColors.statusResolved,
        ),
        AnalyticsBreakdownItem(
          label: 'Water Services',
          percent: 51,
          color: AppColors.warning,
        ),
      ],
      AnalyticsDimension.status: [
        AnalyticsBreakdownItem(
          label: 'Submitted',
          percent: 3,
          color: AppColors.statusSubmitted,
        ),
        AnalyticsBreakdownItem(
          label: 'Under Review',
          percent: 13,
          color: AppColors.statusUnderReview,
        ),
        AnalyticsBreakdownItem(
          label: 'Assigned',
          percent: 3,
          color: AppColors.statusAssigned,
        ),
        AnalyticsBreakdownItem(
          label: 'In Progress',
          percent: 1,
          color: AppColors.statusInProgress,
        ),
        AnalyticsBreakdownItem(
          label: 'Awaiting Confirmation',
          percent: 5,
          color: AppColors.statusPendingApproval,
        ),
        AnalyticsBreakdownItem(
          label: 'Resolved',
          percent: 75,
          color: AppColors.statusResolved,
        ),
        AnalyticsBreakdownItem(
          label: 'Rejected',
          percent: 0,
          color: AppColors.statusRejected,
        ),
      ],
      AnalyticsDimension.municipality: [
        AnalyticsBreakdownItem(
          label: 'Greater Accra',
          percent: 92,
          color: AppColors.statusResolved,
        ),
      ],
    },
    statusCounts: statusCounts,
    statusDistribution: [
      StatusSlice(label: 'Submitted', percent: 3, color: AppColors.statusSubmitted),
      StatusSlice(
        label: 'Under Review',
        percent: 13,
        color: AppColors.statusUnderReview,
      ),
      StatusSlice(label: 'Assigned', percent: 3, color: AppColors.statusAssigned),
      StatusSlice(
        label: 'In Progress',
        percent: 1,
        color: AppColors.statusInProgress,
      ),
      StatusSlice(
        label: 'Awaiting Confirmation',
        percent: 5,
        color: AppColors.statusPendingApproval,
      ),
      StatusSlice(label: 'Resolved', percent: 75, color: AppColors.statusResolved),
      StatusSlice(label: 'Rejected', percent: 0, color: AppColors.statusRejected),
    ],
    trendInsight: '18,600 of 24,800 reports are resolved nationally.',
  );
}

MinistryReportInsightsData ministryReportInsightsFixture() {
  const statusCounts = <ReportStatus, int>{
    ReportStatus.submitted: 1,
    ReportStatus.underReview: 1,
    ReportStatus.assigned: 1,
    ReportStatus.inProgress: 1,
    ReportStatus.pendingApproval: 1,
    ReportStatus.resolved: 2,
    ReportStatus.rejected: 1,
  };
  return const MinistryReportInsightsData(
    categoryPeakLabel: 'Sanitation',
    categoryPeakCount: 3,
    resolutionPercent: 25,
    statusCounts: statusCounts,
    criticalInsights: [
      CriticalInsightItem(
        icon: AppIcons.focusArea,
        tint: AppColors.warning,
        title: 'Sanitation has the highest report volume',
        subtitle: '3 national reports',
      ),
      CriticalInsightItem(
        icon: AppIcons.pace,
        tint: AppColors.statusResolved,
        title: '25% national resolution rate',
        subtitle: '2 reports completed',
      ),
      CriticalInsightItem(
        icon: AppIcons.statusUnderReview,
        tint: AppColors.primary,
        title: '5 reports are in the open backlog',
        subtitle:
            'Submitted, Under Review, Assigned, In Progress, and Awaiting Confirmation',
      ),
    ],
    strategicFocusText:
        'Sanitation has the highest report volume in the selected reports.',
  );
}

MinistryReportsData ministryReportsFixture() {
  return const MinistryReportsData(
    stats: MinistryReportsStats(
      aggregatedReports: 4,
      underReview: 1,
      resolved: 1,
    ),
    reports: [
      ReportSummaryItem(
        title: 'Pothole on Main Street',
        municipality: 'Accra Metropolitan',
        region: Region.greaterAccra,
        category: 'Road Infrastructure',
        status: ReportStatus.submitted,
        dateLabel: '2 days ago',
      ),
      ReportSummaryItem(
        title: 'Broken Streetlight',
        municipality: 'Kumasi Metropolitan',
        region: Region.ashanti,
        category: 'Utilities',
        status: ReportStatus.resolved,
        dateLabel: 'Yesterday',
      ),
      ReportSummaryItem(
        title: 'Overflowing Drainage',
        municipality: 'Tamale Metropolitan',
        region: Region.northern,
        category: 'Sanitation',
        status: ReportStatus.underReview,
        dateLabel: 'Today',
      ),
      ReportSummaryItem(
        title: 'Awaiting Assembly Confirmation',
        municipality: 'Kumasi Metropolitan',
        region: Region.ashanti,
        category: 'Water Services',
        status: ReportStatus.pendingApproval,
        dateLabel: '6 hours ago',
      ),
    ],
  );
}

MunicipalPerformanceData ministryMunicipalPerformanceFixture() {
  return const MunicipalPerformanceData(
    stats: MunicipalPerformanceStats(
      avgResponseLabel: '18h',
      resolutionPercent: 76,
      slaMetPercent: 84,
      backlogLabel: '6',
    ),
    regionalLeaders: [
      RegionalLeaderItem(
        name: 'Accra Metropolitan',
        region: Region.greaterAccra,
        resolvedPercent: 92,
        responseTimeLabel: '14h',
        officerName: 'Kwame Owusu',
        officerPhone: '+233 24 555 0101',
      ),
      RegionalLeaderItem(
        name: 'Kumasi Metropolitan',
        region: Region.ashanti,
        resolvedPercent: 86,
        responseTimeLabel: '18h',
        officerName: 'Abena Boateng',
        officerPhone: '+233 24 555 0102',
      ),
      RegionalLeaderItem(
        name: 'Tamale Metropolitan',
        region: Region.northern,
        resolvedPercent: 71,
        responseTimeLabel: '26h',
        officerName: 'Alhassan Iddrisu',
        officerPhone: '+233 24 555 0109',
      ),
      RegionalLeaderItem(
        name: 'Jasikan Municipal',
        region: Region.oti,
        resolvedPercent: 62,
        responseTimeLabel: '41h',
        officerName: 'Ama Kudjo',
        officerPhone: '+233 24 555 0108',
      ),
    ],
    responseTrend: [46, 62, 54, 88, 66, 40, 28],
    resolutionTrend: [58, 70, 64, 92, 78, 52, 44],
    trendCaption: 'Last 7 days · genuine report activity',
    hasReportData: true,
  );
}

void main() {
  for (final state in MinistryDashboardViewState.values) {
    testWidgets('Ministry Dashboard renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Ministry Dashboard renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      // Regression: the header's brand-mark row and the bottom nav's
      // longest tab label ("Municipalities") both overflowed at this width
      // — a 428px-only test suite never caught it.
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ministry Dashboard shows the full national summary in its '
      'loaded state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryDashboardScreen(data: ministryDashboardFixture()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('Ministry Supervisor'), findsOneWidget);
    expect(find.text('National Dashboard'), findsOneWidget);

    expect(find.text('Total Reports'), findsOneWidget);
    expect(find.text('24.8K'), findsOneWidget);
    expect(find.text('Open Work'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('18.6K'), findsOneWidget);
    // Appears on both the stat card and the bottom-nav tab label.
    expect(find.text('Municipalities'), findsNWidgets(2));
    expect(find.text('216'), findsOneWidget);

    expect(find.text('Report Statistics'), findsOneWidget);
    expect(find.text('Jan–Jun reports'), findsOneWidget);

    expect(find.text('Quick Insights'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Under Review'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Awaiting Confirmation'), findsOneWidget);

    expect(find.text('Municipality Performance'), findsOneWidget);
    expect(find.text('Accra Metropolitan'), findsOneWidget);
    expect(find.text('92% resolved · 14h response'), findsOneWidget);
    expect(find.text('Kumasi Metropolitan'), findsOneWidget);
    expect(find.text('Sunyani Municipal'), findsOneWidget);
  });

  Future<void> pumpMinistryDashboard(
    WidgetTester tester,
    MinistryDashboardViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryDashboardScreen(initialState: state),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Ministry Dashboard zero state keeps the national summary honest', (
    WidgetTester tester,
  ) async {
    await pumpMinistryDashboard(tester, MinistryDashboardViewState.empty);
    expect(find.text('National Dashboard'), findsOneWidget);
    expect(find.text('Total Reports'), findsOneWidget);
    expect(find.text('Open Work'), findsOneWidget);
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('Municipalities'), findsWidgets);
    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('Welcome to the national dashboard'), findsOneWidget);
    // Matches every other Ministry screen's Empty-state button label —
    // this used to say "Retry" here alone, a real inconsistency, not a
    // deliberate per-screen wording choice.
    expect(find.text('Refresh'), findsOneWidget);
    expect(find.text('Report Statistics'), findsNothing);
    expect(find.text('Municipality Performance'), findsNothing);
    expect(find.text('Accra Metropolitan'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  test('Ministry Dashboard aggregates all seven statuses truthfully', () {
    final data = ministryDashboardFixture();

    expect(data.stats.statusCounts.keys, containsAll(ReportStatus.values));
    expect(data.stats.totalReports, 24800);
    expect(data.stats.openWork, 6160);
    expect(data.stats.resolved, 18600);
    expect(data.insights.count(ReportStatus.pendingApproval), 1240);
    expect(data.insights.percent(ReportStatus.pendingApproval), 5);
    expect(data.insights.count(ReportStatus.rejected), 40);
  });

  testWidgets(
    'Ministry Dashboard Offline shows the approved copy, not leftover '
    'Municipal Officer text',
    (WidgetTester tester) async {
      await pumpMinistryDashboard(tester, MinistryDashboardViewState.offline);
      expect(find.text('You\'re offline'), findsOneWidget);
      expect(find.text('Retry connection'), findsOneWidget);
      // Regression: the raw export's offline copy referenced "incoming
      // reports" — a leftover from the Municipal Officer module's own
      // offline banner, not anything the Ministry Supervisor role has.
      expect(find.textContaining('incoming reports'), findsNothing);
    },
  );

  testWidgets('Ministry Dashboard Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryDashboard(tester, MinistryDashboardViewState.error);
    expect(find.text('Unable to Load Dashboard'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Ministry Dashboard does not claim retry succeeded without a refresh callback',
    (WidgetTester tester) async {
      await pumpMinistryDashboard(tester, MinistryDashboardViewState.error);
      final retry = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(retry.onPressed, isNull);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Unable to Load Dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Dashboard Unauthorized shows the approved copy with no action '
    'buttons',
    (WidgetTester tester) async {
      await pumpMinistryDashboard(
        tester,
        MinistryDashboardViewState.unauthorized,
      );
      expect(find.text('Unauthorized Access'), findsOneWidget);
      // The approved frame shows no action buttons for this state.
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets(
    'Ministry Dashboard is a tab-shell screen: bottom nav stays visible and '
    'switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var analyticsTapped = false;
      var municipalitiesTapped = false;
      var reportsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(
            onNavigateToAnalytics: () => analyticsTapped = true,
            onNavigateToMunicipalities: () => municipalitiesTapped = true,
            onNavigateToReports: () => reportsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Municipalities'), findsWidgets);
      expect(find.text('Reports'), findsOneWidget);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(analyticsTapped, isTrue);

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(reportsTapped, isTrue);

      // "Municipalities" also appears as both the section title and the
      // stat card icon in the body — the bottom nav's copy of the icon is
      // the last one in tree order (Stack paints body before nav).
      await tester.tap(find.byIcon(AppIcons.municipality).last);
      await tester.pumpAndSettle();
      expect(municipalitiesTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Dashboard header profile avatar opens Ministry Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(
            onProfileTap: () => profileTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.profile));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    },
  );

  testWidgets('Ministry routes connect Dashboard, Analytics, Municipalities, '
      'Reports, and Profile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> advanceRoute() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await tester.pumpWidget(
      const app.CivicVoiceApp(initialRoute: app.AppRoutes.ministryDashboard),
    );
    await advanceRoute();

    expect(find.text('National Dashboard'), findsOneWidget);

    await tester.tap(find.text('Analytics'));
    await advanceRoute();

    expect(find.text('Analytics Dashboard'), findsOneWidget);
    expect(find.text('No Analytics Available'), findsOneWidget);
    expect(find.text('Trend Insights'), findsNothing);

    await tester.tap(find.byIcon(AppIcons.municipality).last);
    await advanceRoute();

    expect(find.text('Municipal Performance'), findsOneWidget);
    // The app route has no injected, confirmed Ministry snapshot. It must
    // remain honest instead of manufacturing a municipality row to make this
    // route test navigable. Fixture-backed detail navigation is covered below.
    expect(find.text('No Performance Data'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await advanceRoute();

    expect(find.text('Reports Overview'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.profile));
    await advanceRoute();

    expect(find.text('My Profile'), findsOneWidget);
  });

  testWidgets(
    'Ministry Dashboard "View All" opens Municipal Performance while each '
    'municipality row opens its own Municipal Officer detail screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var municipalitiesTapped = 0;
      var reportsTapped = false;
      String? openedMunicipality;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryDashboardScreen(
            data: ministryDashboardFixture(),
            onNavigateToMunicipalities: () => municipalitiesTapped++,
            onNavigateToReports: () => reportsTapped = true,
            onOpenMunicipality: (item) => openedMunicipality = item.name,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All'));
      await tester.pumpAndSettle();

      expect(municipalitiesTapped, 1);
      expect(reportsTapped, isFalse);

      // Regression: a municipality row's own chevron used to imply a tap
      // target with nothing behind it — it now opens the per-municipality
      // Municipal Officer contact detail screen rather than staying dead
      // or duplicating "View All"'s destination.
      await tester.tap(find.text('Accra Metropolitan'));
      await tester.pumpAndSettle();

      expect(openedMunicipality, 'Accra Metropolitan');
      expect(municipalitiesTapped, 1);
      expect(reportsTapped, isFalse);
    },
  );

  // ---------------------------------------------------------------------
  // MIN-002 Analytics Dashboard
  // ---------------------------------------------------------------------

  for (final state in MinistryAnalyticsViewState.values) {
    testWidgets('Ministry Analytics renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(
            initialState: state,
            data: ministryAnalyticsFixture(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Ministry Analytics renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Category Resolution Rates'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Analytics shows the full breakdown in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Municipality'), findsOneWidget);

      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('24,800'), findsOneWidget);
      expect(find.text('Resolution Rate'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);

      expect(find.text('Report Trends'), findsOneWidget);
      expect(find.text('29 days ago'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);

      expect(find.text('Category Resolution Rates'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsOneWidget);
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('Sanitation'), findsOneWidget);
      expect(find.text('Water Services'), findsOneWidget);

      expect(find.text('Report Status'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('Awaiting Confirmation'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      // "Resolved" appears both in the Report Status legend and the bottom
      // status-bar icon's semantic role — checked loosely.
      expect(find.text('Resolved'), findsWidgets);

      expect(find.text('Trend Insights'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Analytics dimension chips pivot the Distribution section',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category Resolution Rates'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsOneWidget);

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      expect(find.text('Status Distribution'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsNothing);

      await tester.tap(find.text('Municipality'));
      await tester.pumpAndSettle();

      expect(find.text('Municipality Resolution Rates'), findsOneWidget);
      // The fixture is deliberately test-only; genuine production data is
      // supplied by MinistryDataDirectory.
      expect(find.text('Greater Accra'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
    },
  );

  testWidgets('Ministry Analytics uses an honest empty default state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MinistryAnalyticsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Analytics Available'), findsOneWidget);
    expect(find.text('Report Trends'), findsNothing);
    expect(find.text('Trend Insights'), findsNothing);
    expect(find.text('Total Reports'), findsNothing);
    expect(find.text('Greater Accra'), findsNothing);
    expect(find.text('29 days ago'), findsNothing);
  });

  testWidgets('Ministry Analytics omits unsupported comparisons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('previous period'), findsNothing);
    expect(find.textContaining('+0%'), findsNothing);
    expect(find.textContaining('+12%'), findsNothing);
  });

  testWidgets(
    'Ministry Analytics date range picker opens a bottom sheet and updates '
    'the selected label',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Last 30 Days'));
      await tester.pumpAndSettle();

      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('This Year'), findsOneWidget);

      await tester.tap(find.text('Last 7 Days'));
      await tester.pumpAndSettle();

      expect(find.text('Last 7 Days'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsNothing);
    },
  );

  testWidgets(
    'Ministry Analytics keeps dimension filters visible after the date selector collapses',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      final dateHeader = find.byKey(const ValueKey('collapsible_header'));
      expect(tester.getSize(dateHeader).height, greaterThan(0));

      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getSize(dateHeader).height, 0);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Municipality'), findsOneWidget);

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();
      expect(find.text('Status Distribution'), findsOneWidget);
    },
  );

  Future<void> pumpMinistryAnalytics(
    WidgetTester tester,
    MinistryAnalyticsViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryAnalyticsScreen(
          initialState: state,
          data: ministryAnalyticsFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ministry Analytics Empty shows the approved copy, with filter chrome '
    'still visible',
    (WidgetTester tester) async {
      await pumpMinistryAnalytics(tester, MinistryAnalyticsViewState.empty);
      expect(find.text('No Analytics Available'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      // Unlike MIN-001 Dashboard, the date range/dimension chrome stays
      // visible for this state — confirmed against the approved frame.
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
    },
  );

  testWidgets('Ministry Analytics No Results clears filters and returns to the '
      'loaded state', (WidgetTester tester) async {
    await pumpMinistryAnalytics(tester, MinistryAnalyticsViewState.noResults);
    expect(find.text('No Results'), findsOneWidget);
    expect(
      find.text('No aggregated analytics match the selected filters.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear Filters'));
    await tester.pumpAndSettle();

    expect(find.text('Category Resolution Rates'), findsOneWidget);
    expect(find.text('Road Infrastructure'), findsOneWidget);
  });

  testWidgets('Ministry Analytics Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryAnalytics(tester, MinistryAnalyticsViewState.offline);
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
  });

  testWidgets('Ministry Analytics Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryAnalytics(tester, MinistryAnalyticsViewState.error);
    expect(find.text('Unable to Load Analytics'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('Ministry Analytics does not invent refresh success', (
    WidgetTester tester,
  ) async {
    await pumpMinistryAnalytics(tester, MinistryAnalyticsViewState.error);

    final retry = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(retry.onPressed, isNull);
    expect(find.text('Unable to Load Analytics'), findsOneWidget);
  });

  testWidgets('Ministry Analytics Unauthorized shows the approved copy with no '
      'action buttons', (WidgetTester tester) async {
    await pumpMinistryAnalytics(
      tester,
      MinistryAnalyticsViewState.unauthorized,
    );
    expect(find.text('Unauthorized Access'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets(
    'Ministry Analytics is a tab-shell screen: bottom nav stays visible and '
    'switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dashboardTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(
            onNavigateToDashboard: () => dashboardTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Analytics header profile avatar opens Ministry Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(
            onProfileTap: () => profileTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.profile));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Analytics Trend Insights callout opens Report Insights',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var insightsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(
            onViewReportInsights: () => insightsTapped = true,
            data: ministryAnalyticsFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trend Insights'));
      await tester.pumpAndSettle();

      expect(insightsTapped, isTrue);
    },
  );

  // ---------------------------------------------------------------------
  // MIN-003 Municipal Performance
  // ---------------------------------------------------------------------

  for (final state in MinistryMunicipalPerformanceViewState.values) {
    testWidgets(
      'Ministry Municipal Performance renders ${state.name} without error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(428, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MinistryMunicipalPerformanceScreen(
              initialState: state,
              data: ministryMunicipalPerformanceFixture(),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Ministry Municipal Performance renders without overflow on a narrow '
    'phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ministry Municipal Performance shows the full breakdown in its loaded '
    'state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Municipal Performance'), findsOneWidget);
      expect(
        find.text(
          'Aggregated response and resolution metrics across '
          'municipalities.',
        ),
        findsOneWidget,
      );
      expect(find.text('All Regions'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Top 10'), findsOneWidget);
      // "Needs Attention" — the widest chip — sits beyond the
      // horizontally-scrollable chip row's initial build extent at this
      // width, matching the same kind of chip-row cut-off already seen
      // elsewhere in this app (e.g. Admin System Activity's widest chip).

      expect(find.text('Avg Response'), findsOneWidget);
      expect(find.text('18h'), findsOneWidget);
      // Appears on both the stat card and the Efficiency Trend toggle.
      expect(find.text('Resolution'), findsNWidgets(2));
      expect(find.text('76%'), findsOneWidget);
      expect(find.text('SLA Met'), findsOneWidget);
      expect(find.text('84%'), findsOneWidget);
      expect(find.text('Backlog'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      expect(find.text('Regional Leaders'), findsOneWidget);
      // One real assembly per Ghana region (16) — enough national volume
      // for the region picker and Top 10/Needs Attention scope to do real
      // filtering, unlike the three placeholder entries this replaced.
      expect(find.text('4 shown'), findsOneWidget);
      expect(find.text('Accra Metropolitan'), findsOneWidget);
      expect(
        find.text('Greater Accra · 92% resolved · 14h response'),
        findsOneWidget,
      );
      expect(find.text('Kumasi Metropolitan'), findsOneWidget);
      expect(find.text('Tamale Metropolitan'), findsOneWidget);

      expect(find.text('Efficiency Trend'), findsOneWidget);
      expect(
        find.text('Last 7 days · genuine report activity'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Ministry Municipal Performance Efficiency Trend toggle switches series '
    'without error',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Resolution" also appears as a stat card label — target the toggle
      // specifically via .last (it's built after the stat cards in tree
      // order).
      await tester.tap(find.text('Resolution').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ministry Municipal Performance region picker scrolls instead of '
      'overflowing on a realistic phone height, and narrows the list', (
    WidgetTester tester,
  ) async {
    // A real phone height, not the artificially tall 2600px viewport
    // most tests here use — the region picker's 17 rows (All Regions +
    // 16 regions) only overflowed a plain Column on an actual device
    // height, which none of the taller-viewport tests would have caught.
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryMunicipalPerformanceScreen(
          data: ministryMunicipalPerformanceFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('All Regions'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ashanti'), findsOneWidget);

    await tester.tap(find.text('Ashanti'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ashanti'), findsOneWidget);
    expect(find.text('Accra Metropolitan'), findsNothing);
    expect(find.text('Kumasi Metropolitan'), findsOneWidget);
  });

  testWidgets(
    'Ministry Municipal Performance keeps filters visible after its subtitle collapses',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final subtitle = find.text(
        'Aggregated response and resolution metrics across municipalities.',
      );
      expect(subtitle, findsOneWidget);
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();

      // CollapsibleListHeader clips its header instead of removing it from
      // the tree, so assert the actual visual/accessibility behavior rather
      // than an incorrect widget-removal assumption.
      expect(subtitle.hitTestable(), findsNothing);
      expect(find.byType(RegionPickerChip), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Top 10'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipal Performance uses an honest empty default state',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryMunicipalPerformanceScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Performance Data'), findsOneWidget);
      expect(find.text('Regional Leaders'), findsNothing);
      expect(find.text('Accra Metropolitan'), findsNothing);
      expect(find.text('76%'), findsNothing);
      expect(find.text('1.2K'), findsNothing);

      final refresh = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Refresh'),
      );
      expect(refresh.onPressed, isNull);
    },
  );

  testWidgets(
    'Ministry Municipal Performance preserves a region on dismiss and clears it only for All Regions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final regionChip = find.byType(RegionPickerChip);
      await tester.tap(regionChip);
      await tester.pumpAndSettle();
      final sheet = find.byType(BottomSheet);
      await tester.tap(
        find.descendant(of: sheet, matching: find.text('Ashanti')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: regionChip, matching: find.text('Ashanti')),
        findsOneWidget,
      );
      expect(find.text('Kumasi Metropolitan'), findsOneWidget);

      await tester.tap(regionChip);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: regionChip, matching: find.text('Ashanti')),
        findsOneWidget,
      );

      await tester.tap(regionChip);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('All Regions')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: regionChip, matching: find.text('All Regions')),
        findsOneWidget,
      );
      expect(find.text('Accra Metropolitan'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipal Performance metrics keep 44px targets on a narrow phone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryMunicipalPerformanceScreen(
            data: ministryMunicipalPerformanceFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final performanceList = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      );
      expect(performanceList, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Efficiency Trend'),
        240,
        scrollable: performanceList,
      );
      final responseToggle = find.ancestor(
        of: find.text('Response'),
        matching: find.byType(InkWell),
      );
      final resolutionToggle = find.ancestor(
        of: find.text('Resolution').last,
        matching: find.byType(InkWell),
      );
      expect(tester.getSize(responseToggle).height, greaterThanOrEqualTo(44));
      expect(tester.getSize(resolutionToggle).height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ministry Reports keeps its selected region when picker closes', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportsScreen(data: ministryReportsFixture()),
      ),
    );
    await tester.pumpAndSettle();

    final filterRow = find.ancestor(
      of: find.text('All'),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            widget.axisDirection == AxisDirection.right,
      ),
    );
    expect(filterRow, findsOneWidget);
    final regionChip = find.byType(RegionPickerChip);
    Future<void> openVisibleRegionPicker({required bool revealFromStart}) async {
      // The initial reveal must start from the leading status chip. Once a
      // region has been chosen, that leading lazy child can be evicted while
      // the rail stays positioned at the trailing picker, so do not resolve
      // the rail through the no-longer-built `All` chip a second time.
      if (revealFromStart) {
        await tester.scrollUntilVisible(
          regionChip,
          240,
          scrollable: filterRow,
        );
      }
      final pickerTapTarget = find.descendant(
        of: regionChip,
        matching: find.byType(InkWell),
      );
      expect(pickerTapTarget, findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(pickerTapTarget),
        alignment: 0.5,
        duration: Duration.zero,
      );
      await tester.pump();
      expect(pickerTapTarget.hitTestable(), findsOneWidget);
      await tester.tap(pickerTapTarget);
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
    }

    await openVisibleRegionPicker(revealFromStart: true);
    await tester.tap(
      find.descendant(of: find.byType(BottomSheet), matching: find.text('Ashanti')),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: regionChip, matching: find.text('Ashanti')),
      findsOneWidget,
    );

    await openVisibleRegionPicker(revealFromStart: false);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: regionChip, matching: find.text('Ashanti')),
      findsOneWidget,
    );
  });

  testWidgets('Ministry Municipal Performance Regional Leaders row opens the '
      'Municipal Officer contact detail screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedMunicipality;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryMunicipalPerformanceScreen(
          data: ministryMunicipalPerformanceFixture(),
          onOpenMunicipality: (item) => openedMunicipality = item.name,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accra Metropolitan'));
    await tester.pumpAndSettle();

    expect(openedMunicipality, 'Accra Metropolitan');
  });

  Future<void> pumpMinistryMunicipalPerformance(
    WidgetTester tester,
    MinistryMunicipalPerformanceViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryMunicipalPerformanceScreen(
          initialState: state,
          data: ministryMunicipalPerformanceFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ministry Municipal Performance Empty shows the approved copy, with '
    'filter chrome still visible',
    (WidgetTester tester) async {
      await pumpMinistryMunicipalPerformance(
        tester,
        MinistryMunicipalPerformanceViewState.empty,
      );
      expect(find.text('No Performance Data'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      // Shorter subtitle than Default, and filter chrome stays visible —
      // both confirmed against the approved frame.
      expect(
        find.text('Aggregated municipality metrics only.'),
        findsOneWidget,
      );
      expect(find.text('All'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipal Performance No Results clears filters and returns '
    'to the loaded state',
    (WidgetTester tester) async {
      await pumpMinistryMunicipalPerformance(
        tester,
        MinistryMunicipalPerformanceViewState.noResults,
      );
      expect(find.text('No Results'), findsOneWidget);
      expect(
        find.text(
          'No municipality performance records match the selected filters.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Regional Leaders'), findsOneWidget);
      expect(find.text('Accra Metropolitan'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipal Performance Offline shows the approved copy',
    (WidgetTester tester) async {
      await pumpMinistryMunicipalPerformance(
        tester,
        MinistryMunicipalPerformanceViewState.offline,
      );
      expect(find.text('You\'re offline'), findsOneWidget);
      expect(find.text('Retry connection'), findsOneWidget);
    },
  );

  testWidgets('Ministry Municipal Performance Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryMunicipalPerformance(
      tester,
      MinistryMunicipalPerformanceViewState.error,
    );
    expect(find.text('Unable to Load Performance'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Ministry Municipal Performance Unauthorized shows the approved copy '
    'with no action buttons',
    (WidgetTester tester) async {
      await pumpMinistryMunicipalPerformance(
        tester,
        MinistryMunicipalPerformanceViewState.unauthorized,
      );
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets(
    'Ministry Municipal Performance is a tab-shell screen: bottom nav stays '
    'visible and switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dashboardTapped = false;
      var analyticsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
        home: MinistryMunicipalPerformanceScreen(
          data: ministryMunicipalPerformanceFixture(),
          onNavigateToDashboard: () => dashboardTapped = true,
            onNavigateToAnalytics: () => analyticsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(analyticsTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Municipal Performance header profile avatar opens Ministry '
    'Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
        home: MinistryMunicipalPerformanceScreen(
          data: ministryMunicipalPerformanceFixture(),
          onProfileTap: () => profileTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.profile));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    },
  );

  // ---------------------------------------------------------------------
  // MIN-004 Reports Overview
  // ---------------------------------------------------------------------

  for (final state in MinistryReportsViewState.values) {
    testWidgets(
      'Ministry Reports Overview renders ${state.name} without error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(428, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MinistryReportsScreen(initialState: state),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Ministry Reports Overview renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryReportsScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ministry Reports Overview uses an honest empty default state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MinistryReportsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Reports'), findsOneWidget);
    expect(find.text('Aggregated Reports'), findsNothing);
    expect(find.text('Pothole on Main Street'), findsNothing);
    expect(find.text('24,812'), findsNothing);
  });

  testWidgets(
    'Ministry Reports Overview keeps a long Awaiting Confirmation row readable '
    'on a narrow phone',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const title =
          'Long drainage obstruction report requiring confirmation from the assembly';
      const location = 'Accra Metropolitan · Sanitation';
      const date = 'Yesterday';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryReportsScreen(
            data: MinistryReportsData(
              stats: MinistryReportsStats(
                aggregatedReports: 1,
                underReview: 0,
                resolved: 0,
              ),
              reports: [
                ReportSummaryItem(
                  title: title,
                  municipality: 'Accra Metropolitan',
                  region: Region.greaterAccra,
                  category: 'Sanitation',
                  status: ReportStatus.pendingApproval,
                  dateLabel: date,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text(title);
      final locationFinder = find.text(location);
      final statusFinder = find.text('Awaiting Confirmation');
      final dateFinder = find.text(date);

      expect(titleFinder, findsOneWidget);
      expect(locationFinder, findsOneWidget);
      expect(statusFinder, findsOneWidget);
      expect(dateFinder, findsOneWidget);
      expect(
        tester.getTopLeft(statusFinder).dy,
        greaterThan(tester.getTopLeft(locationFinder).dy),
      );
      expect(
        tester.getTopLeft(dateFinder).dy,
        greaterThan(tester.getTopLeft(locationFinder).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ministry Reports Overview shows the full report list in its loaded '
    'state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(data: ministryReportsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reports Overview'), findsOneWidget);
      expect(find.text('Search aggregated reports'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      // "All Regions" (the region picker chip) is appended after the four
      // status chips and sits beyond the horizontally-scrollable chip
      // row's initial build extent at this width — same cut-off as
      // Municipal Performance's own "Needs Attention" chip.
      // Each of these also labels a status badge on one of the report
      // cards below, in addition to its own filter chip — "Submitted"
      // (chip + 4 badges), "Resolved" (chip + stat card label + 4
      // badges). "Review" is chip-only: badges spell out "Under Review"
      // in full, a different string.
      expect(find.text('Submitted'), findsNWidgets(2));
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Resolved'), findsNWidgets(3));

      expect(find.text('Aggregated Reports'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(
        find.text('National report volume · current period'),
        findsOneWidget,
      );
      // Stat card label + one under-review badge.
      expect(find.text('Under Review'), findsNWidgets(2));
      expect(find.text('1'), findsNWidgets(2));

      expect(find.text('4 shown'), findsOneWidget);
      expect(find.text('Pothole on Main Street'), findsOneWidget);
      expect(
        find.text('Accra Metropolitan · Road Infrastructure'),
        findsOneWidget,
      );
      expect(find.text('2 days ago'), findsOneWidget);
      expect(find.text('Broken Streetlight'), findsOneWidget);

      expect(find.text('Report Insights'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Reports Overview search field filters the report list',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(data: ministryReportsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'pothole');
      await tester.pumpAndSettle();

      expect(find.text('1 shown'), findsOneWidget);
      expect(find.text('Pothole on Main Street'), findsOneWidget);
      expect(find.text('Broken Streetlight'), findsNothing);
    },
  );

  testWidgets('Ministry Reports Overview status chip filters the report list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportsScreen(data: ministryReportsFixture()),
      ),
    );
    await tester.pumpAndSettle();

    // "Review" is chip-only — unlike "Submitted"/"Resolved", no status
    // badge spells out that exact string ("Under Review" is a different
    // string), so this is unambiguous without needing .first/.last.
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('1 shown'), findsOneWidget);
    expect(find.text('Overflowing Drainage'), findsOneWidget);
    expect(find.text('Pothole on Main Street'), findsNothing);
  });

  testWidgets(
    'Ministry Reports Overview keeps national summaries unchanged by filters',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(data: ministryReportsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('1 shown'), findsOneWidget);
    },
  );

  Future<void> pumpMinistryReports(
    WidgetTester tester,
    MinistryReportsViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportsScreen(
          initialState: state,
          data: ministryReportsFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ministry Reports Overview Empty shows the approved copy, with filter '
    'chrome still visible',
    (WidgetTester tester) async {
      await pumpMinistryReports(tester, MinistryReportsViewState.empty);
      expect(find.text('No Reports'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Search aggregated reports'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Reports Overview No Results clears filters and returns to the '
    'loaded state',
    (WidgetTester tester) async {
      await pumpMinistryReports(tester, MinistryReportsViewState.noResults);
      expect(find.text('No Results'), findsOneWidget);
      expect(
        find.text('No aggregated reports match the current search or filters.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.text('4 shown'), findsOneWidget);
      expect(find.text('Pothole on Main Street'), findsOneWidget);
    },
  );

  testWidgets('Ministry Reports Overview Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReports(tester, MinistryReportsViewState.offline);
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
  });

  testWidgets('Ministry Reports Overview Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReports(tester, MinistryReportsViewState.error);
    expect(find.text('Unable to Load Reports'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Ministry Reports Overview Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      await pumpMinistryReports(tester, MinistryReportsViewState.unauthorized);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets(
    'Ministry Reports Overview is a tab-shell screen: bottom nav stays '
    'visible and switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dashboardTapped = false;
      var analyticsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(
            onNavigateToDashboard: () => dashboardTapped = true,
            onNavigateToAnalytics: () => analyticsTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Municipalities'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);

      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();
      expect(analyticsTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Reports Overview header profile avatar opens Ministry Profile',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(onProfileTap: () => profileTapped = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.profile));
      await tester.pumpAndSettle();

      expect(profileTapped, isTrue);
    },
  );

  testWidgets(
    'Ministry Reports Overview "Report Insights" card opens Report Insights',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var insightsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportsScreen(
            onViewReportInsights: () => insightsTapped = true,
            data: ministryReportsFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report Insights'));
      await tester.pumpAndSettle();

      expect(insightsTapped, isTrue);
    },
  );

  // ---------------------------------------------------------------------
  // MIN-005 Report Insights
  // ---------------------------------------------------------------------

  for (final state in MinistryReportInsightsViewState.values) {
    testWidgets(
      'Ministry Report Insights renders ${state.name} without error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(428, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: MinistryReportInsightsScreen(initialState: state),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Ministry Report Insights renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryReportInsightsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Ministry Report Insights uses an honest empty default state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const MinistryReportInsightsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Insights'), findsOneWidget);
    expect(find.text('Category Peak'), findsNothing);
    expect(find.text('Status Breakdown'), findsNothing);
    expect(find.textContaining('+6.2%'), findsNothing);
    expect(find.textContaining('previous period'), findsNothing);
  });

  testWidgets(
    'Ministry Report Insights has no bottom nav — it is a drill-down, not a '
    'tab',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryReportInsightsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.text('Municipalities'), findsNothing);
    },
  );

  testWidgets(
    'Ministry Report Insights shows the full analysis in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportInsightsScreen(
            data: ministryReportInsightsFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Insights'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      expect(find.text('Category Peak'), findsOneWidget);
      expect(find.text('Sanitation'), findsOneWidget);
      expect(find.text('3 reports'), findsOneWidget);
      expect(find.text('Resolution'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('2 reports resolved'), findsOneWidget);

      expect(find.text('Status Breakdown'), findsOneWidget);
      for (final status in ReportStatus.values) {
        expect(
          find.text(
            '${status.label}: ${ministryReportInsightsFixture().count(status)}',
          ),
          findsOneWidget,
        );
      }
      expect(find.text('Critical Insights'), findsOneWidget);
      expect(
        find.text('Sanitation has the highest report volume'),
        findsOneWidget,
      );
      expect(find.text('5 reports are in the open backlog'), findsOneWidget);
      expect(find.textContaining('MapEntry'), findsNothing);

      expect(find.text('Strategic Focus'), findsOneWidget);
      expect(find.text('View focus summary'), findsOneWidget);
      expect(
        find.text(
          'Focus Summary is unavailable until I06 provides a grounded AI insight.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Ministry Report Insights date range picker opens a bottom sheet and '
    'updates the selected chip',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportInsightsScreen(
            data: ministryReportInsightsFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('30 days'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('90 days'));
      await tester.pumpAndSettle();

      expect(find.text('90 days'), findsOneWidget);
      expect(find.text('30 days'), findsNothing);
    },
  );

  testWidgets('Ministry Report Insights category chip opens a bottom sheet and '
      'updates the selected chip', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportInsightsScreen(data: ministryReportInsightsFixture()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Category'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sanitation').last);
    await tester.pumpAndSettle();

    // "Sanitation" also appears as the Category Peak stat value — the
    // chip is now a second, separate match.
    expect(find.text('Sanitation'), findsNWidgets(2));
    expect(find.text('Category'), findsNothing);
  });

  testWidgets(
    'Ministry Report Insights includes Awaiting Confirmation in its status filter',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportInsightsScreen(data: ministryReportInsightsFixture()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();
      final statusSheetList = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(Scrollable),
      );
      expect(statusSheetList, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Awaiting Confirmation'),
        200,
        scrollable: statusSheetList,
      );
      await tester.tap(find.text('Awaiting Confirmation'));
      await tester.pumpAndSettle();

      expect(find.text('Awaiting Confirmation'), findsOneWidget);
    },
  );

  Future<void> pumpMinistryReportInsights(
    WidgetTester tester,
    MinistryReportInsightsViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportInsightsScreen(
          initialState: state,
          data: ministryReportInsightsFixture(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ministry Report Insights Empty shows the approved copy, with filter '
    'chrome still visible',
    (WidgetTester tester) async {
      await pumpMinistryReportInsights(
        tester,
        MinistryReportInsightsViewState.empty,
      );
      expect(find.text('No Insights'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Report Insights No Results clears filters and returns to the '
    'loaded state',
    (WidgetTester tester) async {
      await pumpMinistryReportInsights(
        tester,
        MinistryReportInsightsViewState.noResults,
      );
      expect(find.text('No Results'), findsOneWidget);
      expect(
        find.text('No report insights match the selected filters.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Category Peak'), findsOneWidget);
    },
  );

  testWidgets('Ministry Report Insights Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReportInsights(
      tester,
      MinistryReportInsightsViewState.offline,
    );
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
  });

  testWidgets('Ministry Report Insights Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReportInsights(
      tester,
      MinistryReportInsightsViewState.error,
    );
    expect(find.text('Unable to Load Insights'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Ministry Municipal Performance does not invent retry success',
    (WidgetTester tester) async {
      await pumpMinistryMunicipalPerformance(
        tester,
        MinistryMunicipalPerformanceViewState.error,
      );

      final retry = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(retry.onPressed, isNull);
      expect(find.text('Unable to Load Performance'), findsOneWidget);
    },
  );

  testWidgets('Ministry Reports Overview does not invent retry success', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReports(tester, MinistryReportsViewState.error);

    final retry = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(retry.onPressed, isNull);
    expect(find.text('Unable to Load Reports'), findsOneWidget);
  });

  testWidgets('Ministry Report Insights does not invent retry success', (
    WidgetTester tester,
  ) async {
    await pumpMinistryReportInsights(
      tester,
      MinistryReportInsightsViewState.error,
    );

    final retry = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(retry.onPressed, isNull);
    expect(find.text('Unable to Load Insights'), findsOneWidget);
  });

  testWidgets(
    'Ministry Report Insights Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      await pumpMinistryReportInsights(
        tester,
        MinistryReportInsightsViewState.unauthorized,
      );
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets('Ministry Report Insights back arrow returns to Dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportInsightsScreen(onBack: () => backTapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  testWidgets(
    'Ministry Report Insights disables Focus Summary until I06 is available',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var focusSummaryTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryReportInsightsScreen(
            onViewFocusSummary: () => focusSummaryTapped = true,
            data: ministryReportInsightsFixture(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'View focus summary'),
      );
      expect(button.onPressed, isNull);
      expect(focusSummaryTapped, isFalse);
    },
  );

  // ---------------------------------------------------------------------
  // MIN-006 Ministry Profile
  // ---------------------------------------------------------------------

  for (final state in MinistryProfileViewState.values) {
    testWidgets('Ministry Profile renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryProfileScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Ministry Profile renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Ministry Profile has no bottom nav — it is a drill-down, not a tab',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
      expect(find.text('Municipalities'), findsNothing);
    },
  );

  testWidgets('Ministry Profile shows the full profile in its view state', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);
    // The person's name heads the hero; role and organization stay concise.
    expect(find.text('Ministry Supervisor'), findsOneWidget);
    expect(find.text('Public Works Ministry'), findsOneWidget);
    expect(find.text('Read-only supervisor'), findsOneWidget);
    expect(find.text('supervisor@ministry.gov'), findsNothing);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('+233 20 000 0000'), findsOneWidget);
    expect(find.text('MIN-000001'), findsOneWidget);
    expect(find.byType(ProfileEditButton), findsOneWidget);

    expect(find.text('Personal Information'), findsNothing);
    expect(find.text('Security'), findsNothing);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Two-factor authentication'), findsNothing);

    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);

    expect(find.text('Account Metadata'), findsNothing);
    expect(find.byTooltip('About Account Access'), findsOneWidget);
    expect(find.text('Supervisor'), findsNothing);
    expect(find.text('Read-only module'), findsNothing);
    expect(find.text('Analytics access'), findsNothing);

    expect(find.text('Session'), findsNothing);
    expect(find.text('Log out'), findsOneWidget);

    await tester.tap(find.byTooltip('About Account Access'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassDialogBackdrop), findsOneWidget);
    expect(find.text('Account Access'), findsOneWidget);
    expect(find.text('Supervisor'), findsOneWidget);
    expect(find.text('Read-only module'), findsOneWidget);
    expect(find.text('Analytics access'), findsOneWidget);
  });

  testWidgets('Ministry Profile avatar pencil opens the name-only editor', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // Only Full Name is editable — the phone is administrator-controlled
    // and never offered in the editor.
    final sheet = find.byType(BottomSheet);
    expect(
      find.descendant(of: sheet, matching: find.byType(TextField)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sheet, matching: find.text('+233 20 000 0000')),
      findsNothing,
    );
    expect(find.byIcon(AppIcons.more), findsNothing);
  });

  testWidgets(
    'Ministry Profile Save with an empty name shows a validation error and '
    'stays in the editor',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      // Still editing, not bounced back to the view state.
      expect(find.text('Save changes'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Profile Save with valid data shows the success banner and '
    'auto-reverts to the view state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.text('Edit profile'), findsNothing);
      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Updated Name'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Profile updated'), findsNothing);
    },
  );

  testWidgets(
    'Ministry Profile save failure keeps the editor open instead of the '
    'load-failure dialog',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryProfileScreen(onSaveProfile: (_) async => false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Changes not saved'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Updated Name'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Profile updated'), findsNothing);
    },
  );

  testWidgets('Ministry Profile Cancel discards edits and returns to view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Discarded Name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Ministry Supervisor'), findsOneWidget);
    expect(find.text('Discarded Name'), findsNothing);
    expect(find.text('Save changes'), findsNothing);
  });

  testWidgets('Ministry Profile system Back during edit also cancels', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryProfileScreen(onBack: () => backTapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Discarded Name');

    // Back closes the editor first; it does not leave the Profile.
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsNothing);
    expect(find.text('Discarded Name'), findsNothing);
    expect(backTapped, isFalse);
    expect(find.byIcon(AppIcons.back), findsOneWidget);
  });

  testWidgets('Ministry Profile Change Password fires onChangePassword', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryProfileScreen(onChangePassword: () => tapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Change password'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets(
    'Ministry Profile Validation shows the approved copy with an empty Full '
    'Name field',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryProfileScreen(
            initialState: MinistryProfileViewState.validation,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      final nameField = tester.widget<TextField>(find.byType(TextField).first);
      expect(nameField.controller?.text, isEmpty);
    },
  );

  testWidgets(
    'Ministry Profile Log out asks for confirmation before firing the '
    'callback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var loggedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryProfileScreen(onLogOut: () => loggedOut = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(loggedOut, isFalse);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(loggedOut, isTrue);
    },
  );

  testWidgets(
    'Ministry Profile Log Out confirmation Cancel does not fire the callback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var loggedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryProfileScreen(onLogOut: () => loggedOut = true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(loggedOut, isFalse);
      expect(find.text('Log out?'), findsNothing);
    },
  );

  Future<void> pumpMinistryProfile(
    WidgetTester tester,
    MinistryProfileViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryProfileScreen(initialState: state),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Ministry Profile Error shows a dialog over a dimmed, disabled backdrop',
    (WidgetTester tester) async {
      await pumpMinistryProfile(tester, MinistryProfileViewState.error);

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Back to Safety'), findsOneWidget);

      // The dimmed backdrop's body content is not interactive — tapping
      // the avatar pencil through it must not start an edit.
      await tester.tap(find.byTooltip('Edit profile'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Save changes'), findsNothing);
    },
  );

  testWidgets('Ministry Profile Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryProfile(tester, MinistryProfileViewState.offline);
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
    expect(find.text('Back to Safety'), findsOneWidget);
  });

  testWidgets(
    'Ministry Profile Unauthorized shows the approved copy with no retry '
    'action',
    (WidgetTester tester) async {
      await pumpMinistryProfile(tester, MinistryProfileViewState.unauthorized);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.text('Back to Safety'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    },
  );

  testWidgets(
    'Ministry Profile Retry moves the Error dialog through loading back to '
    'the view state',
    (WidgetTester tester) async {
      await pumpMinistryProfile(tester, MinistryProfileViewState.error);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Ministry Supervisor'), findsOneWidget);
    },
  );

  testWidgets('Ministry Profile Back to Safety returns to Dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryProfileScreen(
          initialState: MinistryProfileViewState.offline,
          onBack: () => backTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Back to Safety'));
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  testWidgets('Ministry Profile header back arrow returns to Dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryProfileScreen(onBack: () => backTapped = true),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  // ---------------------------------------------------------------------
  // Municipality Detail (Municipal Officer contact)
  // ---------------------------------------------------------------------

  const testMunicipality = RegionalLeaderItem(
    name: 'Accra Metropolitan',
    region: Region.greaterAccra,
    resolvedPercent: 92,
    responseTimeLabel: '14h',
    officerName: 'Kwame Owusu',
    officerPhone: '+233 24 555 0101',
  );

  testWidgets(
    'Ministry Municipality Detail shows the stats recap and officer contact '
    'card',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryMunicipalityDetailScreen(
            municipality: testMunicipality,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accra Metropolitan'), findsWidgets);
      expect(find.text('Greater Accra'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('Avg Response'), findsOneWidget);
      expect(find.text('14h'), findsOneWidget);

      expect(find.text('Municipal Officers'), findsOneWidget);
      expect(find.text('Kwame Owusu'), findsOneWidget);
      expect(find.textContaining('+233 24 555 0101'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);

      // Below the 75% resolvedPercent threshold that flips
      // RegionalLeaderItem.needsAttention — no badge for a municipality
      // that's doing fine.
      expect(find.text('Needs Attention'), findsNothing);
    },
  );

  testWidgets(
    'Ministry Municipality Detail flags a struggling municipality with a '
    'Needs Attention badge',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const strugglingMunicipality = RegionalLeaderItem(
        name: 'Jasikan Municipal',
        region: Region.oti,
        resolvedPercent: 62,
        responseTimeLabel: '41h',
        officerName: 'Ama Kudjo',
        officerPhone: '+233 24 555 0108',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryMunicipalityDetailScreen(
            municipality: strugglingMunicipality,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Needs Attention'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipality Detail Call/Message buttons surface an inline '
    'message when the launch fails',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final original = UrlLauncherPlatform.instance;
      UrlLauncherPlatform.instance = _FakeUrlLauncherPlatform(
        launchResult: false,
      );
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryMunicipalityDetailScreen(
            municipality: testMunicipality,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // A device/platform with no tel: handler returns false rather than
      // throwing — this confirms that surfaces as an inline message rather
      // than silently doing nothing.
      await tester.ensureVisible(find.text('Call'));
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Could not open'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Municipality Detail Call and Message buttons launch tel:/sms: '
    'with the officer\'s phone number, spaces stripped',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final original = UrlLauncherPlatform.instance;
      final fake = _FakeUrlLauncherPlatform();
      UrlLauncherPlatform.instance = fake;
      addTearDown(() => UrlLauncherPlatform.instance = original);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryMunicipalityDetailScreen(
            municipality: testMunicipality,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Call'));
      await tester.tap(find.text('Call'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Could not open'), findsNothing);
      expect(fake.lastLaunchedUri.toString(), 'tel:+233245550101');

      await tester.ensureVisible(find.text('Message'));
      await tester.tap(find.text('Message'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(fake.lastLaunchedUri.toString(), 'sms:+233245550101');
    },
  );

  testWidgets('Ministry Municipality Detail back arrow returns to caller', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryMunicipalityDetailScreen(
          municipality: testMunicipality,
          onBack: () => backTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.back));
    await tester.pumpAndSettle();

    expect(backTapped, isTrue);
  });

  testWidgets(
    'Ministry Notifications shows nationally resolved reports and marks '
    'them read on open',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MinistryNotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report resolved'), findsWidgets);
      expect(find.text('Sidewalk Crack was marked resolved.'), findsOneWidget);
    },
  );
}
