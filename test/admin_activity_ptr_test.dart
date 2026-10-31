import 'dart:async';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/services/admin_activity_repository.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/search_filter_list.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'admin_activity_contract_test.dart' show auditPageFixture;

Finder activityProgressBars() => find.byWidgetPredicate(
  (widget) => widget.runtimeType.toString() == '_GhanaLinearProgress',
);

Finder activityStars() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter.runtimeType.toString() == '_StarPainter',
);

Future<void> pullActivity(WidgetTester tester) async {
  final state = tester.state<CustomRefreshIndicatorState>(
    find.byType(CustomRefreshIndicator),
  );
  unawaited(state.refresh(draggingDuration: Duration.zero));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() async {
    ApiClient.baseUrl = 'http://127.0.0.1:1';
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'activity-ptr');
  });
  for (final dark in [false, true]) {
    testWidgets(
      'slow initial Activity pull has only the top indicator dark=$dark',
      (tester) async {
        final first = Completer<Map<String, dynamic>>();
        final refresh = Completer<Map<String, dynamic>>();
        var calls = 0;
        final repo = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'fixture',
          list: (_, _) => ++calls == 1 ? first.future : refresh.future,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminSystemActivityScreen(repository: repo),
          ),
        );
        await tester.pump();
        expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
        expect(activityStars(), findsNothing);
        expect(
          tester.getSize(find.byType(GhanaLoadingIndicator)).height,
          lessThan(60),
        );
        await pullActivity(tester);
        expect(calls, 2);
        final controller = tester
            .state<CustomRefreshIndicatorState>(
              find.byType(CustomRefreshIndicator),
            )
            .controller;
        expect(controller.isLoading, true);
        expect(activityStars(), findsNothing);
        expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
        expect(activityProgressBars(), findsOneWidget);
        expect(
          tester.getTopLeft(activityProgressBars()).dy,
          closeTo(
            tester.getTopLeft(find.byType(GhanaRefreshIndicator)).dy,
            0.1,
          ),
        );
        first.complete(auditPageFixture(id: 'stale-first'));
        await tester.pump();
        expect(activityProgressBars(), findsOneWidget);
        refresh.complete(auditPageFixture(id: 'fresh'));
        await tester.pumpAndSettle();
        expect(activityProgressBars(), findsNothing);
        expect(activityStars(), findsNothing);
        expect(find.text('Account access updated'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'initial Activity loading status has no central animation dark=$dark',
      (tester) async {
        final first = Completer<Map<String, dynamic>>();
        var calls = 0;
        final repo = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'fixture',
          list: (_, _) {
            calls++;
            return first.future;
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminSystemActivityScreen(repository: repo),
          ),
        );
        await tester.pump();
        expect(activityProgressBars(), findsNothing);
        expect(calls, 1);
        expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
        first.complete(auditPageFixture());
        await tester.pumpAndSettle();
        expect(find.byType(GhanaLoadingIndicator), findsNothing);
      },
    );

    testWidgets(
      'Activity filter loading and retry never insert a page star dark=$dark',
      (tester) async {
        var pending = Completer<Map<String, dynamic>>();
        var calls = 0;
        final repo = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'fixture',
          list: (_, _) =>
              ++calls == 1 ? Future.value(auditPageFixture()) : pending.future,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminSystemActivityScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(CivicFilterChip, 'System Updates'),
        );
        await tester.pumpAndSettle();
        expect(calls, 2);
        expect(activityStars(), findsNothing);
        expect(activityProgressBars(), findsNothing);
        expect(find.text('Loading activity'), findsOneWidget);
        // A different query must not claim the previous query's count or cards.
        expect(find.text('Audit history'), findsNothing);
        expect(find.text('Account access updated'), findsNothing);
        pending.completeError(
          const ApiException(statusCode: 503, message: 'fixture outage'),
        );
        await tester.pumpAndSettle();
        expect(find.text('Activity could not be verified.'), findsOneWidget);
        pending = Completer<Map<String, dynamic>>();
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
        expect(calls, 3);
        expect(activityStars(), findsNothing);
        expect(activityProgressBars(), findsNothing);
        expect(find.text('Loading activity'), findsOneWidget);
        pending.complete(auditPageFixture());
        await tester.pumpAndSettle();
        expect(find.text('Audit history'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'repeated Activity PTR lifecycle retains cards and one top bar on failure dark=$dark',
      (tester) async {
        var pending = Completer<Map<String, dynamic>>();
        var calls = 0;
        final repo = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'fixture',
          list: (_, _) =>
              ++calls == 1 ? Future.value(auditPageFixture()) : pending.future,
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminSystemActivityScreen(repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final rail = tester.element(find.byType(SearchFilterList));
        final card = tester.element(find.text('Account access updated'));
        final cardRect = tester.getRect(find.text('Account access updated'));
        for (var i = 0; i < 2; i++) {
          pending = Completer<Map<String, dynamic>>();
          await pullActivity(tester);
          expect(activityProgressBars(), findsOneWidget);
          expect(find.byType(GhanaLoadingIndicator), findsNothing);
          expect(activityStars(), findsNothing);
          expect(find.text('Updating activity…'), findsNothing);
          expect(tester.getRect(find.text('Account access updated')), cardRect);
          expect(tester.element(find.byType(SearchFilterList)), same(rail));
          expect(
            tester.element(find.text('Account access updated')),
            same(card),
          );
          if (i == 1) {
            pending.completeError(
              const ApiException(statusCode: 503, message: 'fixture outage'),
            );
          } else {
            pending.complete(auditPageFixture());
          }
          await tester.pumpAndSettle();
          expect(activityProgressBars(), findsNothing);
          if (i == 0) {
            expect(find.text('Account access updated'), findsOneWidget);
          }
        }
      },
    );
  }
}
