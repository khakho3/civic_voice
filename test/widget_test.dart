import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';

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
    expect(find.text('Greater Accra'), findsOneWidget);
    expect(find.text('92% SLA compliance'), findsOneWidget);
    expect(find.text('Kumasi Metro'), findsOneWidget);
    expect(find.text('Tamale Metro'), findsOneWidget);
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
    expect(find.text('Retry'), findsOneWidget);
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

      expect(find.text('Dashboard'), findsOneWidget);
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

  testWidgets('Ministry Dashboard "View All" fires the same callback as the '
      'Reports tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var reportsTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryDashboardScreen(
          onNavigateToReports: () => reportsTapped = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('View All'));
    await tester.pumpAndSettle();

    expect(reportsTapped, isTrue);
  });

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

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      await tester.tap(find.text('Dashboard'));
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
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Top 10'), findsOneWidget);

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
      expect(find.text('Greater Accra'), findsOneWidget);
      expect(find.text('92% resolved · 14h response'), findsOneWidget);
      expect(find.text('Kumasi Metro'), findsOneWidget);
      expect(find.text('Tamale Metro'), findsOneWidget);

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
      expect(find.text('Greater Accra'), findsOneWidget);
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

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);

      await tester.tap(find.text('Dashboard'));
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
      // Each of these also labels a status badge on one of the report
      // cards below, in addition to its own filter chip — "Submitted"
      // (chip + Pothole's badge), "Resolved" (chip + stat card label +
      // Broken Streetlight's + Damaged Footbridge's badges). "Review" is
      // chip-only: badges spell out "Under Review" in full, a different
      // string.
      expect(find.text('Submitted'), findsNWidgets(2));
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Resolved'), findsNWidgets(4));

      expect(find.text('Aggregated Reports'), findsOneWidget);
      expect(find.text('24,812'), findsOneWidget);
      expect(
        find.text('National report volume · current period'),
        findsOneWidget,
      );
      // Stat card label + Overflowing Drainage's status badge.
      expect(find.text('Under Review'), findsNWidgets(2));
      expect(find.text('3,248'), findsOneWidget);
      expect(find.text('18,604'), findsOneWidget);

      expect(find.text('7 shown'), findsOneWidget);
      expect(find.text('Pothole on Main Street'), findsOneWidget);
      expect(
        find.text('Accra Municipal · Road Infrastructure'),
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

    expect(find.text('1 shown'), findsOneWidget);
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

      expect(find.text('7 shown'), findsOneWidget);
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

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Municipalities'), findsOneWidget);

      await tester.tap(find.text('Dashboard'));
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
}
