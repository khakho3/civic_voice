import 'dart:async';

import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/ministry/screens/ministry_analytics_screen.dart';
import 'ministry_review_fixtures.dart';

void main() {
  testWidgets('Reports pull refresh failure remains visible and retryable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryReportsScreen(
          data: reviewDirectory().reportOverview,
          onRefresh: () async => throw StateError('Fixture network failure'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(150, 300), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Unable to Load Reports'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
  testWidgets(
    'Analytics retry handles failed refresh without an uncaught error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MinistryAnalyticsScreen(
            initialState: MinistryAnalyticsViewState.error,
            onRefresh: () async => throw StateError('Fixture offline'),
          ),
        ),
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Unable to Load Analytics'), findsOneWidget);
    },
  );
  testWidgets('Analytics accepts authoritative recovery on the same route', (
    tester,
  ) async {
    Future<void> show(MinistryAnalyticsViewState state) => tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MinistryAnalyticsScreen(
          initialState: state,
          data: reviewDirectory().analytics,
        ),
      ),
    );
    await show(MinistryAnalyticsViewState.error);
    await tester.pumpAndSettle();
    expect(find.text('Unable to Load Analytics'), findsOneWidget);
    await show(MinistryAnalyticsViewState.loaded);
    await tester.pumpAndSettle();
    expect(find.text('Unable to Load Analytics'), findsNothing);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets(
    'Analytics keeps filters through failed retry until parent recovery',
    (tester) async {
      var state = MinistryAnalyticsViewState.loaded;
      var failRefresh = true;
      final recovered = Completer<void>();
      late StateSetter updateParent;
      final data = reviewDirectory().analytics;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateParent = setState;
            return MaterialApp(
              theme: AppTheme.light,
              home: MinistryAnalyticsScreen(
                initialState: state,
                data: data,
                onRefresh: () async {
                  if (failRefresh) throw StateError('Fixture unavailable');
                  await recovered.future;
                  updateParent(() => state = MinistryAnalyticsViewState.loaded);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Status'));
      await tester.pumpAndSettle();
      updateParent(() => state = MinistryAnalyticsViewState.error);
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Analytics'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Analytics'), findsOneWidget);
      failRefresh = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.text('Unable to Load Analytics'), findsOneWidget);
      recovered.complete();
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Analytics'), findsNothing);
      expect(find.text('Status Distribution'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Reports keeps filters through failed retry until parent recovery',
    (tester) async {
      var state = MinistryReportsViewState.loaded;
      var failRefresh = true;
      final recovered = Completer<void>();
      late StateSetter updateParent;
      final data = reviewDirectory().reportOverview;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            updateParent = setState;
            return MaterialApp(
              theme: AppTheme.light,
              home: MinistryReportsScreen(
                initialState: state,
                data: data,
                onRefresh: () async {
                  if (failRefresh) throw StateError('Fixture unavailable');
                  await recovered.future;
                  updateParent(() => state = MinistryReportsViewState.loaded);
                },
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      updateParent(() => state = MinistryReportsViewState.error);
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Reports'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to Load Reports'), findsOneWidget);
      failRefresh = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.text('Unable to Load Reports'), findsOneWidget);
      recovered.complete();
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Reports'), findsNothing);
      expect(find.text('1 shown'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
