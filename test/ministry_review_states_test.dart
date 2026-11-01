import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_report_insights_screen.dart';

void main() {
  for (final screen in [
    'dashboard',
    'analytics',
    'performance',
    'reports',
    'insights',
  ]) {
    for (final state in ['loading', 'empty', 'error']) {
      for (final width in [320.0, 768.0]) {
        for (final dark in [false, true]) {
          for (final scale in [1.0, 2.0]) {
            testWidgets('$screen $state width=$width dark=$dark scale=$scale', (
              tester,
            ) async {
              tester.view.physicalSize = Size(width, 900);
              tester.view.devicePixelRatio = 1;
              tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              addTearDown(tester.view.resetPadding);
              final previous = FlutterError.onError;
              FlutterError.onError = (details) {
                debugPrint(details.toString());
                previous?.call(details);
              };
              addTearDown(() => FlutterError.onError = previous);
              final widget = switch (screen) {
                'dashboard' => MinistryDashboardScreen(
                  initialState: MinistryDashboardViewState.values.byName(state),
                ),
                'analytics' => MinistryAnalyticsScreen(
                  initialState: MinistryAnalyticsViewState.values.byName(state),
                ),
                'performance' => MinistryMunicipalPerformanceScreen(
                  initialState: MinistryMunicipalPerformanceViewState.values
                      .byName(state),
                ),
                'reports' => MinistryReportsScreen(
                  initialState: MinistryReportsViewState.values.byName(state),
                ),
                _ => MinistryReportInsightsScreen(
                  initialState: MinistryReportInsightsViewState.values.byName(
                    state,
                  ),
                ),
              };
              await tester.pumpWidget(
                MaterialApp(
                  theme: dark ? AppTheme.dark : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: widget,
                ),
              );
              // Loading skeletons animate indefinitely; inspect a concrete frame.
              await tester.pump(const Duration(milliseconds: 100));
              expect(tester.takeException(), isNull);
              final marker = state == 'loading'
                  ? null
                  : state == 'error'
                  ? switch (screen) {
                      'dashboard' => 'Unable to Load Dashboard',
                      'analytics' => 'Unable to Load Analytics',
                      'performance' => 'Unable to Load Performance',
                      'reports' => 'Unable to Load Reports',
                      _ => 'Unable to Load Insights',
                    }
                  : switch (screen) {
                      'dashboard' => 'Welcome to the national dashboard',
                      'analytics' => 'No Analytics Available',
                      'performance' => 'No Performance Data',
                      'reports' => 'No Reports',
                      _ => 'No Insights',
                    };
              if (marker != null) {
                expect(find.text(marker), findsOneWidget);
                await Scrollable.ensureVisible(
                  tester.element(find.text(marker)),
                  alignment: .5,
                );
                await tester.pump(const Duration(milliseconds: 100));
                expect(find.text(marker).hitTestable(), findsOneWidget);
              } else {
                expect(
                  find.byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_LoadingSkeleton',
                  ),
                  findsOneWidget,
                );
              }
              await tester.pumpWidget(const SizedBox.shrink());
              await tester.pump();
              expect(tester.takeException(), isNull);
            });
          }
        }
      }
    }
  }
}
