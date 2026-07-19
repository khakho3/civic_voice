import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/models/municipal_performance_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipality_detail_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_notifications_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/models/region.dart';

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
      MaterialApp(theme: AppTheme.light, home: const MinistryDashboardScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('Ministry Supervisor'), findsOneWidget);
    expect(find.text('National Dashboard'), findsOneWidget);

    expect(find.text('Total Reports'), findsOneWidget);
    expect(find.text('24.8K'), findsOneWidget);
    // Appears on both the stat card and the Quick Insights card.
    expect(find.text('Under Review'), findsNWidgets(2));
    expect(find.text('Resolved'), findsOneWidget);
    expect(find.text('18.6K'), findsOneWidget);
    // Appears on both the stat card and the bottom-nav tab label.
    expect(find.text('Municipalities'), findsNWidgets(2));
    expect(find.text('216'), findsOneWidget);

    expect(find.text('Report Statistics'), findsOneWidget);
    expect(find.text('Jan–Jun reports'), findsOneWidget);

    expect(find.text('Quick Insights'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Assigned'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);

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

  testWidgets('Ministry Dashboard Empty shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpMinistryDashboard(tester, MinistryDashboardViewState.empty);
    expect(find.text('No Analytics Available'), findsOneWidget);
    // Matches every other Ministry screen's Empty-state button label —
    // this used to say "Retry" here alone, a real inconsistency, not a
    // deliberate per-screen wording choice.
    expect(find.text('Refresh'), findsOneWidget);
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

  testWidgets('Ministry routes connect Dashboard, Analytics, Insights, '
      'Municipalities, Reports, and Profile', (WidgetTester tester) async {
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

    await tester.tap(find.text('Trend Insights'));
    await advanceRoute();

    expect(find.text('Report Insights'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.back));
    await advanceRoute();

    expect(find.text('Analytics Dashboard'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.municipality).last);
    await advanceRoute();

    expect(find.text('Municipal Performance'), findsOneWidget);

    await tester.tap(find.text('Accra Metropolitan'));
    await advanceRoute();

    expect(find.text('Municipal Officers'), findsOneWidget);
    expect(find.text('Kwame Owusu'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.back));
    await advanceRoute();

    expect(find.text('Municipal Performance'), findsOneWidget);

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
          home: MinistryAnalyticsScreen(initialState: state),
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
          home: const MinistryAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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
          home: const MinistryAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Municipality'), findsOneWidget);

      expect(find.text('Total Reports'), findsOneWidget);
      expect(find.text('12,482'), findsOneWidget);
      expect(find.text('Resolution Rate'), findsOneWidget);
      expect(find.text('74.8%'), findsOneWidget);

      expect(find.text('Report Trends'), findsOneWidget);
      expect(find.text('01 May'), findsOneWidget);
      expect(find.text('30 May'), findsOneWidget);

      expect(find.text('Category Distribution'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsOneWidget);
      expect(find.text('68%'), findsOneWidget);
      expect(find.text('Sanitation'), findsOneWidget);
      expect(find.text('Water Services'), findsOneWidget);

      expect(find.text('Report Status'), findsOneWidget);
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
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
          home: const MinistryAnalyticsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Category Distribution'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsOneWidget);

      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();

      expect(find.text('Status Distribution'), findsOneWidget);
      expect(find.text('Road Infrastructure'), findsNothing);

      await tester.tap(find.text('Municipality'));
      await tester.pumpAndSettle();

      expect(find.text('Municipality Distribution'), findsOneWidget);
      // Reuses the exact figures from MIN-001 Dashboard's Municipality
      // Performance list, so the same entity reads consistently.
      expect(find.text('Greater Accra'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
    },
  );

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
        home: MinistryAnalyticsScreen(initialState: state),
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

    expect(find.text('Category Distribution'), findsOneWidget);
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
            home: MinistryMunicipalPerformanceScreen(initialState: state),
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
          home: const MinistryMunicipalPerformanceScreen(),
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
          home: const MinistryMunicipalPerformanceScreen(),
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
      expect(find.text('1.2K'), findsOneWidget);

      expect(find.text('Regional Leaders'), findsOneWidget);
      // One real assembly per Ghana region (16) — enough national volume
      // for the region picker and Top 10/Needs Attention scope to do real
      // filtering, unlike the three placeholder entries this replaced.
      expect(find.text('16 shown'), findsOneWidget);
      expect(find.text('Accra Metropolitan'), findsOneWidget);
      expect(
        find.text('Greater Accra · 92% resolved · 14h response'),
        findsOneWidget,
      );
      expect(find.text('Kumasi Metropolitan'), findsOneWidget);
      expect(find.text('Tamale Metropolitan'), findsOneWidget);

      expect(find.text('Efficiency Trend'), findsOneWidget);
      expect(
        find.text('Last 7 reporting periods · aggregated only'),
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
          home: const MinistryMunicipalPerformanceScreen(),
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
        home: const MinistryMunicipalPerformanceScreen(),
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
        home: MinistryMunicipalPerformanceScreen(initialState: state),
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

  testWidgets(
    'Ministry Reports Overview shows the full report list in its loaded '
    'state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryReportsScreen()),
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
      expect(find.text('Submitted'), findsNWidgets(5));
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Resolved'), findsNWidgets(6));

      expect(find.text('Aggregated Reports'), findsOneWidget);
      expect(find.text('24,812'), findsOneWidget);
      expect(
        find.text('National report volume · current period'),
        findsOneWidget,
      );
      // Stat card label + 4 underReview badges.
      expect(find.text('Under Review'), findsNWidgets(5));
      expect(find.text('3,248'), findsOneWidget);
      expect(find.text('18,604'), findsOneWidget);

      // Spans all 16 regions, same national volume as Municipal
      // Performance's Regional Leaders list.
      expect(find.text('20 shown'), findsOneWidget);
      expect(find.text('Pothole on Main Street'), findsOneWidget);
      expect(
        find.text('Accra Metropolitan · Road Infrastructure'),
        findsOneWidget,
      );
      // Several of the 20 mock reports happen to share a relative-time
      // label ("2 days ago") now that there's real national volume —
      // just confirming the date renders at all, not counting collisions.
      expect(find.text('2 days ago'), findsWidgets);
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
        MaterialApp(theme: AppTheme.light, home: const MinistryReportsScreen()),
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
      MaterialApp(theme: AppTheme.light, home: const MinistryReportsScreen()),
    );
    await tester.pumpAndSettle();

    // "Review" is chip-only — unlike "Submitted"/"Resolved", no status
    // badge spells out that exact string ("Under Review" is a different
    // string), so this is unambiguous without needing .first/.last.
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();

    expect(find.text('4 shown'), findsOneWidget);
    expect(find.text('Overflowing Drainage'), findsOneWidget);
    expect(find.text('Pothole on Main Street'), findsNothing);
  });

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
        home: MinistryReportsScreen(initialState: state),
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

      expect(find.text('20 shown'), findsOneWidget);
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
          home: const MinistryReportInsightsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report Insights'), findsOneWidget);
      expect(find.text('30 days'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      expect(find.text('Category Peak'), findsOneWidget);
      expect(find.text('Sanitation'), findsOneWidget);
      expect(find.text('31% share'), findsOneWidget);
      expect(find.text('Resolution'), findsOneWidget);
      expect(find.text('74%'), findsOneWidget);
      expect(find.text('+6.2%'), findsOneWidget);

      expect(find.text('Critical Insights'), findsOneWidget);
      expect(find.text('Sanitation reports are rising'), findsOneWidget);
      expect(find.text('+18% from previous period'), findsOneWidget);
      expect(find.text('Resolution pace improved'), findsOneWidget);
      expect(find.text('Infrastructure needs focus'), findsOneWidget);

      expect(find.text('Strategic Focus'), findsOneWidget);
      expect(find.text('View focus summary'), findsOneWidget);
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
          home: const MinistryReportInsightsScreen(),
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
        home: const MinistryReportInsightsScreen(),
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
        home: MinistryReportInsightsScreen(initialState: state),
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
    'Ministry Report Insights "View focus summary" fires the callback',
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
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View focus summary'));
      await tester.pumpAndSettle();

      expect(focusSummaryTapped, isTrue);
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
    // Also appears a second time in the Personal Information field row
    // below the header card.
    expect(find.text('Ministry Supervisor'), findsNWidgets(2));
    expect(find.text('Public Works Ministry'), findsOneWidget);
    expect(find.text('Read-only supervisor'), findsOneWidget);
    expect(find.text('supervisor@ministry.gov'), findsNothing);
    expect(find.text('ID MIN-000001'), findsOneWidget);
    expect(find.text('+233 20 000 0000'), findsOneWidget);

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);

    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Two-factor authentication'), findsNothing);

    expect(find.text('System Preferences'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Coming Soon'), findsOneWidget);

    expect(find.text('Account Metadata'), findsOneWidget);
    expect(find.text('Supervisor'), findsOneWidget);
    expect(find.text('Read-only module'), findsOneWidget);
    expect(find.text('Analytics access'), findsOneWidget);

    // Log Out lives in the header kebab menu now, not a standalone row —
    // not visible until the menu is opened.
    expect(find.text('Log Out'), findsNothing);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('Ministry Profile kebab menu Edit Profile enters edit mode', (
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

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    // Only Full Name is actually editable — Email/Phone render as plain
    // captioned text (admin-provisioned, not self-service), matching
    // Admin/Municipal Officer's own profile forms.
    expect(find.byType(TextField), findsNWidgets(1));
    expect(find.byIcon(AppIcons.close), findsOneWidget);
  });

  testWidgets(
    'Ministry Profile Save with an empty name shows a validation error and '
    'stays in edit mode',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required.'), findsOneWidget);
      // Still editing, not bounced back to the view state.
      expect(find.text('Save Changes'), findsOneWidget);
    },
  );

  testWidgets(
    'Ministry Profile Save with valid data moves through loading to success '
    'and auto-reverts to the view state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MinistryProfileScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Updated Name');
      await tester.tap(find.text('Save'));
      // Bounded pumps rather than pumpAndSettle: the loading skeleton's
      // shimmer never settles on its own (matches every other screen's
      // loading state).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Updated Name'), findsNWidgets(2));

      await tester.pump(const Duration(seconds: 4));
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

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Discarded Name');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Ministry Supervisor'), findsNWidgets(2));
    expect(find.text('Discarded Name'), findsNothing);
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('Ministry Profile header close icon during edit also cancels', (
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

    await tester.tap(find.byIcon(AppIcons.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(AppIcons.close));
    await tester.pumpAndSettle();

    expect(find.text('Save Changes'), findsNothing);
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

    await tester.tap(find.text('Change Password'));
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
    'Ministry Profile kebab menu Log Out asks for confirmation before '
    'firing the callback',
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

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(loggedOut, isFalse);

      // "Log Out" appears both on the (now closed) kebab item and as the
      // dialog's confirm button — the confirm button is built last.
      await tester.tap(find.text('Log Out').last);
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

      await tester.tap(find.byIcon(AppIcons.more));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
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
      // through it must not start an edit. (The kebab menu itself lives in
      // the header, outside the dimmed region, so it isn't blocked.)
      await tester.tap(find.text('Personal Information'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Save Changes'), findsNothing);
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
      expect(find.text('Ministry Supervisor'), findsNWidgets(2));
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
