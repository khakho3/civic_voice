import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/features/ministry/services/ministry_data_directory.dart';
import 'package:civic_voice/main.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().clearUser();
    MinistryDataDirectory.instance.clearSession();
  });
  tearDown(MinistryDataDirectory.instance.clearSession);

  for (final (route, screen, error) in [
    (
      AppRoutes.ministryAnalytics,
      MinistryAnalyticsScreen,
      'Unable to Load Analytics',
    ),
    (
      AppRoutes.ministryMunicipalPerformance,
      MinistryMunicipalPerformanceScreen,
      'Unable to Load Performance',
    ),
    (
      AppRoutes.ministryReports,
      MinistryReportsScreen,
      'Unable to Load Reports',
    ),
    (
      AppRoutes.ministryReportInsights,
      MinistryReportInsightsScreen,
      'Unable to Load Insights',
    ),
  ]) {
    testWidgets(
      '$route follows authoritative state even when the report list does not change',
      (tester) async {
        final directory = MinistryDataDirectory.instance;
        await tester.pumpWidget(CivicVoiceApp(initialRoute: route));
        await tester.pumpAndSettle();
        dynamic view() => tester.widget(find.byType(screen));
        expect((view().initialState as Enum).name, 'error');
        expect(view().data, isNull);
        expect(find.text(error), findsOneWidget);

        directory.state.value = MinistryDataDirectoryState.loading;
        await tester.pump();
        expect((view().initialState as Enum).name, 'loading');
        expect(find.text(error), findsNothing);
        directory.hasLiveSnapshot = true;
        directory.state.value = MinistryDataDirectoryState.loaded;
        await tester.pumpAndSettle();
        expect((view().initialState as Enum).name, 'loaded');
        expect(view().data, isNotNull);
        expect(find.text(error), findsNothing);

        directory.state.value = MinistryDataDirectoryState.failed;
        await tester.pumpAndSettle();
        expect((view().initialState as Enum).name, 'error');
        expect(find.text(error), findsOneWidget);
        expect(directory.hasLiveSnapshot, isTrue);
        expect(
          view().data,
          isNotNull,
          reason: 'A failed refresh does not erase the confirmed snapshot',
        );

        directory.state.value = MinistryDataDirectoryState.loaded;
        await tester.pumpAndSettle();
        expect(find.text(error), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
