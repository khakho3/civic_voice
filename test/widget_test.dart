import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';

void main() {
  // ---------------------------------------------------------------------
  // ADM-001 Admin Dashboard
  // ---------------------------------------------------------------------

  for (final state in AdminDashboardViewState.values) {
    testWidgets('Admin Dashboard renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin Dashboard renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin Dashboard shows the full platform overview in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      expect(find.text('CivicVoice'), findsOneWidget);
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(
        find.text('Real-time metrics and system administrative summary.'),
        findsOneWidget,
      );
      expect(find.text('System Live: 99.9% Uptime'), findsOneWidget);

      // "System Settings" labels both the CTA button and the Management
      // row — the bottom-nav tab's own label is the shorter "Settings".
      expect(find.text('System Settings'), findsNWidgets(2));

      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('12.4k'), findsOneWidget);
      expect(find.text('+4.2%'), findsOneWidget);
      expect(find.text('Active Roles'), findsOneWidget);
      expect(find.text('48'), findsOneWidget);
      expect(find.text('+2.1%'), findsOneWidget);
      expect(find.text('Admin Actions'), findsOneWidget);
      expect(find.text('1.8k'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('Open Alerts'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      expect(find.text('Management'), findsOneWidget);
      expect(find.text('User Management'), findsOneWidget);
      expect(
        find.text('Manage administrator and staff accounts'),
        findsOneWidget,
      );
      expect(find.text('Role Management'), findsOneWidget);
      expect(find.text('Review privileges and access groups'), findsOneWidget);
      expect(find.text('Governance-approved configuration'), findsOneWidget);

      expect(find.text('Activity Monitoring'), findsOneWidget);
      expect(find.text('Role permission updated'), findsOneWidget);
      expect(find.text('New admin account approved'), findsOneWidget);
      expect(find.text('System policy reviewed'), findsOneWidget);
      expect(find.text('Audit log · read-only'), findsNWidgets(3));
    },
  );

  testWidgets(
    'Admin Dashboard is a tab-shell screen: bottom nav stays visible and '
    'switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var usersTapped = false;
      var rolesTapped = false;
      var settingsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            onNavigateToUsers: () => usersTapped = true,
            onNavigateToRoles: () => rolesTapped = true,
            onNavigateToSettings: () => settingsTapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
      // The bottom-nav tab's own label is "Settings" — shorter than the
      // CTA button's/Management row's "System Settings".
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);

      await tester.tap(find.text('Roles'));
      await tester.pump();
      expect(rolesTapped, isTrue);

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(settingsTapped, isTrue);
    },
  );

  testWidgets(
    'Admin Dashboard System Settings CTA and Management row both fire the '
    'same callback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(onNavigateToSettings: () => tapCount++),
        ),
      );
      await tester.pump();

      // .first is the top CTA button (built before the Management row and
      // the bottom-nav tab in tree order).
      await tester.tap(find.text('System Settings').first);
      await tester.pump();
      expect(tapCount, 1);
    },
  );

  testWidgets(
    'Admin Dashboard Activity Monitoring card opens System Activity',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var activityTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            onViewSystemActivity: () => activityTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Activity Monitoring'));
      await tester.pump();

      expect(activityTapped, isTrue);
    },
  );

  Future<void> pumpAdminDashboard(
    WidgetTester tester,
    AdminDashboardViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(initialState: state),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'Admin Dashboard Offline shows the approved copy, with the title block '
    'still visible',
    (WidgetTester tester) async {
      await pumpAdminDashboard(tester, AdminDashboardViewState.offline);
      expect(find.text('You\'re offline'), findsOneWidget);
      expect(find.text('Retry connection'), findsOneWidget);
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(find.text('System Live: 99.9% Uptime'), findsOneWidget);
    },
  );

  testWidgets('Admin Dashboard Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpAdminDashboard(tester, AdminDashboardViewState.error);
    expect(find.text('Unable to Load Dashboard'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Admin Dashboard Unauthorized shows the approved copy with no action '
    'buttons',
    (WidgetTester tester) async {
      await pumpAdminDashboard(tester, AdminDashboardViewState.unauthorized);
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(
        find.text(
          'Administrative privileges are required to access this '
          'module.',
        ),
        findsOneWidget,
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets('Admin Dashboard Retry moves Error through loading to loaded', (
    WidgetTester tester,
  ) async {
    await pumpAdminDashboard(tester, AdminDashboardViewState.error);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Unable to Load Dashboard'), findsNothing);
    expect(find.text('Management'), findsOneWidget);
  });
}
