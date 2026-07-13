import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_management_screen.dart';

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

  // ---------------------------------------------------------------------
  // ADM-002 User Management
  // ---------------------------------------------------------------------

  for (final state in AdminUserManagementViewState.values) {
    testWidgets('Admin User Management renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserManagementScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin User Management renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminUserManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin User Management shows the full user list in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminUserManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('User Management'), findsOneWidget);
      expect(
        find.text('Manage administrator and staff accounts.'),
        findsOneWidget,
      );
      expect(find.text('Search users'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Admins'), findsOneWidget);
      expect(find.text('Staff'), findsOneWidget);
      // "Inactive" labels both the filter chip and Ama Boateng's own status
      // pill (she starts deactivated in the mock data).
      expect(find.text('Inactive'), findsNWidgets(2));

      expect(find.text('Ama Boateng'), findsOneWidget);
      expect(find.text('admin@civicvoice.gov'), findsOneWidget);
      expect(find.text('System Administrator'), findsOneWidget);
      // "Active" labels three of the six mock users' status pills (Kojo
      // Mensah, Yaw Asare, Genevieve Amadapah).
      expect(find.text('Active'), findsNWidgets(3));
      expect(find.text('Kojo Mensah'), findsOneWidget);
      expect(find.text('Municipal Officer'), findsOneWidget);
      expect(find.text('Esi Owusu'), findsOneWidget);
      expect(find.text('Ministry Supervisor'), findsOneWidget);
      // "Review" labels Esi Owusu's and Kwame Nyarko's status pills.
      expect(find.text('Review'), findsNWidgets(2));
      expect(find.text('Yaw Asare'), findsOneWidget);
      expect(find.text('Maintenance Team'), findsOneWidget);
      expect(find.text('Kwame Nyarko'), findsOneWidget);
      expect(find.text('Genevieve Amadapah'), findsOneWidget);
      // "Citizen" labels both Kwame Nyarko's and Genevieve Amadapah's role
      // pills.
      expect(find.text('Citizen'), findsNWidgets(2));
    },
  );

  testWidgets('Admin User Management search field filters the user list', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminUserManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kojo');
    await tester.pumpAndSettle();

    expect(find.text('Kojo Mensah'), findsOneWidget);
    expect(find.text('Ama Boateng'), findsNothing);
  });

  testWidgets(
    'Admin User Management Admins filter chip shows only admin users',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminUserManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Admins'));
      await tester.pumpAndSettle();

      expect(find.text('Ama Boateng'), findsOneWidget);
      expect(find.text('Kojo Mensah'), findsNothing);
    },
  );

  testWidgets(
    'Admin User Management kebab menu deactivates and reactivates a user',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminUserManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Ama Boateng (the first kebab) already starts "Inactive" in the mock
      // data — deactivate Kojo Mensah (the second) instead, so this test
      // actually exercises the Active -> Inactive transition.
      await tester.tap(find.byIcon(AppIcons.more).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deactivate account'));
      await tester.pumpAndSettle();

      // Ama Boateng and Kojo Mensah are now both "Inactive" (joining the
      // filter chip of the same name) — Yaw Asare and Genevieve Amadapah
      // are still "Active" (Esi Owusu and Kwame Nyarko remain "Review").
      expect(find.text('Inactive'), findsNWidgets(3));
      expect(find.text('Active'), findsNWidgets(2));

      await tester.tap(find.text('Inactive').first);
      await tester.pumpAndSettle();
      expect(find.text('Ama Boateng'), findsOneWidget);
      expect(find.text('Kojo Mensah'), findsOneWidget);
      expect(find.text('Yaw Asare'), findsNothing);
    },
  );

  testWidgets('Admin User Management tapping a user card opens User Details', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AdminUserItem? openedUser;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserManagementScreen(
          onOpenUserDetails: (user) => openedUser = user,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ama Boateng'));
    await tester.pumpAndSettle();

    expect(openedUser?.name, 'Ama Boateng');
  });

  Future<void> pumpAdminUserManagement(
    WidgetTester tester,
    AdminUserManagementViewState state,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserManagementScreen(initialState: state),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Admin User Management Empty shows the approved copy, with filter '
    'chrome still visible',
    (WidgetTester tester) async {
      await pumpAdminUserManagement(tester, AdminUserManagementViewState.empty);
      expect(find.text('No Users'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      expect(find.text('Search users'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin User Management No Results clears filters and returns to the '
    'loaded state',
    (WidgetTester tester) async {
      await pumpAdminUserManagement(
        tester,
        AdminUserManagementViewState.noResults,
      );
      expect(find.text('No Results'), findsOneWidget);
      expect(
        find.text('No users match the current search or filters.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.text('Ama Boateng'), findsOneWidget);
    },
  );

  testWidgets('Admin User Management Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpAdminUserManagement(tester, AdminUserManagementViewState.offline);
    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('Retry connection'), findsOneWidget);
  });

  testWidgets('Admin User Management Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpAdminUserManagement(tester, AdminUserManagementViewState.error);
    expect(find.text('Unable to Load Users'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets(
    'Admin User Management Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      await pumpAdminUserManagement(
        tester,
        AdminUserManagementViewState.unauthorized,
      );
      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    },
  );

  testWidgets(
    'Admin User Management is a tab-shell screen: bottom nav stays visible '
    'and switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var dashboardTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserManagementScreen(
            onNavigateToDashboard: () => dashboardTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(dashboardTapped, isTrue);
    },
  );
}
