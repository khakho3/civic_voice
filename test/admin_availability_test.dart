import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/screens/admin_overview_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/features/admin/services/admin_read_failure.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/widgets/app_state_message.dart';
import 'admin_live_overview_test.dart' show overviewFixture;

Map<String, dynamic> healthy() => {
  'apiOnline': true,
  'databaseOnline': true,
  'dbLatencyMs': 5,
  'uptimeSeconds': 60,
  'checkedAt': '2026-10-24T12:00:00Z',
};
AdminSystemActivityDirectory healthDirectory(
  Future<Map<String, dynamic>> Function(String) fetch,
) => AdminSystemActivityDirectory.forTesting(
  firebaseAvailable: () => true,
  tokenProvider: () async => 'fixture',
  activityFetcher: (_) async => [],
  healthFetcher: fetch,
  isSuperAdmin: () => true,
);
Widget host(
  AdminResource<AdminOverview> source,
  AdminSystemActivityDirectory health, {
  bool dark = false,
  double textScale = 1,
}) {
  void nothing() {}
  return MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: AdminOverviewScreen(
      directory: source,
      healthDirectory: health,
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
  );
}

void main() {
  test(
    'failure categories keep unreachable service separate from authorization and unverified data',
    () {
      expect(
        classifyAdminReadFailure(const SocketException('fixture')),
        AdminReadFailure.unreachable,
      );
      expect(
        classifyAdminReadFailure(TimeoutException('fixture')),
        AdminReadFailure.unreachable,
      );
      for (final status in [0, 408]) {
        expect(
          classifyAdminReadFailure(
            ApiException(statusCode: status, message: 'private fixture'),
          ),
          AdminReadFailure.unreachable,
        );
      }
      expect(
        classifyAdminReadFailure(
          const ApiException(statusCode: 503, message: 'private fixture'),
        ),
        AdminReadFailure.service,
      );
      for (final status in [401, 403]) {
        expect(
          classifyAdminReadFailure(
            ApiException(statusCode: status, message: 'private fixture'),
          ),
          AdminReadFailure.unauthorized,
        );
      }
      expect(
        classifyAdminReadFailure(const FormatException('private fixture')),
        AdminReadFailure.unverified,
      );
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'health outage hides cached Home cards, shows API Offline and centred Retry, then recovers both reads dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var stopped = false, overviewCalls = 0, healthCalls = 0;
        final source = AdminResource<AdminOverview>(
          owner: () => 'fixture',
          credential: () async => 'fixture',
          fetch: (_) async {
            overviewCalls++;
            if (stopped) {
              throw const ApiException(
                statusCode: 0,
                message: 'private fixture',
              );
            }
            return {
              ...overviewFixture(),
              'totalUsers': overviewCalls == 1 ? 1234 : 99,
            };
          },
          parse: AdminOverview.parse,
        );
        addTearDown(source.dispose);
        final health = healthDirectory((_) async {
          healthCalls++;
          if (stopped) {
            throw const ApiException(statusCode: 0, message: 'private fixture');
          }
          return healthy();
        });
        await tester.pumpWidget(host(source, health, dark: dark));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('1234'), findsOneWidget);
        expect(find.text('API: Online'), findsOneWidget);
        stopped = true;
        await health.refreshHealth();
        await tester.pump();
        expect(source.data?.totalUsers, 1234);
        expect(find.text('1234'), findsNothing);
        expect(find.text('API: Offline'), findsOneWidget);
        expect(find.text('Cannot reach CivicVoice'), findsOneWidget);
        expect(find.byType(AppStateMessage), findsOneWidget);
        expect(
          tester.getCenter(find.byType(AppStateMessage)).dy,
          inInclusiveRange(250, 750),
        );
        expect(find.text("You're offline"), findsNothing);
        expect(find.textContaining('private fixture'), findsNothing);
        final beforeOverview = overviewCalls, beforeHealth = healthCalls;
        stopped = false;
        await tester.tap(find.text('Retry'));
        await tester.pump(const Duration(milliseconds: 200));
        expect(overviewCalls, beforeOverview + 1);
        expect(healthCalls, beforeHealth + 1);
        expect(find.text('99'), findsOneWidget);
        expect(find.text('API: Online'), findsOneWidget);
        expect(find.byType(AppStateMessage), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final entry in [
    (
      const ApiException(statusCode: 0, message: 'private fixture'),
      'Cannot reach CivicVoice',
      'Offline',
    ),
    (
      const ApiException(statusCode: 503, message: 'private fixture'),
      'Service unavailable',
      'Offline',
    ),
    (
      const ApiException(statusCode: 403, message: 'private fixture'),
      'Administrative access required',
      'Unavailable',
    ),
    (
      const FormatException('private fixture'),
      'Unable to load dashboard',
      'Unavailable',
    ),
  ]) {
    testWidgets(
      'cold failure ${entry.$2} has truthful state and no raw error',
      (tester) async {
        tester.view.physicalSize = const Size(320, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final source = AdminResource<AdminOverview>(
          owner: () => 'fixture',
          credential: () async => 'fixture',
          fetch: (_) async => throw entry.$1,
          parse: AdminOverview.parse,
        );
        addTearDown(source.dispose);
        final health = healthDirectory((_) async => throw entry.$1);
        await tester.pumpWidget(host(source, health, textScale: 1.5));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text(entry.$2), findsOneWidget);
        expect(find.text('API: ${entry.$3}'), findsOneWidget);
        expect(find.textContaining('private fixture'), findsNothing);
        expect(find.text("You're offline"), findsNothing);
        expect(
          find.byKey(const ValueKey('admin-overview-stats')),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'newer successful health clears stale Offline without inventing overview data',
    (tester) async {
      var stopped = true;
      final source = AdminResource<AdminOverview>(
        owner: () => 'fixture',
        credential: () async => 'fixture',
        fetch: (_) async {
          if (stopped)
            throw const ApiException(statusCode: 0, message: 'fixture');
          return overviewFixture();
        },
        parse: AdminOverview.parse,
      );
      addTearDown(source.dispose);
      final health = healthDirectory((_) async {
        if (stopped)
          throw const ApiException(statusCode: 0, message: 'fixture');
        return healthy();
      });
      await tester.pumpWidget(host(source, health));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('API: Offline'), findsOneWidget);
      stopped = false;
      await health.refreshHealth();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('API: Online'), findsOneWidget);
      expect(find.text('Unable to load dashboard'), findsOneWidget);
      expect(find.text('Cannot reach CivicVoice'), findsNothing);
      expect(find.byKey(const ValueKey('admin-overview-stats')), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('1234'), findsOneWidget);
      expect(find.byType(AppStateMessage), findsNothing);
    },
  );
}
