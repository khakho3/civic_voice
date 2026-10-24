import 'dart:async';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_alerts_screen.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/features/admin/widgets/admin_scaffold.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:civic_voice/widgets/civic_filter_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_live_overview_test.dart' show alertFixture;

Map<String, dynamic> page() => {
  'alerts': [alertFixture()],
  'total': 1,
  'nextCursor': null,
};
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(
      accountId: 'alert-navigation-test',
    );
    await MockAuthService().initialize();
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.superAdmin,
    );
  });
  tearDown(() => MockAuthService().clearUser());
  for (final dark in [false, true]) {
    testWidgets('drawer opens the existing alert route and closes dark=$dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          routes: {
            '/admin/alerts': (_) => AdminAlertsScreen(
              resourceFactory: (_, _, _) => AdminResource<AdminAlertPage>(
                owner: () => 'fixture-admin',
                credential: () async => 'fixture',
                fetch: (_) async => page(),
                parse: AdminAlertPage.parse,
              ),
            ),
          },
          home: Builder(
            builder: (context) => AdminScaffold(
              selectedTab: AdminTab.dashboard,
              body: const SizedBox(),
              onOpenAlerts: () =>
                  Navigator.of(context).pushNamed('/admin/alerts'),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pumpAndSettle();
      final drawer = find.byType(Drawer);
      await tester.tap(
        find.descendant(of: drawer, matching: find.text('Open alerts')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AdminAlertsScreen), findsOneWidget);
      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(CivicFilterChip), findsWidgets);
      expect(find.text('System setting changed'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AdminAlertsScreen), findsNothing);
      expect(find.byType(Drawer), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'filter fetch is quiet, preserves errors and leaves explicit refresh feedback dark=$dark',
      (tester) async {
        var pending = Completer<Map<String, dynamic>>();
        final states = <String>[];
        var cold = true;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: AdminAlertsScreen(
              resourceFactory: (state, query, cursor) {
                states.add(state);
                return AdminResource<AdminAlertPage>(
                  owner: () => 'fixture-admin',
                  credential: () async => 'fixture',
                  fetch: (_) {
                    if (cold) {
                      cold = false;
                      return Future.value(page());
                    }
                    return pending.future;
                  },
                  parse: AdminAlertPage.parse,
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(CivicFilterChip, 'Open and acknowledged'),
        );
        await tester.pump();
        expect(states, ['ACTIVE']);
        await tester.tap(find.widgetWithText(CivicFilterChip, 'Open'));
        await tester.pump();
        expect(states, ['ACTIVE', 'OPEN']);
        expect(find.text('Updating alerts…'), findsOneWidget);
        expect(find.byType(BusyIndicator), findsNothing);
        // Same-owner matches stay mounted, without claiming a new total or empty page.
        expect(find.text('System setting changed'), findsOneWidget);
        expect(find.text('1 matching alerts'), findsNothing);
        expect(find.text('No alerts match these filters.'), findsNothing);
        pending.completeError(StateError('offline'));
        await tester.pumpAndSettle();
        expect(find.textContaining('could not be verified'), findsOneWidget);
        expect(find.text('No alerts match these filters.'), findsNothing);
        pending = Completer<Map<String, dynamic>>();
        await tester.tap(find.text('Refresh alerts'));
        await tester.pump();
        expect(find.byType(BusyIndicator), findsOneWidget);
        expect(find.text('Updating alerts…'), findsNothing);
        pending.complete(page());
        await tester.pumpAndSettle();
        expect(find.text('System setting changed'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'ordinary Admin keeps its existing header without a Super Admin drawer',
    (tester) async {
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminScaffold(
            selectedTab: AdminTab.dashboard,
            body: const SizedBox(),
            onOpenAlerts: () {},
          ),
        ),
      );
      expect(tester.widget<Scaffold>(find.byType(Scaffold)).drawer, isNull);
      expect(find.byIcon(AppIcons.menu), findsNothing);
    },
  );
}
