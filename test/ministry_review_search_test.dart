import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'ministry_review_fixtures.dart';

void main() {
  for (final width in [320.0, 390.0, 412.0, 768.0]) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.5, 2.0]) {
        testWidgets(
          'Reports search keyboard width=$width dark=$dark scale=$scale',
          (tester) async {
            SharedPreferences.setMockInitialValues({});
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(tester.view.resetPadding);
            addTearDown(tester.view.resetViewInsets);
            final data = reviewDirectory().reportOverview;
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark : AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: MinistryReportsScreen(data: data),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.text('Search aggregated reports'));
            await tester.pumpAndSettle();
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.enterText(find.byType(TextField), 'submitted');
            await tester.pumpAndSettle();
            expect(
              find.text(data.reports.first.title).hitTestable(),
              findsWidgets,
            );
            expect(tester.takeException(), isNull);
            await tester.testTextInput.receiveAction(TextInputAction.search);
            tester.view.resetViewInsets();
            await tester.pumpAndSettle();
            expect(find.text('1 shown'), findsOneWidget);
            expect(
              find.text('7'),
              findsOneWidget,
              reason: 'Search must not change national totals',
            );
            await tester.tap(find.text('submitted').first);
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField), 'no-fixture-match');
            await tester.testTextInput.receiveAction(TextInputAction.search);
            await tester.pumpAndSettle();
            expect(
              find.text('No reports match your search or filter.'),
              findsOneWidget,
            );
            await tester.ensureVisible(find.text('Clear'));
            await tester.pumpAndSettle();
            await tester.tap(find.text('Clear'));
            await tester.pumpAndSettle();
            final vertical = find
                .byWidgetPredicate(
                  (w) =>
                      w is Scrollable &&
                      axisDirectionToAxis(w.axisDirection) == Axis.vertical,
                )
                .first;
            final position = tester.state<ScrollableState>(vertical).position;
            position.jumpTo(position.minScrollExtent);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('7 shown'),
              150,
              scrollable: vertical,
            );
            expect(find.text('7 shown'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
