import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'ministry_widget_test.dart'
    show
        ministryAnalyticsFixture,
        ministryMunicipalPerformanceFixture,
        ministryReportInsightsFixture;

void main() {
  final screens = <String, Widget Function()>{
    'Analytics': () =>
        MinistryAnalyticsScreen(data: ministryAnalyticsFixture()),
    'Performance': () => MinistryMunicipalPerformanceScreen(
      data: ministryMunicipalPerformanceFixture(),
    ),
    'Insights': () =>
        MinistryReportInsightsScreen(data: ministryReportInsightsFixture()),
  };
  for (final entry in screens.entries) {
    for (final width in [320.0, 390.0, 412.0, 1440.0]) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key} shared filters $width dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: entry.value(),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CivicFilterChip), findsWidgets);
          final first = find.byType(CivicFilterChip).first;
          expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
          if (entry.key == 'Analytics') {
            await tester.tap(find.widgetWithText(CivicFilterChip, 'Status'));
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<CivicFilterChip>(
                    find.widgetWithText(CivicFilterChip, 'Status'),
                  )
                  .selected,
              isTrue,
            );
          } else {
            await tester.tap(first);
            await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsOneWidget);
            // Inspecting/dismissing a picker must not select a new value.
            await tester.binding.handlePopRoute();
            await tester.pumpAndSettle();
            expect(find.byType(BottomSheet), findsNothing);
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
