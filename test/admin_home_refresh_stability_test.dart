import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/screens/admin_overview_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'admin_live_overview_test.dart' show overviewFixture;

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'verified Home cards and scroll stay still during repeated refresh dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? owner = 'admin-A';
        Future<Map<String, dynamic>> Function() fetch = () async =>
            overviewFixture();
        final source = AdminResource<AdminOverview>(
          fetch: (_) => fetch(),
          parse: AdminOverview.parse,
          owner: () => owner,
          credential: () async => 'fixture',
        );
        addTearDown(source.dispose);
        void nothing() {}
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminOverviewScreen(
              directory: source,
              superAdmin: true,
              onUsers: nothing,
              onTeams: nothing,
              onActivity: nothing,
              onAlerts: nothing,
              onRoles: nothing,
              onSettings: nothing,
              onProfile: nothing,
              onNotifications: nothing,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final stats = find.byKey(const ValueKey('admin-overview-stats'));
        final element = tester.element(stats), rect = tester.getRect(stats);
        final scroll = tester
            .state<ScrollableState>(find.byType(Scrollable).last)
            .position;
        scroll.jumpTo(60);
        await tester.pumpAndSettle();
        final offset = scroll.pixels;
        final shiftedRect = tester.getRect(stats);
        for (var i = 0; i < 3; i++) {
          final pending = Completer<Map<String, dynamic>>();
          fetch = () => pending.future;
          final refreshing = source.load();
          await tester.pump();
          expect(find.byType(BusyIndicator), findsNothing);
          expect(tester.element(stats), same(element));
          expect(tester.getRect(stats), shiftedRect);
          expect(scroll.pixels, offset);
          pending.complete(overviewFixture());
          await refreshing;
          await tester.pumpAndSettle();
          expect(tester.getRect(stats), shiftedRect);
          expect(scroll.pixels, offset);
        }
        owner = 'admin-B';
        final pending = Completer<Map<String, dynamic>>();
        fetch = () => pending.future;
        final switched = source.load();
        await tester.pump();
        expect(find.text('1234'), findsNothing);
        expect(find.byType(BusyIndicator), findsNothing);
        expect(find.text('Loading overview'), findsOneWidget);
        pending.completeError(StateError('fixture failure'));
        await switched;
        await tester.pumpAndSettle();
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('1234'), findsNothing);
        expect(rect.width, 380);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
