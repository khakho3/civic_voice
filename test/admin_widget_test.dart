import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_system_activity_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_role_management_screen.dart';
import 'package:civic_voice/features/admin/models/admin_profile_data.dart';
import 'package:civic_voice/features/admin/models/admin_system_settings_data.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_settings_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_details_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_management_screen.dart';
import 'package:civic_voice/models/app_role.dart';

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

      // Dashboard's header shows a centered logo mark, not the "CivicVoice"
      // wordmark text — that now lives only in the drawer.
      expect(find.image(const AssetImage(AppAssets.logoApp)), findsOneWidget);
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(find.text('API Status: Online'), findsOneWidget);

      // "System Settings" labels only the Management row now — the top
      // CTA button was dropped as a redundant path to the same
      // destination, and the bottom-nav tab's own label is the shorter
      // "Settings".
      expect(find.text('System Settings'), findsOneWidget);

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
      // Management row's "System Settings".
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
    'Admin Dashboard Management row System Settings entry fires the '
    'callback',
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

      await tester.tap(find.text('System Settings'));
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

  testWidgets(
    'Admin routes connect Dashboard, Users, User Details, and Roles',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(initialRoute: app.AppRoutes.adminDashboard),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Platform Overview'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('User Management'), findsWidgets);

      await tester.tap(find.text('Kojo Mensah'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('User Details'), findsOneWidget);
      expect(find.text('CV-USER-0102'), findsOneWidget);

      await tester.tap(find.text('Roles').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Role Management'), findsOneWidget);
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
      expect(find.text('API Status: Online'), findsOneWidget);
    },
  );

  testWidgets('Admin Dashboard Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    await pumpAdminDashboard(tester, AdminDashboardViewState.error);
    expect(find.text('Unable to Load Dashboard'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
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

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Unable to Load Dashboard'), findsNothing);
    expect(find.text('Management'), findsOneWidget);
  });

  // ---------------------------------------------------------------------
  // Admin drawer (shared AdminScaffold chrome, exercised via Dashboard)
  // ---------------------------------------------------------------------

  testWidgets('Admin drawer opens from the header hamburger icon', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
    );
    await tester.pump();

    expect(find.byType(Drawer), findsNothing);

    await tester.tap(find.byIcon(AppIcons.menu));
    // The drawer's slide-in is a spring (`fling`) animation: its ticker only
    // establishes its own elapsed-time epoch on the frame it starts, so a
    // single large `pump(duration)` right after the tap that triggers it
    // evaluates the spring at t=0 and freezes it fully closed. It needs a
    // zero-duration pump first (to start the ticker) before a second pump
    // lets it settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('CivicVoice'), findsOneWidget);
    expect(find.text('System Activity'), findsOneWidget);
    expect(find.text('Admin Profile'), findsOneWidget);
  });

  testWidgets(
    'Admin drawer does not repeat the four bottom-nav tab destinations',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dashboard/Users/Roles/Settings are already one tap away on the
      // bottom nav, so the drawer's own ListView shouldn't repeat them —
      // only the two destinations with no tab slot.
      final drawerTiles = tester.widgetList<ListTile>(
        find.descendant(
          of: find.byType(Drawer),
          matching: find.byType(ListTile),
        ),
      );
      final drawerLabels = drawerTiles
          .map((tile) => (tile.title! as Text).data)
          .toList();
      expect(drawerLabels, ['System Activity', 'Admin Profile']);
    },
  );

  testWidgets('Admin drawer System Activity and Admin Profile items fire their '
      'callbacks and close the drawer', (WidgetTester tester) async {
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

    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('System Activity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(activityTapped, isTrue);
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('Admin drawer Admin Profile item is disabled when unwired', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
    );
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.text('Admin Profile'),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.enabled, isFalse);
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

      // Deactivating asks for confirmation first.
      expect(find.text('Deactivate account?'), findsOneWidget);
      await tester.tap(find.text('Deactivate'));
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
    expect(find.text('Retry'), findsOneWidget);
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

  // ---------------------------------------------------------------------
  // ADM-004 Role Management
  // ---------------------------------------------------------------------

  for (final state in AdminRoleManagementViewState.values) {
    testWidgets('Admin Role Management renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminRoleManagementScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin Role Management renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminRoleManagementScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin Role Management shows both fixed tiers and the permissions '
    'table in its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminRoleManagementScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('System Access Control'), findsOneWidget);
      // "Super Admin" appears twice — once as a card title, once as its
      // Quick Permissions Check table column header.
      expect(find.text('Super Admin'), findsWidgets);
      expect(find.text('Full System Authority'), findsOneWidget);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Standard Access'), findsOneWidget);
      expect(find.text('Export Reports'), findsWidgets);
      expect(find.text('View Audit Logs'), findsWidgets);
      expect(find.text('Security Audit Required'), findsOneWidget);
      expect(find.text('View Detailed Logs'), findsOneWidget);
      expect(find.text('Quick Permissions Check'), findsOneWidget);
      // Appears both as the table's row label and Super Admin's own tag
      // chip (Super Admin is granted every permission).
      expect(find.text('Delete Records'), findsWidgets);

      // No management affordances — the tier set is fixed and read-only.
      expect(find.byType(PopupMenuButton<void>), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    },
  );

  testWidgets(
    'Admin Role Management is a tab-shell screen: bottom nav stays visible '
    'and switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var usersTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminRoleManagementScreen(
            onNavigateToUsers: () => usersTapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);
    },
  );

  testWidgets(
    'Admin Role Management Security Audit card opens System Activity',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var activityTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminRoleManagementScreen(
            onOpenSystemActivity: () => activityTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('View Detailed Logs'));
      await tester.pump();

      expect(activityTapped, isTrue);
    },
  );

  testWidgets('Admin Role Management Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminRoleManagementScreen(
          initialState: AdminRoleManagementViewState.offline,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You\'re offline'), findsOneWidget);
    expect(find.text('System Access Control'), findsOneWidget);
  });

  testWidgets('Admin Role Management Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminRoleManagementScreen(
          initialState: AdminRoleManagementViewState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets(
    'Admin Role Management Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminRoleManagementScreen(
            initialState: AdminRoleManagementViewState.unauthorized,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'Admin Role Management Retry moves Error through loading to loaded',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminRoleManagementScreen(
            initialState: AdminRoleManagementViewState.error,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Super Admin'), findsWidgets);
    },
  );

  // ---------------------------------------------------------------------
  // ADM-003 User Details
  // ---------------------------------------------------------------------

  AdminUserItem findMockUser(String name) =>
      mockAdminUsers().firstWhere((u) => u.name == name);

  for (final state in AdminUserDetailsViewState.values) {
    testWidgets('Admin User Details renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(
            user: findMockUser('Yaw Asare'),
            initialState: state,
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin User Details renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(user: findMockUser('Yaw Asare')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Admin User Details shows the profile, sections, and permissions '
      'summary in its loaded state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserDetailsScreen(user: findMockUser('Yaw Asare')),
      ),
    );
    await tester.pump();

    expect(find.text('User Details'), findsOneWidget);
    // Each appears twice — once on the profile card, once as its own
    // read-only "User Information" field.
    expect(find.text('Yaw Asare'), findsWidgets);
    expect(find.text('yaw.asare@civicvoice.gov'), findsWidgets);
    expect(find.text('CV-USER-0104'), findsOneWidget);
    expect(find.text('User Information'), findsOneWidget);
    expect(find.text('Access Management'), findsOneWidget);
    expect(find.text('Permissions Summary'), findsOneWidget);
    expect(find.text('Account Activity'), findsOneWidget);
    // The role pill and the "Assigned Role" dropdown's current value
    // both read "Maintenance Team".
    expect(find.text('Maintenance Team'), findsWidgets);
    expect(find.text('Update reports'), findsOneWidget);

    // Still shows the "Users" tab selected, not a persistent tab of its
    // own — this screen is a drill-down from that list.
    expect(find.text('Users'), findsOneWidget);

    // No Admin Tier selector for a non-admin account.
    expect(find.text('Admin Tier'), findsNothing);
  });

  testWidgets(
    'Admin User Details reveals the Admin Tier selector only when Assigned '
    'Role is System Administrator',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(user: findMockUser('Yaw Asare')),
        ),
      );
      await tester.pump();

      expect(find.text('Admin Tier'), findsNothing);

      // No indefinitely-repeating animation exists in this screen's
      // loaded state (unlike Dashboard's breathing dot or the loading
      // skeleton's shimmer), so pumpAndSettle is safe here and more
      // robust than guessing a fixed settle duration for the dropdown's
      // own open/close route animation.
      await tester.tap(find.byType(DropdownButton<AppRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('System Administrator').last);
      await tester.pumpAndSettle();

      expect(find.text('Admin Tier'), findsOneWidget);
      // Defaults to the Admin tier, not Super Admin.
      expect(find.text('Admin'), findsWidgets);
      // Permissions Summary now previews the Admin tier's grants instead
      // of Maintenance Team's.
      expect(find.text('Update reports'), findsNothing);
      expect(find.text('Export Reports'), findsWidgets);

      await tester.tap(find.byType(DropdownButton<AppRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen').last);
      await tester.pumpAndSettle();

      expect(find.text('Admin Tier'), findsNothing);
    },
  );

  testWidgets(
    'Admin User Details Save Changes shows the success banner and forwards '
    'the edited record',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AdminUserItem? saved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(
            user: findMockUser('Yaw Asare'),
            onSaveChanges: (user) => saved = user,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Changes saved'), findsNothing);

      await tester.tap(find.text('Save Changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Saving asks for confirmation first — its own confirm button
      // shares the same label as the page's Save Changes button.
      expect(find.text('Save access changes?'), findsOneWidget);
      await tester.tap(find.text('Save Changes').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Changes saved'), findsOneWidget);
      expect(saved?.role, AppRole.maintenanceTeam);
      expect(saved?.status, AdminUserStatus.active);
    },
  );

  testWidgets('Admin User Details Cancel navigates back to User Management', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var backTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserDetailsScreen(
          user: findMockUser('Yaw Asare'),
          onNavigateToUsers: () => backTapped = true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(backTapped, isTrue);
  });

  testWidgets(
    'Admin User Details is a tab-shell screen: bottom nav stays visible '
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
          home: AdminUserDetailsScreen(
            user: findMockUser('Yaw Asare'),
            onNavigateToDashboard: () => dashboardTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Dashboard'));
      await tester.pump();
      expect(dashboardTapped, isTrue);
    },
  );

  testWidgets('Admin User Details Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserDetailsScreen(
          user: findMockUser('Yaw Asare'),
          initialState: AdminUserDetailsViewState.offline,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You\'re offline'), findsOneWidget);
  });

  testWidgets('Admin User Details Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserDetailsScreen(
          user: findMockUser('Yaw Asare'),
          initialState: AdminUserDetailsViewState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('Admin User Details Unauthorized shows the approved copy with no '
      'action buttons', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminUserDetailsScreen(
          user: findMockUser('Yaw Asare'),
          initialState: AdminUserDetailsViewState.unauthorized,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Unauthorized Access'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets(
    'Admin User Details Retry moves Error through loading to loaded',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(
            user: findMockUser('Yaw Asare'),
            initialState: AdminUserDetailsViewState.error,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Yaw Asare'), findsWidgets);
    },
  );

  // ---------------------------------------------------------------------
  // ADM-006 System Activity
  // ---------------------------------------------------------------------

  for (final state in AdminSystemActivityViewState.values) {
    testWidgets('Admin System Activity renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin System Activity renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Activity shows the stats, filters, and activity feed in '
    'its loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('System Activity'), findsOneWidget);
      expect(find.text('Total Events'), findsOneWidget);
      expect(find.text('2.4k'), findsOneWidget);
      expect(find.text('Login Events'), findsOneWidget);
      expect(find.text('Admin Actions'), findsOneWidget);
      expect(find.text('Security Alerts'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('All Events'), findsOneWidget);
      expect(find.text('System Updates'), findsOneWidget);
      // "User Modifications" — the third, widest chip — sits beyond the
      // horizontally-scrollable chip row's initial build extent at this
      // width, matching the approved frame's own cut-off rendering of it.
      expect(find.text('Last 24 Hours'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      expect(find.text('Unauthorized Login Attempt'), findsOneWidget);
      expect(find.text('System Policy Update'), findsOneWidget);
      expect(find.text('Automated Backup Complete'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      // "Administrative Credential Issued" happened over a day ago, so
      // the default "Last 24 Hours" range already excludes it — covered
      // separately by the time-range dropdown test below.
      expect(find.text('Administrative Credential Issued'), findsNothing);

      // Still shows Dashboard as the selected tab — this screen has no
      // persistent tab slot of its own.
      final dashboardTab = find.ancestor(
        of: find.text('Dashboard'),
        matching: find.byType(InkWell),
      );
      expect(dashboardTab, findsOneWidget);
    },
  );

  testWidgets('Admin System Activity filter chip narrows the activity feed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemActivityScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('System Updates'));
    await tester.pump();

    expect(find.text('System Policy Update'), findsOneWidget);
    expect(find.text('Automated Backup Complete'), findsOneWidget);
    expect(find.text('Unauthorized Login Attempt'), findsNothing);
    expect(find.text('Administrative Credential Issued'), findsNothing);
  });

  testWidgets(
    'Admin System Activity time range dropdown filters out older events',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(),
        ),
      );
      await tester.pump();

      // "Administrative Credential Issued" happened over a day ago, so
      // the default "Last 24 Hours" range already excludes it.
      expect(find.text('Administrative Credential Issued'), findsNothing);
      expect(find.text('Automated Backup Complete'), findsOneWidget);

      // No indefinitely-repeating animation exists in this screen's loaded
      // state, so pumpAndSettle is safe and more robust than guessing a
      // fixed settle duration for the dropdown's own open/close route
      // animation.
      await tester.tap(find.byType(DropdownButton<ActivityTimeRange>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 Days').last);
      await tester.pumpAndSettle();

      // Broadening the range reveals it.
      expect(find.text('Administrative Credential Issued'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Activity is a tab-shell screen: bottom nav switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var usersTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            onNavigateToUsers: () => usersTapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);
    },
  );

  testWidgets(
    'Admin System Activity No Results clears filters and returns to the '
    'loaded state',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.noResults,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('No Results'), findsOneWidget);
      // Filter chrome stays visible and interactive in No Results.
      expect(find.text('All Events'), findsOneWidget);

      await tester.tap(find.text('Clear Filters'));
      await tester.pump();

      expect(find.text('No Results'), findsNothing);
      expect(find.text('Unauthorized Login Attempt'), findsOneWidget);
    },
  );

  testWidgets('Admin System Activity Empty shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemActivityScreen(
          initialState: AdminSystemActivityViewState.empty,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('No Activity'), findsOneWidget);
  });

  testWidgets('Admin System Activity Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemActivityScreen(
          initialState: AdminSystemActivityViewState.offline,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You\'re offline'), findsOneWidget);
  });

  testWidgets('Admin System Activity Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemActivityScreen(
          initialState: AdminSystemActivityViewState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets(
    'Admin System Activity Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.unauthorized,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'Admin System Activity Retry moves Error through loading to loaded',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.error,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Recent Activity'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // ADM-007 System Settings
  // ---------------------------------------------------------------------

  for (final state in AdminSystemSettingsViewState.values) {
    testWidgets('Admin System Settings renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemSettingsScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin System Settings renders without overflow on a narrow phone '
    '(375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Settings shows every section and field in its loaded '
    'state, with no Save bar when clean',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('General Configuration'), findsOneWidget);
      expect(find.text('Platform Name'), findsOneWidget);
      expect(find.text('CivicVoice'), findsOneWidget);
      expect(find.text('Default Language'), findsOneWidget);
      expect(find.text('Maintenance Mode'), findsOneWidget);
      expect(find.text('Security & Access'), findsOneWidget);
      expect(find.text('Enforce two-factor authentication'), findsOneWidget);
      expect(find.text('Session timeout'), findsOneWidget);
      expect(find.text('Audit logging'), findsOneWidget);
      expect(find.text('Data Retention'), findsOneWidget);
      expect(find.text('Audit log retention'), findsOneWidget);
      expect(find.text('Backup schedule'), findsOneWidget);
      expect(find.text('Service Preferences'), findsOneWidget);
      expect(find.text('Public status page'), findsOneWidget);
      expect(find.text('Regional data routing'), findsOneWidget);

      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Reset Changes'), findsNothing);
    },
  );

  testWidgets('Admin System Settings shows the Save bar once dirty and Reset '
      'Changes reverts it', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemSettingsScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch).first);
    await tester.pump();

    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Reset Changes'), findsOneWidget);

    await tester.tap(find.text('Reset Changes'));
    await tester.pump();

    expect(find.text('Save Changes'), findsNothing);
    expect(find.text('Reset Changes'), findsNothing);
  });

  testWidgets('Admin System Settings Save Changes shows the success banner and '
      'clears the dirty state', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemSettingsScreen(),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.tap(find.text('Save Changes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Saving asks for confirmation first — its own confirm button shares
    // the same label as the page's Save Changes button.
    expect(find.text('Save system settings?'), findsOneWidget);
    await tester.tap(find.text('Save Changes').last);
    await tester.pump();

    // The save completes after a simulated delay — a single pump only
    // advances one frame, not the full delay.
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Configuration saved'), findsOneWidget);
    expect(find.text('Save Changes'), findsNothing);
    expect(find.text('Reset Changes'), findsNothing);
  });

  testWidgets(
    'Admin System Settings blocks saving with an empty Platform Name and '
    'shows the validation copy',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'CivicVoice'),
        '',
      );
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(find.text('Validation Error'), findsOneWidget);
      expect(find.text('Platform name is required.'), findsOneWidget);
      // Still dirty — the failed save doesn't clear the bar.
      expect(find.text('Save Changes'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Settings initialSaveState previews the Update Failed '
    'banner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialSaveState: SystemSettingsSaveState.failed,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Update Failed'), findsOneWidget);
      expect(
        find.text(
          'System settings could not be saved. No changes were applied.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('Admin System Settings is a tab-shell screen: bottom nav stays '
      'visible and switches tabs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var usersTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminSystemSettingsScreen(
          onNavigateToUsers: () => usersTapped = true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Users'));
    await tester.pump();
    expect(usersTapped, isTrue);
  });

  testWidgets('Admin System Settings Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemSettingsScreen(
          initialState: AdminSystemSettingsViewState.offline,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You\'re offline'), findsOneWidget);
  });

  testWidgets('Admin System Settings Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminSystemSettingsScreen(
          initialState: AdminSystemSettingsViewState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets(
    'Admin System Settings Unauthorized shows the approved copy with no '
    'action buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialState: AdminSystemSettingsViewState.unauthorized,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'Admin System Settings Retry moves Error through loading to loaded',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialState: AdminSystemSettingsViewState.error,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(find.text('Something went wrong'), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('General Configuration'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // ADM-008 Admin Profile
  // ---------------------------------------------------------------------

  for (final state in AdminProfileViewState.values) {
    testWidgets('Admin Profile renders ${state.name} without error', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminProfileScreen(initialState: state),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Admin Profile renders without overflow on a narrow phone (375px)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin Profile shows every section in its loaded state, read-only '
    'and with no Save bar by default',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
      );
      await tester.pump();

      expect(find.text('Admin Profile'), findsOneWidget);
      // Appears twice — the profile card headline and the "Full Name"
      // field value.
      expect(find.text('System Administrator'), findsNWidgets(2));
      expect(find.text('admin@civicvoice.gov'), findsOneWidget);
      expect(find.text('Platform Administration'), findsOneWidget);
      expect(find.text('ADM-001'), findsOneWidget);
      expect(find.text('Access Summary'), findsOneWidget);
      expect(find.text('92% governance checklist complete'), findsOneWidget);
      expect(find.text('Security Settings'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Two-factor authentication'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
      expect(find.text('Administrative Scope'), findsOneWidget);
      expect(find.text('Users'), findsWidgets);
      expect(find.text('Roles'), findsWidgets);
      expect(find.text('Governance Level'), findsOneWidget);
      expect(find.text('Approved administrator'), findsOneWidget);
      expect(find.text('Session'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    },
  );

  testWidgets(
    'Admin Profile Edit reveals editable fields and the Save bar, Cancel '
    'reverts',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit'));
      await tester.pump();

      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // The bottom nav hides while editing — it would otherwise sit
      // directly on top of the sticky Save bar, and navigating away
      // mid-edit without going through Cancel/Save is more likely a
      // mistake than an intent.
      expect(find.text('Dashboard'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Platform Administration'),
        'Civic Operations',
      );
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Platform Administration'), findsOneWidget);
      expect(find.text('Civic Operations'), findsNothing);
      expect(find.text('Dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Profile Sign Out asks for confirmation before firing the '
    'callback',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var signedOut = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminProfileScreen(onSignOut: () => signedOut = true),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Sign out?'), findsOneWidget);
      expect(signedOut, isFalse);

      // Dismissing via Cancel doesn't sign out.
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(signedOut, isFalse);
      expect(find.text('Sign out?'), findsNothing);

      // Confirming via the dialog's own button (shares the trigger
      // button's label, hence .last) does sign out.
      await tester.tap(find.text('Sign Out'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Sign Out').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(signedOut, isTrue);
    },
  );

  testWidgets(
    'Admin Profile Save Changes shows the success banner and exits edit '
    'mode',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Edit'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Platform Administration'),
        'Civic Operations',
      );
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // The save completes after a simulated delay — a single pump only
      // advances one frame, not the full delay.
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Profile updated'), findsOneWidget);
      expect(find.text('Civic Operations'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
    },
  );

  testWidgets(
    'Admin Profile blocks saving with an empty Full Name and shows the '
    'validation copy',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Edit'));
      await tester.pump();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'System Administrator'),
        '',
      );
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      expect(find.text('Full name is required.'), findsOneWidget);
      // Still editing — the failed save doesn't clear the bar.
      expect(find.text('Save Changes'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Profile initialSaveState previews the Update Failed banner',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminProfileScreen(
            initialSaveState: AdminProfileSaveState.failed,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Update Failed'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Profile is a tab-shell screen: bottom nav stays visible and '
    'switches tabs',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var usersTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminProfileScreen(onNavigateToUsers: () => usersTapped = true),
        ),
      );
      await tester.pump();

      expect(find.text('Dashboard'), findsOneWidget);
      // "Users"/"Settings" also appear as Administrative Scope pills.
      expect(find.text('Users'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);

      // The Administrative Scope pill ("Users") is built before the
      // bottom-nav tab of the same name.
      await tester.tap(find.text('Users').last);
      await tester.pump();
      expect(usersTapped, isTrue);
    },
  );

  testWidgets('Admin Profile Offline shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminProfileScreen(
          initialState: AdminProfileViewState.offline,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You\'re offline'), findsOneWidget);
  });

  testWidgets('Admin Profile Error shows the approved copy', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminProfileScreen(
          initialState: AdminProfileViewState.error,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets(
    'Admin Profile Unauthorized shows the approved copy with no action '
    'buttons',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminProfileScreen(
            initialState: AdminProfileViewState.unauthorized,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets('Admin Profile Retry moves Error through loading to loaded', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminProfileScreen(
          initialState: AdminProfileViewState.error,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Something went wrong'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Access Summary'), findsOneWidget);
  });
}
