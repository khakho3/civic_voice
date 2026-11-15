import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/admin/widgets/admin_scaffold.dart';
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart';
import 'package:civic_voice/features/maintenance/widgets/maintenance_scaffold.dart';
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/ministry/widgets/ministry_scaffold.dart';
import 'package:civic_voice/features/municipal/screens/municipal_profile_screen.dart';
import 'package:civic_voice/features/municipal/widgets/municipal_scaffold.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.admin,
    );
  });
  tearDown(() => MockAuthService().clearUser());

  for (final dark in [false, true]) {
    Future<void> show(
      WidgetTester tester,
      Widget child, {
      double scale = 2,
    }) async {
      tester.view.physicalSize = const Size(320, 950);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: child,
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final tab in [MaintenanceTab.dashboard, MaintenanceTab.tasks]) {
      testWidgets(
        'Maintenance $tab menu has only logout; Profile stays in navigation dark=$dark',
        (tester) async {
          MaintenanceTab? selected;
          await show(
            tester,
            MaintenanceScaffold(
              selectedTab: tab,
              body: const SizedBox(),
              onTabSelected: (tab) => selected = tab,
            ),
          );
          await tester.tap(find.byTooltip('Account options'));
          await tester.pumpAndSettle();
          expect(
            find.widgetWithText(PopupMenuItem<String>, 'Profile'),
            findsNothing,
          );
          expect(
            find.widgetWithText(PopupMenuItem<String>, 'Log Out'),
            findsOneWidget,
          );
          await tester.tap(
            find.widgetWithText(PopupMenuItem<String>, 'Log Out'),
          );
          await tester.pumpAndSettle();
          expect(find.text('Log out?'), findsOneWidget);
          await tester.tap(find.text('Cancel'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Profile'));
          expect(selected, MaintenanceTab.profile);
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final role in ['municipal', 'ministry', 'assembly']) {
      testWidgets('$role menu opens Profile without logging out dark=$dark', (
        tester,
      ) async {
        var opened = 0;
        void profile() => opened++;
        await show(tester, switch (role) {
          'municipal' => MunicipalScaffold(
            selectedTab: MunicipalTab.dashboard,
            body: const SizedBox(),
            onProfileTap: profile,
          ),
          'ministry' => MinistryScaffold(
            selectedTab: MinistryTab.dashboard,
            body: const SizedBox(),
            onProfileTap: profile,
          ),
          _ => AdminScaffold(
            selectedTab: AdminTab.dashboard,
            body: const SizedBox(),
            onOpenProfile: profile,
          ),
        });
        await tester.tap(find.byTooltip('Account options'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Profile'));
        await tester.pumpAndSettle();
        expect(opened, 1);
        expect(find.text('Log out?'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    for (final (role, screen) in <(String, Widget)>[
      ('maintenance', const ProfileScreen()),
      ('municipal', const MunicipalProfileScreen()),
      ('ministry', const MinistryProfileScreen()),
      ('assembly', const AdminProfileScreen()),
    ]) {
      testWidgets(
        '$role Profile omits account menu and retains in-page logout dark=$dark',
        (tester) async {
          await show(tester, screen, scale: 1);
          expect(find.byTooltip('Account options'), findsNothing);
          final logout = find.textContaining(
            RegExp('Log out', caseSensitive: false),
          );
          await tester.scrollUntilVisible(
            logout,
            350,
            scrollable: find.byType(Scrollable).first,
          );
          expect(logout, findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
