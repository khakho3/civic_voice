import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/models/admin_system_activity_data.dart';
import 'package:civic_voice/features/admin/screens/admin_overview_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/features/admin/widgets/admin_api_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'admin_live_overview_test.dart' show overviewFixture;

SystemHealthStats health({bool api = true, bool db = true}) =>
    SystemHealthStats(
      apiOnline: api,
      databaseOnline: db,
      dbLatencyMs: 5,
      uptimeSeconds: 900,
      checkedAt: DateTime(2026, 10, 24),
    );
void main() {
  setUp(() {
    final d = AdminSystemActivityDirectory.instance;
    final old = d.health.value;
    final live = d.hasLiveHealthSnapshot;
    addTearDown(() {
      d.hasLiveHealthSnapshot = live;
      d.health.value = old;
    });
  });
  for (final dark in [false, true]) {
    for (final width in [320.0, 448.0]) {
      for (final status in ['Online', 'Offline', 'Unavailable']) {
        testWidgets('live header badge $status $width dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 1000);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final d = AdminSystemActivityDirectory.instance;
          d.hasLiveHealthSnapshot = status != 'Unavailable';
          d.health.value = health(api: status == 'Online');
          final resource = AdminResource<AdminOverview>(
            owner: () => 'fixture-admin',
            credential: () async => 'fixture',
            fetch: (_) async => overviewFixture(),
            parse: AdminOverview.parse,
          );
          addTearDown(resource.dispose);
          var activity = 0;
          void nothing() {}
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: AdminOverviewScreen(
                directory: resource,
                superAdmin: true,
                onUsers: nothing,
                onTeams: nothing,
                onActivity: () => activity++,
                onAlerts: nothing,
                onRoles: nothing,
                onSettings: nothing,
                onProfile: nothing,
                onNotifications: nothing,
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('API: $status'), findsOneWidget);
          expect(find.text('API: Sample'), findsNothing);
          final heading = tester.getRect(find.text('Platform Overview'));
          final badge = tester.getRect(find.byType(AdminApiStatusBadge));
          expect(badge.left, greaterThanOrEqualTo(heading.right));
          expect(badge.right, lessThanOrEqualTo(width - 16));
          expect(
            tester
                .getSize(find.byKey(const ValueKey('admin-overview-stats')))
                .width,
            width - 32,
          );
          await tester.tap(find.text('API: $status'));
          await tester.pump();
          expect(activity, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'database failure is offline and reduced motion keeps glow static',
    (tester) async {
      Widget host({required bool reduced, required SystemHealthStats stats}) =>
          MaterialApp(
            theme: AppTheme.light,
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(body: AdminApiStatusBadge(stats: stats)),
            ),
          );
      final good = health();
      await tester.pumpWidget(host(reduced: false, stats: good));
      double blur() =>
          (tester
                      .widget<Container>(
                        find.byKey(const ValueKey('admin-api-status-dot')),
                      )
                      .decoration
                  as BoxDecoration)
              .boxShadow!
              .single
              .blurRadius;
      final initial = blur();
      await tester.pump(const Duration(milliseconds: 400));
      expect(blur(), greaterThan(initial));
      await tester.pumpWidget(host(reduced: true, stats: good));
      final still = blur();
      await tester.pump(const Duration(seconds: 1));
      expect(blur(), still);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.pumpWidget(host(reduced: true, stats: health(db: false)));
      expect(find.text('API: Offline'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ordinary Admin has no platform badge even with a verified national snapshot',
    (tester) async {
      final d = AdminSystemActivityDirectory.instance;
      d.hasLiveHealthSnapshot = true;
      d.health.value = health();
      final resource = AdminResource<AdminOverview>(
        owner: () => 'fixture-admin',
        credential: () async => 'fixture',
        fetch: (_) async => overviewFixture(),
        parse: AdminOverview.parse,
      );
      addTearDown(resource.dispose);
      void nothing() {}
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminOverviewScreen(
            directory: resource,
            superAdmin: false,
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
      expect(find.byType(AdminApiStatusBadge), findsNothing);
      expect(find.text('Assembly Overview'), findsOneWidget);
    },
  );
}
