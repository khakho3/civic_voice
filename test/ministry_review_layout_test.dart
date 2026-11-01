import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipality_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'ministry_review_fixtures.dart';

void main() {
  for (final screen in [
    'dashboard',
    'analytics',
    'performance',
    'detail',
    'reports',
    'insights',
  ]) {
    for (final width in [320.0, 390.0, 412.0, 768.0]) {
      for (final dark in [false, true]) {
        for (final scale in [1.0, 1.5, 2.0]) {
          testWidgets('$screen populated width=$width dark=$dark scale=$scale', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            final prior = FlutterError.onError;
            FlutterError.onError = (details) {
              debugPrint(details.toString());
              prior?.call(details);
            };
            addTearDown(() => FlutterError.onError = prior);
            final data = reviewDirectory();
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: switch (screen) {
                  'dashboard' => MinistryDashboardScreen(data: data.dashboard),
                  'analytics' => MinistryAnalyticsScreen(data: data.analytics),
                  'performance' => MinistryMunicipalPerformanceScreen(
                    data: data.performance,
                  ),
                  'detail' => const MinistryMunicipalityDetailScreen(
                    municipality: reviewMunicipality,
                  ),
                  'reports' => MinistryReportsScreen(data: data.reportOverview),
                  _ => MinistryReportInsightsScreen(data: data.insights),
                },
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final marker = switch (screen) {
              'performance' => '14%',
              'detail' => reviewMunicipality.name,
              'insights' => 'Infrastructure',
              _ => '7',
            };
            expect(
              find.text(marker).hitTestable(),
              findsWidgets,
              reason: 'The explicit fixture must visibly populate $screen',
            );
            final scroll = find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable &&
                      axisDirectionToAxis(w.axisDirection) == Axis.vertical,
                )
                .first;
            final position = tester.state<ScrollableState>(scroll).position;
            // Traverse the complete content, not just the initially built cards.
            while (position.pixels < position.maxScrollExtent) {
              position.jumpTo(
                (position.pixels + 300).clamp(0, position.maxScrollExtent),
              );
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            final record = switch (screen) {
              'dashboard' ||
              'performance' => data.performance.regionalLeaders.first.name,
              'detail' => reviewMunicipality.officerName,
              'reports' => data.reportOverview.reports.first.title,
              'insights' => '5 reports are in the open backlog',
              _ => data.analytics.trendInsight,
            };
            position.jumpTo(position.minScrollExtent);
            await tester.pumpAndSettle();
            final target = find.text(record);
            for (var step = 0; target.evaluate().isEmpty && step < 50; step++) {
              position.jumpTo(
                (position.pixels + 200).clamp(0, position.maxScrollExtent),
              );
              await tester.pumpAndSettle();
            }
            expect(target, findsWidgets);
            await Scrollable.ensureVisible(
              tester.element(target.first),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            // Header collapse can move the record after ensureVisible computes
            // its offset. Continue scrolling as a user would, then require the
            // record itself to be visible above the fixed navigation.
            for (
              var step = 0;
              target.hitTestable().evaluate().isEmpty &&
                  position.pixels < position.maxScrollExtent &&
                  step < 20;
              step++
            ) {
              await tester.drag(scroll, const Offset(0, -100));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
            }
            expect(
              target.hitTestable(),
              findsWidgets,
              reason:
                  'Record bounds ${tester.getRect(target.first)}, '
                  'scroll ${position.pixels}/${position.maxScrollExtent}',
            );
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
}
