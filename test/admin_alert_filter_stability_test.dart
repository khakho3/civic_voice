import 'dart:async';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/screens/admin_alerts_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:civic_voice/widgets/focused_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_live_overview_test.dart' show alertFixture;

Map<String, dynamic> alertsPage(String prefix, {int count = 20}) => {
  'alerts': [
    for (var i = 0; i < count; i++)
      {...alertFixture(), 'id': 'event-$i', 'title': '$prefix $i'},
  ],
  'total': count,
  'nextCursor': null,
};
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'alert-stability');
  });
  for (final dark in [false, true]) {
    testWidgets(
      'matching cards and filter controls stay stable during rapid server filtering dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? owner = 'admin-A';
        final open = Completer<Map<String, dynamic>>(),
            all = Completer<Map<String, dynamic>>();
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminAlertsScreen(
              resourceFactory: (state, _, _) => AdminResource<AdminAlertPage>(
                owner: () => owner,
                credential: () async => 'fixture',
                fetch: (_) => state == 'ACTIVE'
                    ? Future.value(alertsPage('Verified'))
                    : state == 'OPEN'
                    ? open.future
                    : all.future,
                parse: AdminAlertPage.parse,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final before = tester.getTopLeft(find.text('Verified 0'));
        await tester.tap(find.widgetWithText(CivicFilterChip, 'Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.getTopLeft(find.text('Verified 0')).dy, before.dy);
        expect(find.byType(BusyIndicator), findsNothing);
        expect(find.text('20 matching alerts'), findsNothing);
        expect(
          tester
              .widget<CivicFilterChip>(
                find.widgetWithText(CivicFilterChip, 'Acknowledged'),
              )
              .onTap,
          isNotNull,
        );
        // A second choice can replace the pending request without a disabled fade.
        final filters = find.byType(SingleChildScrollView).first;
        await tester.drag(filters, const Offset(-700, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(CivicFilterChip, 'All alerts'));
        await tester.pump();
        all.complete(alertsPage('Current'));
        await tester.pumpAndSettle();
        expect(find.text('Current 0'), findsOneWidget);
        open.complete(alertsPage('Stale'));
        await tester.pumpAndSettle();
        expect(find.text('Stale 0'), findsNothing);
        expect(find.text('Current 0'), findsOneWidget);
        final scroll = tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .where(
              (s) =>
                  axisDirectionToAxis(s.position.axisDirection) ==
                  Axis.vertical,
            )
            .last;
        scroll.position.jumpTo(700);
        await tester.pumpAndSettle();
        final offset = scroll.position.pixels;
        await tester.tap(find.byType(SearchTriggerField));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Close search'));
        await tester.pumpAndSettle();
        expect(scroll.position.pixels, offset);
        owner = 'admin-B';
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'pending filter cannot show another owner cached rows or an unverified empty state',
    (tester) async {
      String? owner = 'admin-A';
      final pending = Completer<Map<String, dynamic>>();
      AdminAlertsScreen screen() => AdminAlertsScreen(
        resourceFactory: (state, _, _) => AdminResource<AdminAlertPage>(
          owner: () => owner,
          credential: () async => 'fixture',
          fetch: (_) => state == 'ACTIVE'
              ? Future.value(alertsPage('Private', count: 1))
              : pending.future,
          parse: AdminAlertPage.parse,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: screen()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(CivicFilterChip, 'Open'));
      await tester.pump();
      owner = 'admin-B';
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: screen()),
      );
      await tester.pump();
      expect(find.text('Private 0'), findsNothing);
      expect(find.text('No alerts match these filters.'), findsNothing);
      pending.complete(alertsPage('Late', count: 1));
      await tester.pumpAndSettle();
      expect(find.text('Late 0'), findsNothing);
    },
  );
  testWidgets(
    'a confirmed empty filter releases the preserved range and keeps search reachable',
    (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminAlertsScreen(
            resourceFactory: (state, _, _) => AdminResource<AdminAlertPage>(
              owner: () => 'admin-A',
              credential: () async => 'fixture',
              fetch: (_) => state == 'ACTIVE'
                  ? Future.value(alertsPage('Verified'))
                  : pending.future,
              parse: AdminAlertPage.parse,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final scroll = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .where(
            (s) =>
                axisDirectionToAxis(s.position.axisDirection) == Axis.vertical,
          )
          .last;
      scroll.position.jumpTo(700);
      await tester.pumpAndSettle();
      final offset = scroll.position.pixels;
      await tester.ensureVisible(find.widgetWithText(CivicFilterChip, 'Open'));
      await tester.tap(find.widgetWithText(CivicFilterChip, 'Open'));
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, offset);
      pending.complete({'alerts': [], 'total': 0, 'nextCursor': null});
      await tester.pumpAndSettle();
      expect(find.text('No alerts match these filters.'), findsOneWidget);
      expect(scroll.position.pixels, 0);
      expect(find.byType(SearchTriggerField).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
