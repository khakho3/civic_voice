import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:civic_voice/main.dart' as app;
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/core/theme/theme_controller.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/models/admin_dashboard_data.dart';
import 'package:civic_voice/features/admin/models/admin_system_activity_data.dart';
import 'package:civic_voice/features/admin/models/admin_maintenance_team_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_maintenance_teams_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_notifications_screen.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:civic_voice/features/admin/screens/admin_role_management_screen.dart';
import 'package:civic_voice/features/admin/models/admin_profile_data.dart';
import 'package:civic_voice/features/admin/models/admin_system_settings_data.dart';
import 'package:civic_voice/features/admin/screens/admin_create_user_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_settings_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_details_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_management_screen.dart';
import 'package:civic_voice/features/admin/services/admin_user_directory.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/features/admin/services/admin_system_settings_directory.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/utils/time_greeting.dart';
import 'package:civic_voice/widgets/app_dropdown_field.dart';
import 'package:civic_voice/widgets/glass_dialog_backdrop.dart';
import 'package:civic_voice/models/ghana_assemblies_data.dart';
import 'package:civic_voice/models/assembly.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/mock_auth_service.dart';

/// Snapshots the live `AdminSystemSettingsDirectory` settings and restores
/// them after the test — for tests that write through the real directory
/// singleton, which otherwise leaks into every later test in this file
/// (e.g. a test that turns audit logging or account creation off would
/// otherwise leave it off for every test that runs afterward).
void _preserveAdminSystemSettingsDirectory() {
  final directory = AdminSystemSettingsDirectory.instance;
  final original = directory.settings.value;
  final state = directory.state.value;
  final loading = directory.loading.value;
  final error = directory.error.value;
  final hasLiveSnapshot = directory.hasLiveSnapshot;
  addTearDown(
    () {
      directory.settings.value = original;
      directory.state.value = state;
      directory.loading.value = loading;
      directory.error.value = error;
      directory.hasLiveSnapshot = hasLiveSnapshot;
    },
  );
}

void _setConfirmedSystemSettingsFixture() {
  final directory = AdminSystemSettingsDirectory.instance;
  _preserveAdminSystemSettingsDirectory();
  directory.settings.value = mockSystemSettings();
  directory.hasLiveSnapshot = true;
  directory.state.value = AdminSystemSettingsDirectoryState.loaded;
  directory.error.value = null;
}

List<ActivityItem> _adminActivityFixture() => mockActivityItems();

AdminUserItem _dashboardUserFixture({
  required String id,
  required AppRole role,
  Assembly? assembly,
  AdminUserStatus status = AdminUserStatus.active,
}) => AdminUserItem(
  apiId: id,
  name: 'Dashboard $id',
  phone: '+233 20 000 ${id.padLeft(4, '0')}',
  role: role,
  status: status,
  userId: id,
  lastSignIn: DateTime(2026, 10, 18),
  accountCreated: DateTime(2026, 1, 1),
  assembly: assembly,
  region: assembly?.region,
);

ActivityItem _dashboardActivityFixture({
  required String id,
  required String title,
  required ActivitySeverity severity,
  Assembly? assembly,
}) => ActivityItem(
  id: id,
  title: title,
  description: 'Authorized dashboard fixture',
  timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
  severity: severity,
  category: ActivityCategory.userModification,
  tag: 'Administration',
  assembly: assembly,
);

void _preserveAdminUserDirectory() {
  final directory = AdminUserDirectory.instance;
  final users = directory.users.value;
  final state = directory.state.value;
  final loading = directory.loading.value;
  final error = directory.error.value;
  final hasLiveSnapshot = directory.hasLiveSnapshot;
  addTearDown(() {
    directory.users.value = users;
    directory.state.value = state;
    directory.loading.value = loading;
    directory.error.value = error;
    directory.hasLiveSnapshot = hasLiveSnapshot;
  });
}

void _preserveAdminSystemActivityDirectory() {
  final directory = AdminSystemActivityDirectory.instance;
  final items = directory.items.value;
  final health = directory.health.value;
  final state = directory.state.value;
  final loading = directory.loading.value;
  final error = directory.error.value;
  final hasLiveSnapshot = directory.hasLiveSnapshot;
  final hasLiveHealthSnapshot = directory.hasLiveHealthSnapshot;
  addTearDown(() {
    directory.items.value = items;
    directory.health.value = health;
    directory.state.value = state;
    directory.loading.value = loading;
    directory.error.value = error;
    directory.hasLiveSnapshot = hasLiveSnapshot;
    directory.hasLiveHealthSnapshot = hasLiveHealthSnapshot;
  });
}

AdminDashboardData adminDashboardFixture() => const AdminDashboardData(
  stats: AdminDashboardStats(
    totalUsers: 8,
    activeRoles: 4,
    adminActions: 5,
    alertEvents: 2,
  ),
  activityAvailable: true,
  activity: [
    AdminActivityItem(
      title: 'Authorized audit event',
      caption: 'Security · Critical',
    ),
  ],
);

Finder _dashboardMetricValue(String label, String value) => find.descendant(
  of: find.byKey(ValueKey('admin-dashboard-metric-$label')),
  matching: find.text(value),
);

MaintenanceTeam _adminMaintenanceTeamFixture() => MaintenanceTeam(
  teamId: 'TEAM-0001',
  name: 'Kumasi Central Crew',
  region: Region.ashanti,
  assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
  memberUserIds: const ['MNT-000004', 'MNT-000010'],
  createdAt: DateTime(2025, 7, 4),
  leadUserId: 'MNT-000004',
  leadName: 'Yaw Asare',
  leadPhone: '+233 27 777 8888',
);

MaintenanceTeam _seedAdminMaintenanceTeamFixture() {
  _seedAdminUserDirectoryFixture();
  final directory = MaintenanceTeamDirectory.instance;
  final originalTeams = directory.teams.value;
  final originalState = directory.state.value;
  addTearDown(() {
    directory.teams.value = originalTeams;
    directory.state.value = originalState;
  });
  final team = _adminMaintenanceTeamFixture();
  directory.teams.value = [team];
  directory.state.value = MaintenanceTeamDirectoryState.loaded;
  return team;
}

void _seedMaintenanceTeamDirectoryFixture(MaintenanceTeam team) {
  final directory = MaintenanceTeamDirectory.instance;
  final originalTeams = directory.teams.value;
  final originalState = directory.state.value;
  addTearDown(() {
    directory.teams.value = originalTeams;
    directory.state.value = originalState;
  });
  directory.teams.value = [team];
  directory.state.value = MaintenanceTeamDirectoryState.loaded;
}

List<AdminUserItem> _maintenanceMemberFixtures() => [
  for (final user in mockAdminUsers())
    if (user.userId == 'MNT-000004' || user.userId == 'MNT-000010') user,
];

void _setAdminUserDirectoryState({
  required List<AdminUserItem> users,
  required AdminUserDirectoryState state,
  required bool loading,
  required bool hasLiveSnapshot,
  String? error,
}) {
  final directory = AdminUserDirectory.instance;
  directory.hasLiveSnapshot = hasLiveSnapshot;
  directory.users.value = users;
  directory.error.value = error;
  directory.loading.value = loading;
  directory.state.value = state;
}

void _seedAdminUserDirectoryFixture() {
  final directory = AdminUserDirectory.instance;
  final originalUsers = directory.users.value;
  final originalState = directory.state.value;
  final originalLoading = directory.loading.value;
  final originalError = directory.error.value;
  final originalSnapshot = directory.hasLiveSnapshot;
  addTearDown(() {
    directory.users.value = originalUsers;
    directory.state.value = originalState;
    directory.loading.value = originalLoading;
    directory.error.value = originalError;
    directory.hasLiveSnapshot = originalSnapshot;
  });
  directory.users.value = mockAdminUsers();
  directory.state.value = AdminUserDirectoryState.loaded;
  directory.loading.value = false;
  directory.error.value = null;
  directory.hasLiveSnapshot = true;
}

Future<void> _openMaintenanceTeamFormRoute(
  WidgetTester tester, {
  MaintenanceTeam? team,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (formContext) => AdminMaintenanceTeamFormScreen(
                team: team,
                onClose: () => Navigator.of(formContext).pop(),
              ),
            ),
          ),
          child: const Text('Open team form'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open team form'));
  await tester.pumpAndSettle();
}

Future<void> _openMaintenanceTeamDetailsRoute(
  WidgetTester tester, {
  required MaintenanceTeam team,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (detailsContext) => AdminMaintenanceTeamDetailsScreen(
                team: team,
                onBackToTeams: () => Navigator.of(detailsContext).pop(),
              ),
            ),
          ),
          child: const Text('Open team details'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open team details'));
  await tester.pumpAndSettle();
}

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
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            data: adminDashboardFixture(),
            healthStats: mockSystemHealthStats(),
          ),
        ),
      );
      await tester.pump();

      // Dashboard's header shows a centered logo mark, not the "CivicVoice"
      // wordmark text — that now lives only in the drawer.
      expect(find.image(const AssetImage(AppAssets.logoApp)), findsOneWidget);
      expect(find.text('Platform Overview'), findsOneWidget);
      expect(find.text('API: Sample'), findsOneWidget);

      // "System Settings" labels only the Management row now — the top
      // CTA button was dropped as a redundant path to the same
      // destination, and the bottom-nav tab's own label is the shorter
      // "Settings".
      expect(find.text('System Settings'), findsOneWidget);

      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(find.text('Active Roles'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('Admin Actions (24h)'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('Alert events'), findsOneWidget);
      expect(_dashboardMetricValue('Alert events', '2'), findsOneWidget);
      expect(find.text('View alert events'), findsOneWidget);
      final alertEventsAction = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'View alert events'),
      );
      expect(alertEventsAction.onPressed, isNull);

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
      expect(find.text('Authorized audit event'), findsOneWidget);
      expect(find.text('Security · Critical'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Dashboard marks unavailable directory data instead of using mock totals',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      expect(find.text('Unavailable'), findsWidgets);
      expect(
        find.text(
          'Audit records are unavailable until an authorized live snapshot is supplied.',
        ),
        findsOneWidget,
      );
      expect(find.text('Unauthorized Login Attempt'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
    },
  );

  testWidgets(
    'Admin Dashboard distinguishes an authorized zero snapshot from unavailable data',
    (WidgetTester tester) async {
      const zeroData = AdminDashboardData(
        stats: AdminDashboardStats(
          totalUsers: 0,
          activeRoles: 0,
          adminActions: 0,
          alertEvents: 0,
        ),
        activityAvailable: true,
        activity: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminDashboardScreen(data: zeroData),
        ),
      );
      await tester.pump();

      expect(find.text('0'), findsNWidgets(4));
      expect(find.text('Unavailable'), findsNothing);
      expect(
        find.text('No authorized activity is available for this scope.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Admin Dashboard reacts to explicit directory snapshots and updates',
    (WidgetTester tester) async {
      final users = AdminUserDirectory.instance;
      final activity = AdminSystemActivityDirectory.instance;
      _preserveAdminUserDirectory();
      _preserveAdminSystemActivityDirectory();
      users.users.value = const [];
      users.hasLiveSnapshot = false;
      users.state.value = AdminUserDirectoryState.unavailable;
      users.loading.value = false;
      users.error.value = null;
      activity.items.value = const [];
      activity.hasLiveSnapshot = false;
      activity.state.value = AdminSystemActivityDirectoryState.unavailable;
      activity.loading.value = false;
      activity.error.value = null;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();
      expect(find.text('Unavailable'), findsWidgets);

      users.users.value = [
        _dashboardUserFixture(id: 'U-1', role: AppRole.systemAdministrator),
      ];
      users.hasLiveSnapshot = true;
      users.state.value = AdminUserDirectoryState.loaded;
      users.loading.value = false;
      users.error.value = null;
      activity.items.value = [
        _dashboardActivityFixture(
          id: 'A-1',
          title: 'Critical activity',
          severity: ActivitySeverity.critical,
        ),
      ];
      activity.hasLiveSnapshot = true;
      activity.state.value = AdminSystemActivityDirectoryState.loaded;
      await tester.pump();

      expect(_dashboardMetricValue('Total Users', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Active Roles', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Admin Actions (24h)', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Alert events', '1'), findsOneWidget);
      expect(find.text('Critical activity'), findsOneWidget);

      users.users.value = [
        _dashboardUserFixture(id: 'U-1', role: AppRole.systemAdministrator),
        _dashboardUserFixture(id: 'U-2', role: AppRole.maintenanceTeam),
      ];
      await tester.pump();
      expect(_dashboardMetricValue('Total Users', '2'), findsOneWidget);

      activity.items.value = [
        _dashboardActivityFixture(
          id: 'A-1',
          title: 'Critical activity',
          severity: ActivitySeverity.critical,
        ),
        _dashboardActivityFixture(
          id: 'A-2',
          title: 'Alert activity',
          severity: ActivitySeverity.alert,
        ),
        _dashboardActivityFixture(
          id: 'A-3',
          title: 'Informational activity',
          severity: ActivitySeverity.info,
        ),
      ];
      await tester.pump();

      // Three authorized events are visible, but only Alert and Critical
      // contribute to the Alert events metric.
      expect(_dashboardMetricValue('Admin Actions (24h)', '3'), findsOneWidget);
      expect(_dashboardMetricValue('Alert events', '2'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Dashboard renders confirmed empty directories as zero and marks failed snapshots stale',
    (WidgetTester tester) async {
      final users = AdminUserDirectory.instance;
      final activity = AdminSystemActivityDirectory.instance;
      _preserveAdminUserDirectory();
      _preserveAdminSystemActivityDirectory();
      users.users.value = const [];
      users.hasLiveSnapshot = true;
      users.state.value = AdminUserDirectoryState.loaded;
      users.loading.value = false;
      users.error.value = null;
      activity.items.value = const [];
      activity.hasLiveSnapshot = true;
      activity.state.value = AdminSystemActivityDirectoryState.loaded;
      activity.loading.value = false;
      activity.error.value = null;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();
      expect(_dashboardMetricValue('Total Users', '0'), findsOneWidget);
      expect(_dashboardMetricValue('Active Roles', '0'), findsOneWidget);
      expect(_dashboardMetricValue('Admin Actions (24h)', '0'), findsOneWidget);
      expect(_dashboardMetricValue('Alert events', '0'), findsOneWidget);

      activity.error.value = 'Refresh failed';
      activity.state.value = AdminSystemActivityDirectoryState.failed;
      await tester.pump();
      expect(
        find.text('Some dashboard data may be stale after a failed refresh.'),
        findsOneWidget,
      );
      expect(_dashboardMetricValue('Alert events', '0'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Dashboard scopes live directory metrics to an assembly Admin',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      final kumasi = assemblyNamed(Region.ashanti, 'Kumasi');
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: kumasi,
      );
      addTearDown(() => MockAuthService().clearUser());

      final users = AdminUserDirectory.instance;
      final activity = AdminSystemActivityDirectory.instance;
      _preserveAdminUserDirectory();
      _preserveAdminSystemActivityDirectory();
      users.users.value = [
        _dashboardUserFixture(
          id: 'KUM-1',
          role: AppRole.maintenanceTeam,
          assembly: kumasi,
        ),
        _dashboardUserFixture(
          id: 'ACC-1',
          role: AppRole.maintenanceTeam,
          assembly: assemblyNamed(Region.greaterAccra, 'Accra'),
        ),
      ];
      users.hasLiveSnapshot = true;
      users.state.value = AdminUserDirectoryState.loaded;
      users.loading.value = false;
      users.error.value = null;
      activity.items.value = [
        _dashboardActivityFixture(
          id: 'KUM-A',
          title: 'Kumasi alert',
          severity: ActivitySeverity.alert,
          assembly: kumasi,
        ),
        _dashboardActivityFixture(
          id: 'ACC-A',
          title: 'Accra critical',
          severity: ActivitySeverity.critical,
          assembly: assemblyNamed(Region.greaterAccra, 'Accra'),
        ),
        _dashboardActivityFixture(
          id: 'PLATFORM-A',
          title: 'Platform critical',
          severity: ActivitySeverity.critical,
        ),
      ];
      activity.hasLiveSnapshot = true;
      activity.state.value = AdminSystemActivityDirectoryState.loaded;
      activity.loading.value = false;
      activity.error.value = null;

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      expect(find.text('Kumasi alert'), findsOneWidget);
      expect(find.text('Accra critical'), findsNothing);
      expect(find.text('Platform critical'), findsNothing);
      // The only visible event is the in-scope alert; no platform totals are
      // calculated from the other fixture records.
      expect(_dashboardMetricValue('Total Users', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Active Roles', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Admin Actions (24h)', '1'), findsOneWidget);
      expect(_dashboardMetricValue('Alert events', '1'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Dashboard remains usable at 375px and 1.5x text scale with live data',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final users = AdminUserDirectory.instance;
      final activity = AdminSystemActivityDirectory.instance;
      _preserveAdminUserDirectory();
      _preserveAdminSystemActivityDirectory();
      users.users.value = [
        _dashboardUserFixture(id: 'U-1', role: AppRole.systemAdministrator),
      ];
      users.hasLiveSnapshot = true;
      users.state.value = AdminUserDirectoryState.loaded;
      users.loading.value = false;
      users.error.value = null;
      activity.items.value = [
        _dashboardActivityFixture(
          id: 'A-1',
          title: 'Accessible critical activity',
          severity: ActivitySeverity.critical,
        ),
      ];
      activity.hasLiveSnapshot = true;
      activity.state.value = AdminSystemActivityDirectoryState.loaded;
      activity.loading.value = false;
      activity.error.value = null;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const AdminDashboardScreen(),
          ),
        ),
      );
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Total Users'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('Alert events'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      var activityTapped = false;
      var settingsTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            onNavigateToUsers: () => usersTapped = true,
            onNavigateToActivity: () => activityTapped = true,
            onNavigateToSettings: () => settingsTapped = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      // The bottom-nav tab's own label is "Settings" — shorter than the
      // Management row's "System Settings".
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);

      await tester.tap(find.text('Activity'));
      await tester.pump();
      expect(activityTapped, isTrue);

      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(settingsTapped, isTrue);
    },
  );

  testWidgets('Admin Dashboard Management row System Settings entry fires the '
      'callback', (WidgetTester tester) async {
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
  });

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
            onNavigateToActivity: () => activityTapped = true,
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
      _seedAdminUserDirectoryFixture();
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
      expect(find.text('MUN-000002'), findsOneWidget);

      // User Management's own route is still mounted underneath (kept
      // alive by the pushed route), so it has its own hamburger icon too
      // — `.last` targets the topmost, currently-visible User Details
      // screen's.
      await tester.tap(find.byIcon(AppIcons.menu).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Role Management').last);
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

  testWidgets('Admin Dashboard does not invent retry success without a callback', (
    WidgetTester tester,
  ) async {
    await pumpAdminDashboard(tester, AdminDashboardViewState.error);

    final retry = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(retry.onPressed, isNull);
    expect(find.text('Unable to Load Dashboard'), findsOneWidget);
  });

  testWidgets(
    'Admin Dashboard greets an assembly Admin by their provisioned name '
    'and assembly, instead of Platform Overview',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      );
      addTearDown(() => MockAuthService().clearUser());
      _seedAdminUserDirectoryFixture();

      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      expect(find.text('Platform Overview'), findsNothing);
      // "Efua Darko" is the seeded Admin-tier account for Kumasi.
      expect(find.text('${timeBasedGreeting()}, Efua Darko'), findsOneWidget);
      expect(find.text('Kumasi Metropolitan Assembly'), findsOneWidget);
      expect(find.textContaining('API:'), findsNothing);
    },
  );

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
    // "Role Management" also appears as Dashboard's own Management row
    // title — scoped to the drawer so this only checks the drawer's own
    // item, not that unrelated duplicate.
    expect(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Role Management'),
      ),
      findsOneWidget,
    );
    expect(find.text('Admin Profile'), findsOneWidget);
  });

  testWidgets(
    'Admin header menu and notification controls have one accessible label each',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(onNotificationsTap: () {}),
        ),
      );
      await tester.pump();

      final semantics = tester.ensureSemantics();
      try {
        final menu = find.bySemanticsLabel('Open navigation menu');
        final notifications = find.bySemanticsLabel('Notifications');
        expect(menu, findsOneWidget);
        expect(notifications, findsOneWidget);
        expect(tester.getSemantics(menu).flagsCollection.isButton, isTrue);
        expect(
          tester.getSemantics(menu).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isTrue,
        );
        expect(
          tester.getSemantics(notifications).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isTrue,
        );

        await tester.tap(menu);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(Drawer), findsOneWidget);
      } finally {
        semantics.dispose();
      }

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      final disabledSemantics = tester.ensureSemantics();
      try {
        final notifications = find.bySemanticsLabel('Notifications');
        expect(notifications, findsOneWidget);
        expect(
          tester.getSemantics(notifications).flagsCollection.isEnabled == Tristate.isTrue,
          isFalse,
        );
        expect(
          tester.getSemantics(notifications).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isFalse,
        );
      } finally {
        disabledSemantics.dispose();
      }
    },
  );

  testWidgets(
    'Admin header preserves Back and disabled-control semantics',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      );
      addTearDown(() => MockAuthService().clearUser());

      var profileTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminDashboardScreen(
            onOpenProfile: () => profileTapped = true,
          ),
        ),
      );
      await tester.pump();

      final semantics = tester.ensureSemantics();
      try {
        final profile = find.bySemanticsLabel('Admin profile');
        expect(profile, findsOneWidget);
        expect(
          tester.getSemantics(profile).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isTrue,
        );
        await tester.tap(profile);
        expect(profileTapped, isTrue);
      } finally {
        semantics.dispose();
      }

      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminProfileScreen(onBack: () => backTapped = true),
        ),
      );
      await tester.pump();

      final backSemantics = tester.ensureSemantics();
      try {
        final back = find.bySemanticsLabel('Go back');
        expect(back, findsOneWidget);
        await tester.tap(back);
        expect(backTapped, isTrue);
      } finally {
        backSemantics.dispose();
      }

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
      );
      await tester.pump();

      final disabledSemantics = tester.ensureSemantics();
      try {
        final profile = find.bySemanticsLabel('Admin profile');
        expect(profile, findsOneWidget);
        expect(
          tester.getSemantics(profile).flagsCollection.isEnabled == Tristate.isTrue,
          isFalse,
        );
        expect(
          tester.getSemantics(profile).getSemanticsData().hasAction(
            SemanticsAction.tap,
          ),
          isFalse,
        );
      } finally {
        disabledSemantics.dispose();
      }
    },
  );

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

      // Dashboard/Users/Activity/Settings are already one tap away on the
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
      expect(drawerLabels, ['Role Management', 'Admin Profile']);
    },
  );

  testWidgets('Admin drawer Role Management and Admin Profile items fire their '
      'callbacks and close the drawer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var rolesTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminDashboardScreen(onNavigateToRoles: () => rolesTapped = true),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // "Role Management" also appears as Dashboard's own Management row
    // title underneath the drawer — scope the tap to the drawer's item.
    await tester.tap(
      find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Role Management'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(rolesTapped, isTrue);
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

  testWidgets(
    'Admin drawer marks only Role Management as the active destination',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminRoleManagementScreen(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pumpAndSettle();

      final roleTile = find.ancestor(
        of: find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Role Management'),
        ),
        matching: find.byType(ListTile),
      );
      final profileTile = find.ancestor(
        of: find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Admin Profile'),
        ),
        matching: find.byType(ListTile),
      );

      expect(tester.widget<ListTile>(roleTile).selected, isTrue);
      expect(tester.widget<ListTile>(profileTile).selected, isFalse);
      expect(
        tester.getSemantics(roleTile).flagsCollection.isSelected == Tristate.isTrue,
        isTrue,
      );
      expect(
        tester
            .widgetList<ListTile>(
              find.descendant(
                of: find.byType(Drawer),
                matching: find.byType(ListTile),
              ),
            )
            .where((tile) => tile.selected)
            .length,
        1,
      );
    },
  );

  testWidgets('Admin drawer marks Admin Profile as the active destination', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
    );
    await tester.pump();
    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pumpAndSettle();

    final profileTile = find.ancestor(
      of: find.descendant(
        of: find.byType(Drawer),
        matching: find.text('Admin Profile'),
      ),
      matching: find.byType(ListTile),
    );
    expect(tester.widget<ListTile>(profileTile).selected, isTrue);
    expect(
      tester.getSemantics(profileTile).flagsCollection.isSelected == Tristate.isTrue,
      isTrue,
    );
  });

  testWidgets(
    'Admin drawer keeps Maintenance Teams active across its route family',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminMaintenanceTeamsScreen(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pumpAndSettle();

      final teamsTile = find.ancestor(
        of: find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Maintenance Teams'),
        ),
        matching: find.byType(ListTile),
      );
      expect(tester.widget<ListTile>(teamsTile).selected, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminMaintenanceTeamFormScreen(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pumpAndSettle();
      expect(tester.widget<ListTile>(teamsTile).selected, isTrue);
    },
  );

  testWidgets('Admin drawer closes with native Back and barrier dismissal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
    );
    await tester.pump();

    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Drawer), findsNothing);

    await tester.tap(find.byIcon(AppIcons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tapAt(const Offset(410, 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgets('Assembly Admin does not receive the Super Admin drawer', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await MockAuthService().initialize();
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.admin,
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    );
    addTearDown(() => MockAuthService().clearUser());

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminDashboardScreen()),
    );
    await tester.pump();

    expect(find.byIcon(AppIcons.menu), findsNothing);
    expect(find.byType(Drawer), findsNothing);
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
      _seedAdminUserDirectoryFixture();
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
      expect(find.text('+233 24 111 2222'), findsOneWidget);
      // "System Administrator" labels both Ama Boateng's (Super Admin) and
      // Efua Darko's (Admin) role pills.
      expect(find.text('System Administrator'), findsNWidgets(2));
      // "Active" labels five of the eight mock users' status pills (Kojo
      // Mensah, Yaw Asare, Kojo Mensah-Boateng, Genevieve Amadapah, Efua
      // Darko).
      expect(find.text('Active'), findsNWidgets(5));
      expect(find.text('Kojo Mensah'), findsOneWidget);
      expect(find.text('Municipal Officer'), findsOneWidget);
      expect(find.text('Esi Owusu'), findsOneWidget);
      expect(find.text('Ministry Supervisor'), findsOneWidget);
      // "Review" labels Esi Owusu's and Kwame Nyarko's status pills.
      expect(find.text('Review'), findsNWidgets(2));
      expect(find.text('Yaw Asare'), findsOneWidget);
      // "Maintenance Team" labels both Yaw Asare's and Kojo Mensah-Boateng's
      // role pills — the second real technician added so the team-lead
      // feature has more than one member to be meaningful for.
      expect(find.text('Maintenance Team'), findsNWidgets(2));
      expect(find.text('Kojo Mensah-Boateng'), findsOneWidget);
      expect(find.text('Kwame Nyarko'), findsOneWidget);
      expect(find.text('Genevieve Amadapah'), findsOneWidget);
      expect(find.text('Efua Darko'), findsOneWidget);
      // "Citizen" labels both Kwame Nyarko's and Genevieve Amadapah's role
      // pills.
      expect(find.text('Citizen'), findsNWidgets(2));
    },
  );

  testWidgets('Admin User Management distinguishes unavailable user data', (
    WidgetTester tester,
  ) async {
    final directory = AdminUserDirectory.instance;
    final originalUsers = directory.users.value;
    final originalState = directory.state.value;
    final originalSnapshot = directory.hasLiveSnapshot;
    addTearDown(() {
      directory.users.value = originalUsers;
      directory.state.value = originalState;
      directory.hasLiveSnapshot = originalSnapshot;
    });
    directory.users.value = const <AdminUserItem>[];
    directory.state.value = AdminUserDirectoryState.unavailable;
    directory.hasLiveSnapshot = false;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminUserManagementScreen()),
    );
    await tester.pump();

    expect(find.text('User data unavailable'), findsOneWidget);
    expect(find.text('No Users'), findsNothing);
    expect(find.byType(GhanaRefreshIndicator), findsNothing);
  });

  testWidgets('Admin User Management shows confirmed empty data as empty', (
    WidgetTester tester,
  ) async {
    final directory = AdminUserDirectory.instance;
    final originalUsers = directory.users.value;
    final originalState = directory.state.value;
    final originalSnapshot = directory.hasLiveSnapshot;
    addTearDown(() {
      directory.users.value = originalUsers;
      directory.state.value = originalState;
      directory.hasLiveSnapshot = originalSnapshot;
    });
    directory.users.value = const <AdminUserItem>[];
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.hasLiveSnapshot = true;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminUserManagementScreen()),
    );
    await tester.pump();

    expect(find.text('No Users'), findsOneWidget);
    expect(find.text('User data unavailable'), findsNothing);
  });

  testWidgets('Admin User Management retains stale confirmed users after failure', (
    WidgetTester tester,
  ) async {
    final directory = AdminUserDirectory.instance;
    final originalUsers = directory.users.value;
    final originalState = directory.state.value;
    final originalSnapshot = directory.hasLiveSnapshot;
    addTearDown(() {
      directory.users.value = originalUsers;
      directory.state.value = originalState;
      directory.hasLiveSnapshot = originalSnapshot;
    });
    directory.users.value = [mockAdminUsers().first];
    directory.state.value = AdminUserDirectoryState.failed;
    directory.hasLiveSnapshot = true;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminUserManagementScreen()),
    );
    await tester.pump();

    expect(find.text('Ama Boateng'), findsOneWidget);
    expect(
      find.text('Showing previously confirmed user data. Refresh failed.'),
      findsOneWidget,
    );
  });

  testWidgets('Admin User Management shows a first-load failure as an error', (
    WidgetTester tester,
  ) async {
    final directory = AdminUserDirectory.instance;
    final originalState = directory.state.value;
    final originalSnapshot = directory.hasLiveSnapshot;
    final originalAvailable = directory.firebaseAvailableForTesting;
    addTearDown(() {
      directory.state.value = originalState;
      directory.hasLiveSnapshot = originalSnapshot;
      directory.firebaseAvailableForTesting = originalAvailable;
    });
    directory.firebaseAvailableForTesting = true;
    directory.state.value = AdminUserDirectoryState.failed;
    directory.hasLiveSnapshot = false;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminUserManagementScreen()),
    );
    await tester.pump();

    expect(find.text('Unable to Load Users'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Admin User Management marks a failed empty refresh as stale', (
    WidgetTester tester,
  ) async {
    final directory = AdminUserDirectory.instance;
    final originalUsers = directory.users.value;
    final originalState = directory.state.value;
    final originalSnapshot = directory.hasLiveSnapshot;
    addTearDown(() {
      directory.users.value = originalUsers;
      directory.state.value = originalState;
      directory.hasLiveSnapshot = originalSnapshot;
    });
    directory.users.value = const <AdminUserItem>[];
    directory.state.value = AdminUserDirectoryState.failed;
    directory.hasLiveSnapshot = true;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminUserManagementScreen()),
    );
    await tester.pump();

    expect(find.text('No Users'), findsOneWidget);
    expect(
      find.text('The last confirmed user list was empty. The latest refresh failed.'),
      findsOneWidget,
    );
  });

  testWidgets('Admin User Management search field filters the user list', (
    WidgetTester tester,
  ) async {
    _seedAdminUserDirectoryFixture();
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

    await tester.tap(find.text('Search users'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'kojo');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();

    expect(find.text('Kojo Mensah'), findsOneWidget);
    expect(find.text('Ama Boateng'), findsNothing);
  });

  testWidgets(
    'Admin User Management Admins filter chip shows only admin users',
    (WidgetTester tester) async {
      _seedAdminUserDirectoryFixture();
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
    'Admin User Management does not claim a local deactivate success',
    (WidgetTester tester) async {
      _seedAdminUserDirectoryFixture();
      final originalUsers = List<AdminUserItem>.of(
        AdminUserDirectory.instance.users.value,
      );
      addTearDown(
        () => AdminUserDirectory.instance.users.value = originalUsers,
      );
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

      expect(find.text('Could not update this account.'), findsOneWidget);

      // Ama Boateng and Kojo Mensah are now both "Inactive" (joining the
      // filter chip of the same name) — Yaw Asare, Kojo Mensah-Boateng,
      // Genevieve Amadapah, and Efua Darko are still "Active" (Esi Owusu
      // and Kwame Nyarko remain "Review").
      expect(find.text('Inactive'), findsNWidgets(2));
      expect(find.text('Active'), findsNWidgets(5));
    },
  );

  testWidgets(
    'Admin User Management kebab menu remains visible near the lower viewport edge',
    (WidgetTester tester) async {
      _seedAdminUserDirectoryFixture();
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

      final lastMenu = find.byIcon(AppIcons.more).last;
      // The first scrollable is the horizontal filter-chip row. Scroll the
      // vertical user list so the final card's menu clears the floating nav.
      final userList = find.byType(Scrollable).last;
      await tester.drag(
        userList,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(lastMenu);
      expect(tester.getRect(lastMenu).bottom, lessThan(720));
      await tester.tap(lastMenu);
      await tester.pumpAndSettle();

      final action = find.text('Deactivate account');
      expect(action, findsOneWidget);
      expect(
        tester.getRect(action).bottom,
        lessThanOrEqualTo(tester.view.physicalSize.height),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Admin User Management does not claim a local delete success', (
    WidgetTester tester,
  ) async {
    _seedAdminUserDirectoryFixture();
    final originalUsers = List<AdminUserItem>.of(
      AdminUserDirectory.instance.users.value,
    );
    addTearDown(() => AdminUserDirectory.instance.users.value = originalUsers);
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

    await tester.tap(find.byIcon(AppIcons.more).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete account permanently'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this account permanently?'), findsOneWidget);
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    expect(find.text('Could not delete this account.'), findsOneWidget);
    expect(find.text('Kojo Mensah'), findsOneWidget);
  });

  testWidgets('Admin User Management tapping a user card opens User Details', (
    WidgetTester tester,
  ) async {
    _seedAdminUserDirectoryFixture();
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
      expect(find.text('Refresh'), findsNothing);
      expect(find.text('Search users'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin User Management No Results clears filters and returns to the '
    'loaded state',
    (WidgetTester tester) async {
      _seedAdminUserDirectoryFixture();
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

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Home'));
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
      expect(find.text('Reference tier — server enforcement is verified separately.'),
          findsNWidgets(2));
      expect(find.text('Reference permission comparison'), findsOneWidget);
      expect(
        find.text(
          'This reference does not verify current server authorization.',
        ),
        findsOneWidget,
      );
      // "Super Admin" appears twice — once as a card title, once as its
      // Quick Permissions Check table column header.
      expect(find.text('Super Admin'), findsWidgets);
      expect(find.text('Reference national access'), findsOneWidget);
      expect(find.text('Admin'), findsWidgets);
      expect(find.text('Reference standard access'), findsOneWidget);
      expect(find.text('Export Reports'), findsWidgets);
      expect(find.text('View Audit Logs'), findsWidgets);
      expect(find.text('Audit history unavailable'), findsOneWidget);
      expect(find.textContaining('14 days ago'), findsNothing);
      expect(find.text('View Detailed Logs'), findsNothing);
      expect(find.text('Quick Permissions Check'), findsNothing);
      // Appears both as the table's row label and Super Admin's own tag
      // chip (Super Admin is granted every permission).
      expect(find.text('Delete Records'), findsWidgets);

      // No management affordances — the tier set is fixed and read-only.
      expect(find.byType(PopupMenuButton<void>), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(
        find.bySemanticsLabel(
          'Reference permission: Super Admin allows Delete Records.',
        ),
        findsOneWidget,
      );
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

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);
    },
  );

  testWidgets('Admin Role Management does not substitute unfiltered Activity '
      'for unavailable audit history', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminRoleManagementScreen()),
    );
    await tester.pump();

    expect(find.text('Audit history unavailable'), findsOneWidget);
    expect(find.text('View Detailed Logs'), findsNothing);
  });

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
    expect(find.text('Retry connection'), findsNothing);
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
    expect(find.text('Retry'), findsNothing);
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

  testWidgets('Admin Role Management error has no false-success Retry', (
    WidgetTester tester,
  ) async {
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
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Super Admin'), findsNothing);
  });

  testWidgets('Admin Role Management permission reference remains usable at '
      '1.5x text scale', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: const AdminRoleManagementScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reference permission comparison'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets(
    'Admin User Details keeps its compact identity usable at larger text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: AdminUserDetailsScreen(user: findMockUser('Yaw Asare')),
        ),
      );
      await tester.pump();

      expect(find.text('YA'), findsOneWidget);
      expect(find.text('Yaw Asare'), findsWidgets);
      expect(find.text('+233 27 777 8888'), findsWidgets);
      expect(find.text('Maintenance Team'), findsWidgets);
      expect(find.text('Active'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Admin User Details shows a compact accessible identity and '
      'calm account sections in its loaded state', (WidgetTester tester) async {
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
    // The compact identity is left-aligned and exposed once to assistive
    // technology; account information remains visible below it.
    expect(
      find.bySemanticsLabel(
        'User identity: Yaw Asare, +233 27 777 8888, Maintenance Team',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Account status: Active'), findsOneWidget);
    expect(find.text('YA'), findsOneWidget);
    expect(find.text('Yaw Asare'), findsWidgets);
    expect(
      tester.getTopLeft(find.text('YA')).dx,
      lessThan(tester.getTopLeft(find.text('Yaw Asare').first).dx),
    );
    expect(find.text('+233 27 777 8888'), findsWidgets);
    // The status pill and the assigned-role dropdown both display this
    // current value; neither is duplicate account state.
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('MNT-000004'), findsOneWidget);
    expect(find.text('Account information'), findsOneWidget);
    expect(find.text('Access'), findsOneWidget);
    expect(find.text('Permissions'), findsOneWidget);
    expect(find.text('Account Activity'), findsOneWidget);
    expect(find.text('Administrative actions'), findsOneWidget);
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
      await tester.tap(find.byType(AppDropdownField<AppRole>));
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

      await tester.tap(find.byType(AppDropdownField<AppRole>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Citizen').last);
      await tester.pumpAndSettle();

      expect(find.text('Admin Tier'), findsNothing);
    },
  );

  testWidgets(
    'Admin User Details Save Changes does not fabricate a server success',
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

      // No Firebase/API fixture is supplied here, so the screen must not
      // manufacture a successful update for this local preview record.
      expect(find.text('Changes saved'), findsNothing);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(saved, isNull);
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

  testWidgets('Admin User Details back arrow returns to User Management', (
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

    expect(find.byTooltip('Back to user management'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to user management'));
    await tester.pump();

    expect(backTapped, isTrue);
  });

  testWidgets(
    'Admin User Details Save remains on the screen when the server update fails',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var returnedToUsers = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminUserDetailsScreen(
            user: findMockUser('Yaw Asare'),
            onNavigateToUsers: () => returnedToUsers = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes').last);
      await tester.pumpAndSettle();

      expect(returnedToUsers, isFalse);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Changes saved'), findsNothing);
    },
  );

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

      await tester.tap(find.text('Home'));
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
    'Admin User Details keeps a failed reload unavailable without a genuine '
    'refresh callback',
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

      expect(find.text('Retry'), findsNothing);
      expect(find.text('Retry connection'), findsNothing);
      expect(
        find.text(
          'Unable to load user details right now. Reloading details is not available from this screen.',
        ),
        findsOneWidget,
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Yaw Asare'), findsNothing);
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
    'Admin System Activity keeps filters and content usable at 375px and '
    '1.5x text scale',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AdminSystemActivityScreen(items: _adminActivityFixture()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('All Events'), findsOneWidget);
      expect(find.byType(AppDropdownField<ActivityTimeRange>), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Activity keeps its unavailable explanation readable at '
    '375px and 1.5x text scale',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AdminSystemActivityScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Activity data unavailable'), findsOneWidget);
      expect(
        find.text(
          'Audit activity is unavailable until an authorized live snapshot is supplied.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AdminSystemActivityScreen(
              items: [],
              activitySnapshotAvailable: true,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No activity matches your filters.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Activity distinguishes unavailable data from a confirmed empty feed',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminSystemActivityScreen()),
      );
      await tester.pump();
      expect(find.text('Activity data unavailable'), findsOneWidget);
      expect(find.text('No activity matches your filters.'), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemActivityScreen(
            items: [],
            activitySnapshotAvailable: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Activity data unavailable'), findsNothing);
      expect(find.text('No activity matches your filters.'), findsOneWidget);
      expect(
        find.text(
          'System health unavailable until an authorized live snapshot is supplied.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Admin System Activity observes directory unavailable, loading, empty, and stale states',
    (WidgetTester tester) async {
      final directory = AdminSystemActivityDirectory.instance;
      _preserveAdminSystemActivityDirectory();
      directory.items.value = const [];
      directory.health.value = null;
      directory.hasLiveSnapshot = false;
      directory.state.value = AdminSystemActivityDirectoryState.unavailable;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.loading,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Activity data unavailable'), findsOneWidget);

      directory.state.value = AdminSystemActivityDirectoryState.loading;
      await tester.pump();
      expect(find.text('Activity data unavailable'), findsNothing);
      expect(find.text('Recent Activity'), findsNothing);

      directory.hasLiveSnapshot = true;
      directory.state.value = AdminSystemActivityDirectoryState.loaded;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.loaded,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('No activity matches your filters.'), findsOneWidget);

      directory.items.value = _adminActivityFixture();
      directory.state.value = AdminSystemActivityDirectoryState.failed;
      await tester.pump();
      expect(
        find.text(
          'The latest activity could not be refreshed. Showing the last authorized snapshot.',
        ),
        findsOneWidget,
      );
      expect(find.text('Unauthorized Login Attempt'), findsOneWidget);
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
          home: AdminSystemActivityScreen(
            items: _adminActivityFixture(),
            healthStats: mockSystemHealthStats(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('System Activity'), findsOneWidget);
      expect(find.text('API Status'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('DB Latency'), findsOneWidget);
      expect(find.text('42ms'), findsOneWidget);
      expect(find.text('Uptime'), findsOneWidget);
      expect(find.text('4d 6h'), findsOneWidget);
      expect(find.text('Sample system health'), findsOneWidget);
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
      // Both mock citizen-registration events (Kumasi and Accra) happened
      // within the last 24 hours too, so a Super Admin session — which
      // sees every assembly's events, unlike a scoped assembly Admin —
      // finds both here.
      expect(find.text('Citizen Account Registered'), findsNWidgets(2));
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Standard'), findsOneWidget);
      // Automated Backup Complete plus both citizen registrations all
      // share Info severity.
      expect(find.text('Info'), findsNWidgets(3));
      // "Administrative Credential Issued" happened over a day ago, so
      // the default "Last 24 Hours" range already excludes it — covered
      // separately by the time-range dropdown test below.
      expect(find.text('Administrative Credential Issued'), findsNothing);

      // System Activity is now its own bottom-nav tab (see [AdminTab]'s
      // own doc comment), so its "Activity" nav item renders selected —
      // confirmed via the selected-tab text color every other selected
      // nav item uses (a plain color/weight change, no filled background —
      // matching Citizen's own bottom nav). The selected color is the
      // accessible action ink, never the gold fill (1.47:1 on white).
      final activityLabel = tester.widget<Text>(find.text('Activity'));
      expect(activityLabel.style?.color, AppColors.primaryText);
    },
  );

  testWidgets(
    'Admin System Activity scopes an assembly Admin to their own region, '
    'hides the health stats, and keeps the Activity tab visible',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      );
      addTearDown(() => MockAuthService().clearUser());

      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            items: _adminActivityFixture(),
            activitySnapshotAvailable: true,
          ),
        ),
      );
      await tester.pump();

      // No national-scope health readout for an assembly Admin.
      expect(find.text('API Status'), findsNothing);
      expect(find.text('DB Latency'), findsNothing);
      expect(find.text('Uptime'), findsNothing);

      // Only the Kumasi citizen registration is theirs to audit — not the
      // Accra one, and not the platform-wide events with no assembly of
      // their own (Unauthorized Login Attempt, System Policy Update,
      // Automated Backup Complete).
      expect(find.text('Citizen Account Registered'), findsOneWidget);
      expect(
        find.text(
          'A new citizen account self-registered from Kumasi, Ashanti '
          'Region.',
        ),
        findsOneWidget,
      );
      expect(find.text('Unauthorized Login Attempt'), findsNothing);
      expect(find.text('System Policy Update'), findsNothing);
      expect(find.text('Automated Backup Complete'), findsNothing);

      // The Activity tab itself still shows — only Settings drops for an
      // assembly Admin.
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
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
        home: AdminSystemActivityScreen(items: _adminActivityFixture()),
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
          home: AdminSystemActivityScreen(items: _adminActivityFixture()),
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
      await tester.tap(find.byType(AppDropdownField<ActivityTimeRange>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Last 7 Days').last);
      await tester.pumpAndSettle();

      // Broadening the range reveals it.
      expect(find.text('Administrative Credential Issued'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Activity scrolls the time range with Activity content after search chrome collapses',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            items: _adminActivityFixture(),
            activitySnapshotAvailable: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final timeRange = find.byType(AppDropdownField<ActivityTimeRange>);
      final initialTop = tester.getTopLeft(timeRange).dy;
      // A modest scroll keeps the list's first child mounted while proving
      // that the time range travels with normal Activity content.
      final contentScroll = find.byType(Scrollable).last;
      await tester.drag(contentScroll, const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(timeRange, findsOneWidget);
      expect(tester.getTopLeft(timeRange).dy, lessThan(initialTop));
    },
  );

  testWidgets(
    'Admin System Activity labels only a complete directory health snapshot Live',
    (WidgetTester tester) async {
      final directory = AdminSystemActivityDirectory.instance;
      _preserveAdminSystemActivityDirectory();
      directory.items.value = _adminActivityFixture();
      directory.state.value = AdminSystemActivityDirectoryState.loaded;
      directory.hasLiveSnapshot = true;
      directory.health.value = SystemHealthStats(
        apiOnline: true,
        databaseOnline: true,
        dbLatencyMs: 12,
        uptimeSeconds: 3600,
        checkedAt: DateTime(2026, 10, 17, 12),
      );
      directory.hasLiveHealthSnapshot = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(items: directory.items.value),
        ),
      );
      await tester.pump();
      expect(find.text('Live system health'), findsOneWidget);
      expect(find.text('Sample system health'), findsNothing);
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
            items: _adminActivityFixture(),
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
          home: AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.noResults,
            items: _adminActivityFixture(),
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
            items: [],
            activitySnapshotAvailable: true,
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
            activitySnapshotAvailable: false,
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
            activitySnapshotAvailable: false,
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
            activitySnapshotAvailable: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Unauthorized Access'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );

  testWidgets(
    'Admin System Activity does not invent retry success without a callback',
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
            activitySnapshotAvailable: false,
          ),
        ),
      );
      await tester.pump();

      final retry = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Retry'),
      );
      expect(retry.onPressed, isNull);
      expect(find.text('Something went wrong'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Activity remains in error when its genuine refresh fails',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(
            initialState: AdminSystemActivityViewState.error,
            activitySnapshotAvailable: false,
            onRefresh: () async => throw StateError('network unavailable'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Something went wrong'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Activity shows an inline notice instead of the feed when '
    'Audit logging is off',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _preserveAdminSystemSettingsDirectory();
      _setConfirmedSystemSettingsFixture();
      AdminSystemSettingsDirectory.instance.settings.value =
          AdminSystemSettingsDirectory.instance.settings.value.copyWith(
            auditLogging: false,
          );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminSystemActivityScreen(items: _adminActivityFixture()),
        ),
      );
      await tester.pump();

      expect(find.text('Audit logging is turned off'), findsOneWidget);
      // A known seeded activity item's title — absent because the feed
      // itself isn't rendering at all, not because of a filter.
      expect(find.text('Unauthorized Login Attempt'), findsNothing);
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
    'Admin System Settings keeps supported controls usable at 375px and '
    '1.5x text scale',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AdminSystemSettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('System Preferences'), findsOneWidget);
      expect(find.text('Session timeout'), findsOneWidget);
      expect(find.text('Audit logging'), findsOneWidget);
      expect(find.text('Allow new account creation'), findsOneWidget);
      expect(find.byType(AppDropdownField<String>), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Settings keeps its unavailable explanation readable at '
    '375px and 1.5x text scale',
    (WidgetTester tester) async {
      final directory = AdminSystemSettingsDirectory.instance;
      _preserveAdminSystemSettingsDirectory();
      directory.hasLiveSnapshot = false;
      directory.state.value = AdminSystemSettingsDirectoryState.unavailable;
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: AdminSystemSettingsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('System settings unavailable'), findsOneWidget);
      expect(
        find.text(
          'Settings are unavailable until an authorized server snapshot is supplied.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Admin System Settings shows every section and field in its loaded '
    'state, with no Save bar when clean',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
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

      expect(find.text('System Preferences'), findsOneWidget);
      expect(find.text('General Configuration'), findsNothing);
      expect(find.text('Security & Access'), findsNothing);
      expect(find.text('Service Preferences'), findsNothing);
      expect(find.text('Default Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Maintenance Mode'), findsOneWidget);
      expect(find.text('Enforce two-factor authentication'), findsNothing);
      expect(find.text('Session timeout'), findsOneWidget);
      expect(find.text('Audit logging'), findsOneWidget);
      expect(find.text('Allow new account creation'), findsOneWidget);
      expect(find.text('Data Retention'), findsNothing);
      expect(find.text('Audit log retention'), findsNothing);
      expect(find.text('Backup schedule'), findsNothing);
      expect(find.text('Public status page'), findsOneWidget);

      // Default Language, Maintenance Mode, and Public status page all
      // flag as not-yet-real.
      expect(find.text('Coming Soon'), findsNWidgets(3));

      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Reset Changes'), findsNothing);
    },
  );

  testWidgets('Admin System Settings Maintenance Mode and Public status page '
      'switches are genuinely disabled, not just badged', (
    WidgetTester tester,
  ) async {
    _setConfirmedSystemSettingsFixture();
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

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    // Maintenance Mode (index 0) and Public status page (last) both have
    // no onChanged at all — a disabled-looking Switch that's still live
    // was the original bug.
    expect(switches.first.onChanged, isNull);
    expect(switches.last.onChanged, isNull);

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(find.text('Save Changes'), findsNothing);
  });

  testWidgets('Admin System Settings shows the Save bar once dirty and Reset '
      'Changes reverts it', (WidgetTester tester) async {
    _setConfirmedSystemSettingsFixture();
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

    // Index 1 is Audit logging — the first genuinely live switch
    // (Maintenance Mode at index 0 is deliberately disabled).
    await tester.tap(find.byType(Switch).at(1));
    await tester.pump();

    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Reset Changes'), findsOneWidget);

    await tester.tap(find.text('Reset Changes'));
    await tester.pump();

    expect(find.text('Save Changes'), findsNothing);
    expect(find.text('Reset Changes'), findsNothing);
  });

  testWidgets(
    'Admin System Settings Save Changes submits to the real backend and '
    'recovers from a failed request',
    (WidgetTester tester) async {
      // Save now calls the real civic_voice_api PATCH /api/admin/settings
      // (see AdminSystemSettingsDirectory.save) instead of a fake delay
      // that always succeeded — against the dead baseUrl every test runs
      // with (flutter_test_config.dart), that means a real failure here
      // is the correct, testable outcome: the "Update Failed" banner
      // appears and the draft survives so nothing is silently lost.
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _preserveAdminSystemSettingsDirectory();
      final directory = AdminSystemSettingsDirectory.instance;
      directory.settings.value = mockSystemSettings();
      directory.hasLiveSnapshot = true;
      directory.state.value = AdminSystemSettingsDirectoryState.loaded;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump();
      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // Saving asks for confirmation first — its own confirm button shares
      // the same label as the page's Save Changes button.
      expect(find.text('Save system settings?'), findsOneWidget);
      await tester.tap(find.text('Save Changes').last);
      await tester.pumpAndSettle();

      expect(find.text('Update Failed'), findsOneWidget);
      // The failed save doesn't clear the dirty state — the draft is
      // still unsaved, so Save/Reset stay available to retry.
      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.text('Reset Changes'), findsOneWidget);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[1].onChanged, isNotNull);
      expect(switches[2].onChanged, isNotNull);
    },
  );

  testWidgets(
    'Admin System Settings initialSaveState previews the Update Failed '
    'banner',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
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

  testWidgets(
    'Admin System Settings locks editable controls and actions while saving',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialSaveState: SystemSettingsSaveState.saving,
          ),
        ),
      );
      await tester.pump();

      final timeout = tester.widget<AppDropdownField<String>>(
        find.byType(AppDropdownField<String>),
      );
      expect(timeout.onChanged, isNull);
      for (final control in tester.widgetList<Switch>(find.byType(Switch))) {
        expect(control.onChanged, isNull);
      }
      final reset = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Reset Changes'),
      );
      final save = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(reset.onPressed, isNull);
      expect(save.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets(
    'Admin System Settings restores editable controls after a completed save state',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialSaveState: SystemSettingsSaveState.saved,
          ),
        ),
      );
      await tester.pump();

      final timeout = tester.widget<AppDropdownField<String>>(
        find.byType(AppDropdownField<String>),
      );
      expect(timeout.onChanged, isNotNull);
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].onChanged, isNull);
      expect(switches[1].onChanged, isNotNull);
      expect(switches[2].onChanged, isNotNull);
      expect(switches[3].onChanged, isNull);
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

    expect(find.text('Home'), findsOneWidget);
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
    'Admin System Settings does not invent retry success without Firebase',
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

      final retry = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Retry'),
      );
      expect(retry.onPressed, isNull);
      expect(find.text('Something went wrong'), findsOneWidget);
    },
  );

  // ---------------------------------------------------------------------
  // Admin Create User — "Allow new account creation" gate
  // ---------------------------------------------------------------------

  testWidgets(
    'Admin Create User form and submit button are frozen when account '
    'creation is turned off in System Settings',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      _preserveAdminSystemSettingsDirectory();
      AdminSystemSettingsDirectory.instance.settings.value =
          AdminSystemSettingsDirectory.instance.settings.value.copyWith(
            allowNewAccountCreation: false,
          );

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminCreateUserScreen()),
      );
      await tester.pump();

      expect(find.text('Account creation is paused'), findsOneWidget);

      final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create User'),
      );
      expect(createButton.onPressed, isNull);
    },
  );

  testWidgets(
    'Admin Create User form is fully interactive when account creation is '
    'allowed',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminCreateUserScreen()),
      );
      await tester.pump();

      expect(find.text('Account creation is paused'), findsNothing);

      final createButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Create User'),
      );
      expect(createButton.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Admin System Settings distinguishes unavailable, loading, confirmed, and stale snapshots',
    (WidgetTester tester) async {
      final directory = AdminSystemSettingsDirectory.instance;
      _preserveAdminSystemSettingsDirectory();
      directory.settings.value = const SystemSettingsData(
        maintenanceMode: false,
        sessionTimeout: '30 minutes',
        auditLogging: false,
        publicStatusPage: false,
        allowNewAccountCreation: false,
      );
      directory.hasLiveSnapshot = false;
      directory.loading.value = false;
      directory.error.value = null;
      directory.state.value = AdminSystemSettingsDirectoryState.unavailable;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(
            initialState: AdminSystemSettingsViewState.loading,
          ),
        ),
      );
      await tester.pump();
      expect(find.text('System settings unavailable'), findsOneWidget);

      directory.state.value = AdminSystemSettingsDirectoryState.loading;
      await tester.pump();
      expect(find.text('System settings unavailable'), findsNothing);
      expect(find.text('System Preferences'), findsNothing);

      directory.settings.value = mockSystemSettings();
      directory.hasLiveSnapshot = true;
      directory.loading.value = false;
      directory.error.value = null;
      directory.state.value = AdminSystemSettingsDirectoryState.loaded;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminSystemSettingsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('System Preferences'), findsOneWidget);

      directory.state.value = AdminSystemSettingsDirectoryState.failed;
      await tester.pump();
      expect(
        find.text(
          'The latest settings could not be refreshed. Showing the last confirmed server snapshot.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Admin Create User uses accessible underline identity fields and keeps '
    'Access controls available',
    (WidgetTester tester) async {
      _setConfirmedSystemSettingsFixture();
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminCreateUserScreen()),
      );
      await tester.pump();

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.byType(AppDropdownField<AppRole>), findsOneWidget);

      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(2));
      expect(fields.first.autofillHints, contains(AutofillHints.name));
      expect(fields.first.textInputAction, TextInputAction.next);
      expect(fields.last.autofillHints, contains(AutofillHints.telephoneNumber));
      expect(fields.last.textInputAction, TextInputAction.done);
      for (final field in fields) {
        expect(field.decoration?.filled, isFalse);
        expect(field.decoration?.enabledBorder, isA<UnderlineInputBorder>());
      }
    },
  );

  testWidgets(
    'Admin Create User keeps validation errors visible with underline fields',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());
      _setConfirmedSystemSettingsFixture();
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const AdminCreateUserScreen()),
      );
      await tester.pump();

      final createButton = find.widgetWithText(FilledButton, 'Create User');
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Create account?'), findsNothing);
    },
  );

  testWidgets(
    'Admin Create User keeps its create and discard confirmations',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());
      _setConfirmedSystemSettingsFixture();
      var returnedToUsers = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminCreateUserScreen(
            onNavigateToUsers: () => returnedToUsers = true,
          ),
        ),
      );
      await tester.pump();

      final role = find.byType(AppDropdownField<AppRole>);
      await tester.ensureVisible(role);
      await tester.tap(role);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ministry Supervisor').last);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'Akosua Mensah');
      await tester.enterText(fields.last, '+233 24 123 4567');
      await tester.pump();

      final createButton = find.widgetWithText(FilledButton, 'Create User');
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();
      expect(find.text('Create account?'), findsOneWidget);
      final createDialog = find.byType(AlertDialog);
      await tester.tap(
        find.descendant(of: createDialog, matching: find.text('Cancel')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('Discard this account?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pump();

      expect(returnedToUsers, isTrue);
    },
  );

  testWidgets(
    'Admin Create User discards a stale create response after session clear',
    (WidgetTester tester) async {
      final directory = AdminUserDirectory.instance;
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());
      _setConfirmedSystemSettingsFixture();
      final originalUsers = directory.users.value;
      final originalState = directory.state.value;
      final originalSnapshot = directory.hasLiveSnapshot;
      final originalLoading = directory.loading.value;
      final originalError = directory.error.value;
      final originalCurrentUserId = directory.currentApiUserId;
      final response = Completer<Map<String, dynamic>>();
      var callbackCalled = false;
      var navigated = false;
      addTearDown(() {
        directory.users.value = originalUsers;
        directory.state.value = originalState;
        directory.hasLiveSnapshot = originalSnapshot;
        directory.loading.value = originalLoading;
        directory.error.value = originalError;
        directory.currentApiUserId = originalCurrentUserId;
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminCreateUserScreen(
            idTokenProvider: () async => 'token',
            createUserRequest: ({
              required idToken,
              required fullName,
              required phone,
              required role,
              adminTier,
              region,
              assembly,
            }) => response.future,
            onUserCreated: (_) => callbackCalled = true,
            onNavigateToUsers: () => navigated = true,
          ),
        ),
      );
      await tester.pump();

      final role = find.byType(AppDropdownField<AppRole>);
      await tester.ensureVisible(role);
      await tester.tap(role);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ministry Supervisor').last);
      await tester.pumpAndSettle();

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, 'Akosua Mensah');
      await tester.enterText(fields.last, '+233 24 123 4567');
      final createButton = find.widgetWithText(FilledButton, 'Create User');
      await tester.drag(
        find.byType(Scrollable).first,
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();
      final dialog = find.byType(AlertDialog);
      await tester.tap(find.descendant(of: dialog, matching: find.text('Create')));
      await tester.pump();

      directory.invalidateAndClear();
      response.complete({
        'user': {
          'id': 'created-after-clear',
          'publicId': 'ADM-created-after-clear',
          'fullName': 'Akosua Mensah',
          'phone': '+233241234567',
          'role': 'ADMIN',
          'active': true,
          'createdAt': DateTime(2026).toIso8601String(),
          'updatedAt': DateTime(2026).toIso8601String(),
        },
      });
      await tester.pump();
      await tester.pump();

      expect(directory.users.value, isEmpty);
      expect(callbackCalled, isFalse);
      expect(navigated, isFalse);
      expect(find.textContaining('Account created'), findsNothing);
    },
  );

  testWidgets(
    'Admin Create User remains usable at 375px with 1.5x text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const AdminCreateUserScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
      expect(find.text('Email'), findsNothing);
      expect(find.text('admin@civicvoice.gov'), findsNothing);
      expect(find.text('Platform Administration'), findsOneWidget);
      expect(find.text('ADM-000001'), findsOneWidget);
      expect(find.text('System Preferences'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System (Default)'), findsNothing);
      expect(find.text('Light'), findsNothing);
      expect(find.text('Dark'), findsNothing);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsNothing);
      expect(find.text('Coming Soon'), findsOneWidget);
      // Administrator Information and System Preferences are the only
      // titled sections; About and Change Password have no headings.
      expect(find.text('Administrator Information'), findsOneWidget);
      expect(find.text('Security'), findsNothing);
      expect(find.text('About'), findsNothing);
      expect(find.text('About CivicVoice'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Two-factor authentication'), findsNothing);
      expect(find.byTooltip('About Administrative Scope'), findsOneWidget);
      expect(find.text('Roles'), findsNothing);
      expect(find.text('Governance Level'), findsOneWidget);
      expect(find.text('Approved administrator'), findsOneWidget);
      expect(find.text('Session'), findsNothing);
      expect(find.text('Last activity'), findsNothing);
      expect(find.text('Log out'), findsOneWidget);

      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save Changes'), findsNothing);
      expect(find.text('Cancel'), findsNothing);

      await tester.tap(find.byTooltip('About Administrative Scope'));
      await tester.pumpAndSettle();

      expect(find.byType(GlassDialogBackdrop), findsOneWidget);
      expect(find.text('Administrative Scope'), findsOneWidget);
      expect(find.text('Users'), findsWidgets);
      expect(find.text('Roles'), findsOneWidget);
      expect(find.text('Settings'), findsWidgets);
    },
  );

  testWidgets('Admin Profile Change Password fires onChangePassword', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminProfileScreen(onChangePassword: () => tapped = true),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Change Password'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('Admin Profile Theme row switches ThemeController.mode from '
      'its System/Light/Dark menu', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() => ThemeController.mode.value = ThemeMode.light);
    // Explicit starting point rather than relying on ThemeController's own
    // default (light, not system, as of this app's onboarding UX) — this
    // test is about the System/Light/Dark control actually switching
    // modes, not about what the unrelated default happens to be.
    ThemeController.mode.value = ThemeMode.system;

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const AdminProfileScreen()),
    );
    await tester.pump();

    expect(ThemeController.mode.value, ThemeMode.system);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.dark);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.light);
  });

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

      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();

      // Only Full Name is self-editable. CivicVoice does not collect email,
      // while phone, jurisdiction/department, and Admin ID stay locked and
      // never appear in the modal editor (which also blocks the nav).
      final sheet = find.byType(BottomSheet);
      expect(sheet, findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.byType(TextField)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: sheet, matching: find.text('ADM-000001')),
        findsNothing,
      );
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'System Administrator'),
        'Updated Administrator',
      );
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Cancel with unsaved changes confirms before discarding.
      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save changes'), findsNothing);
      expect(find.text('Platform Administration'), findsOneWidget);
      expect(find.text('Updated Administrator'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
    },
  );

  testWidgets('Admin Profile Log Out asks for confirmation before firing the '
      'callback', (WidgetTester tester) async {
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

    await tester.tap(find.text('Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Log out?'), findsOneWidget);
    expect(signedOut, isFalse);

    // Dismissing via Cancel doesn't sign out.
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(signedOut, isFalse);
    expect(find.text('Log out?'), findsNothing);

    // Confirming via the dialog's destructive button does sign out.
    await tester.tap(find.text('Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(signedOut, isTrue);
  });

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

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'System Administrator'),
        'Civic Administrator',
      );
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      // The save completes after a simulated delay — a single pump only
      // advances one frame, not the full delay.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated'), findsOneWidget);
      // The saved record shows the new name; administrator-controlled
      // fields are untouched.
      expect(find.text('Civic Administrator'), findsNWidgets(2));
      expect(find.text('ADM-000001'), findsOneWidget);
      expect(find.text('Platform Administration'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Save changes'), findsNothing);
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

      await tester.tap(find.byTooltip('Edit profile'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'System Administrator'),
        '',
      );
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await tester.pump();

      expect(find.text('Full name is required.'), findsOneWidget);
      // Still editing — the failed save doesn't close the editor.
      expect(find.text('Save changes'), findsOneWidget);
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
    'Super Admin Profile remains a tab-shell screen and switches tabs',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

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

      expect(find.text('Home'), findsOneWidget);
      // Administrative scope details stay behind the info action, so these
      // are now the unambiguous bottom-nav destinations.
      expect(find.text('Users'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Users'));
      await tester.pump();
      expect(usersTapped, isTrue);
    },
  );

  testWidgets(
    'assembly Admin Profile has a top back button and no bottom navigation',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      );
      addTearDown(() => MockAuthService().clearUser());

      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminProfileScreen(onBack: () => backTapped = true),
        ),
      );
      await tester.pump();

      expect(find.byIcon(AppIcons.back), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Users'), findsNothing);
      expect(find.text('Activity'), findsNothing);
      expect(find.text('Teams'), findsNothing);

      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pump();
      expect(backTapped, isTrue);
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
        home: AdminProfileScreen(
          initialState: AdminProfileViewState.error,
          initialData: mockAdminProfile(),
          onRetry: () async {},
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('Something went wrong'), findsNothing);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('System Preferences'), findsOneWidget);
  });

  testWidgets(
    'Admin Create Team: first member ticked becomes lead by default, and '
    'the crown button reassigns it',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.admin,
        region: Region.ashanti,
        assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      );
      addTearDown(() => MockAuthService().clearUser());

      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // "Kumasi Central Crew" already has both of Kumasi's maintenance
      // workers as members (Yaw Asare leading) — editing it, rather than
      // creating a new team, since both are otherwise "assigned elsewhere"
      // and wouldn't appear as eligible for a brand-new team.
      final team = _seedAdminMaintenanceTeamFixture();
      expect(team.name, 'Kumasi Central Crew');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminMaintenanceTeamFormScreen(team: team),
        ),
      );
      await tester.pump();

      expect(find.text('Yaw Asare'), findsOneWidget);
      expect(find.text('Kojo Mensah-Boateng'), findsOneWidget);
      // Both start selected with Yaw already the lead.
      expect(find.byTooltip('Team lead'), findsOneWidget);
      expect(find.byTooltip('Make team lead'), findsOneWidget);

      // Untick both, back to a clean slate.
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Kojo Mensah-Boateng'),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Yaw Asare'));
      await tester.pump();
      expect(find.byTooltip('Team lead'), findsNothing);
      expect(find.byTooltip('Make team lead'), findsNothing);

      // Kojo ticked first now defaults to lead.
      await tester.tap(
        find.widgetWithText(CheckboxListTile, 'Kojo Mensah-Boateng'),
      );
      await tester.pump();
      expect(find.byTooltip('Team lead'), findsOneWidget);
      expect(find.byTooltip('Make team lead'), findsNothing);

      // Yaw ticked second doesn't steal the lead automatically.
      await tester.tap(find.widgetWithText(CheckboxListTile, 'Yaw Asare'));
      await tester.pump();
      expect(find.byTooltip('Team lead'), findsOneWidget);
      expect(find.byTooltip('Make team lead'), findsOneWidget);

      // Explicit reassignment via the crown moves the lead to Yaw — still
      // exactly one lead, never zero or two.
      await tester.tap(find.byTooltip('Make team lead'));
      await tester.pump();
      expect(find.byTooltip('Team lead'), findsOneWidget);
      expect(find.byTooltip('Make team lead'), findsOneWidget);
      final leadIcon = tester.widget<Icon>(
        find.descendant(
          of: find.byTooltip('Team lead'),
          matching: find.byIcon(AppIcons.teamLead),
        ),
      );
      expect(leadIcon.color, AppColors.warning);
    },
  );

  testWidgets(
    'Admin Maintenance Teams keeps full-width jurisdiction filters in its '
    'scrollable list',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      final originalTeams = MaintenanceTeamDirectory.instance.teams.value;
      final originalState = MaintenanceTeamDirectory.instance.state.value;
      addTearDown(() {
        MaintenanceTeamDirectory.instance.teams.value = originalTeams;
        MaintenanceTeamDirectory.instance.state.value = originalState;
      });
      final assembly = assemblyNamed(Region.ashanti, 'Kumasi');
      MaintenanceTeamDirectory.instance.teams.value = List.generate(
        12,
        (index) => MaintenanceTeam(
          teamId: 'TEST-TEAM-$index',
          name: 'Scrollable maintenance team $index',
          region: Region.ashanti,
          assembly: assembly,
          memberUserIds: const [],
          createdAt: DateTime(2026, 1, index + 1),
        ),
      );
      MaintenanceTeamDirectory.instance.state.value =
          MaintenanceTeamDirectoryState.loaded;

      tester.view.physicalSize = const Size(375, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminMaintenanceTeamsScreen(),
        ),
      );
      await tester.pump();

      final regionField = find.byType(AppDropdownField<Region>);
      final assemblyField = find.byType(AppDropdownField<Assembly>);
      expect(regionField, findsOneWidget);
      expect(assemblyField, findsOneWidget);
      expect(
        tester.widget<AppDropdownField<Region>>(regionField).hint,
        'Select region',
      );
      expect(
        tester.widget<AppDropdownField<Assembly>>(assemblyField).hint,
        'Select Region first',
      );
      expect(tester.getRect(regionField).width, closeTo(343, 0.1));
      expect(tester.getRect(assemblyField).width, closeTo(343, 0.1));

      final list = find.ancestor(
        of: regionField,
        matching: find.byType(ListView),
      );
      final scrollable = find.byType(Scrollable).last;
      expect(list, findsOneWidget);
      expect(scrollable, findsOneWidget);
      final initialRegionTop = tester.getTopLeft(regionField).dy;
      await tester.drag(list, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(
        tester.state<ScrollableState>(scrollable).position.pixels,
        greaterThan(0),
      );
      expect(tester.getTopLeft(regionField).dy, lessThan(initialRegionTop));
    },
  );

  testWidgets(
    'Admin Maintenance Teams does not present an unfetched directory as '
    'mock team data',
    (WidgetTester tester) async {
      final directory = MaintenanceTeamDirectory.instance;
      final originalTeams = directory.teams.value;
      final originalState = directory.state.value;
      addTearDown(() {
        directory.teams.value = originalTeams;
        directory.state.value = originalState;
      });
      directory.teams.value = const [];
      directory.state.value = MaintenanceTeamDirectoryState.unavailable;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminMaintenanceTeamsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Team data unavailable'), findsOneWidget);
      expect(find.text('Kumasi Central Crew'), findsNothing);
    },
  );

  testWidgets(
    'Admin Maintenance Teams distinguishes confirmed empty data from '
    'unavailable data',
    (WidgetTester tester) async {
      final directory = MaintenanceTeamDirectory.instance;
      final originalTeams = directory.teams.value;
      final originalState = directory.state.value;
      addTearDown(() {
        directory.teams.value = originalTeams;
        directory.state.value = originalState;
      });
      directory.teams.value = const [];
      directory.state.value = MaintenanceTeamDirectoryState.loaded;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const AdminMaintenanceTeamsScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('No maintenance teams in the system yet.'), findsOneWidget);
      expect(find.text('Team data unavailable'), findsNothing);
    },
  );

  testWidgets('Admin Maintenance Teams retry reports unavailable without a '
      'successful fetch', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const AdminMaintenanceTeamsScreen(
          initialState: AdminMaintenanceTeamsViewState.error,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Team data unavailable'), findsOneWidget);
    expect(find.byType(AdminMaintenanceTeamsScreen), findsOneWidget);
  });

  test('Maintenance Team server mutations do not use local success fallback', () async {
    final team = _seedAdminMaintenanceTeamFixture();
    final directory = MaintenanceTeamDirectory.instance;
    final updated = team.copyWith(name: 'Renamed only in a draft');

    await expectLater(
      directory.createTeamOnServer(
        name: 'Unconfirmed team',
        assembly: team.assembly,
      ),
      throwsA(isA<StateError>()),
    );
    await expectLater(directory.updateTeamOnServer(updated), throwsA(isA<StateError>()));
    await expectLater(directory.deleteTeamOnServer(team), throwsA(isA<StateError>()));

    expect(directory.teams.value, [team]);
  });

  testWidgets(
    'Admin Team form clears assembly members and lead when its region changes',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      final team = _seedAdminMaintenanceTeamFixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminMaintenanceTeamFormScreen(team: team),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Team lead'), findsOneWidget);
      await tester.tap(find.byType(AppDropdownField<Region>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(Region.greaterAccra.label));
      await tester.pumpAndSettle();

      final assemblyField = tester.widget<AppDropdownField<Assembly>>(
        find.byType(AppDropdownField<Assembly>),
      );
      expect(assemblyField.hint, 'Select assembly');
      expect(find.byTooltip('Team lead'), findsNothing);
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
      }
    },
  );

  testWidgets(
    'Admin Team form clears members and lead when its assembly changes',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      final team = _seedAdminMaintenanceTeamFixture();
      final alternativeAssembly = ghanaAssemblies[team.region]!.firstWhere(
        (assembly) => assembly.name != team.assembly.name,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminMaintenanceTeamFormScreen(team: team),
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Team lead'), findsOneWidget);
      await tester.tap(find.byType(AppDropdownField<Assembly>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(alternativeAssembly.fullName).last);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Team lead'), findsNothing);
      for (final checkbox in tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      )) {
        expect(checkbox.value, isFalse);
      }
    },
  );

  testWidgets('Admin Team create form lets a clean system Back close normally', (
    WidgetTester tester,
  ) async {
    await _openMaintenanceTeamFormRoute(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open team form'), findsOneWidget);
    expect(find.text('Discard team changes?'), findsNothing);
  });

  testWidgets(
    'Admin Team create form keeps a dirty draft on system Back until discard',
    (WidgetTester tester) async {
      await _openMaintenanceTeamFormRoute(tester);
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Unsaved Central Team');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard team changes?'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();
      expect(find.text('Open team form'), findsNothing);
      expect(
        tester.widget<TextField>(nameField).controller!.text,
        'Unsaved Central Team',
      );

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open team form'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Team edit form header Back uses the same guarded discard flow',
    (WidgetTester tester) async {
      final team = _seedAdminMaintenanceTeamFixture();
      await _openMaintenanceTeamFormRoute(tester, team: team);
      await tester.enterText(find.byType(TextField).first, 'Renamed Crew');

      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      expect(find.text('Discard team changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Open team form'), findsOneWidget);
    },
  );

  testWidgets('Admin Team form asks before discarding a lead-only change', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await MockAuthService().initialize();
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.admin,
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    );
    addTearDown(() => MockAuthService().clearUser());

    final team = _seedAdminMaintenanceTeamFixture();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamFormScreen(team: team),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Make team lead'));
    await tester.pump();
    final cancel = find.text('Cancel');
    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();

    expect(find.text('Discard team changes?'), findsOneWidget);
  });

  testWidgets(
    'Admin Team Details uses the header Back and keeps Maintenance Teams active',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      await MockAuthService().initialize();
      await MockAuthService().selectRole(
        AppRole.systemAdministrator,
        adminTier: AdminTier.superAdmin,
      );
      addTearDown(() => MockAuthService().clearUser());

      final team = _seedAdminMaintenanceTeamFixture();
      var closeCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminMaintenanceTeamDetailsScreen(
            team: team,
            onBackToTeams: () => closeCalls += 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Go back'), findsOneWidget);
      expect(find.byTooltip('Back to maintenance teams'), findsNothing);
      expect(find.byIcon(AppIcons.back), findsOneWidget);

      await tester.tap(find.byIcon(AppIcons.menu));
      await tester.pumpAndSettle();
      final teamsTile = find.ancestor(
        of: find.descendant(
          of: find.byType(Drawer),
          matching: find.text('Maintenance Teams'),
        ),
        matching: find.byType(ListTile),
      );
      expect(tester.widget<ListTile>(teamsTile).selected, isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Go back'));
      await tester.pumpAndSettle();
      expect(closeCalls, 1);
    },
  );

  testWidgets('Admin Team Details missing-team view provides header Back', (
    WidgetTester tester,
  ) async {
    final directory = MaintenanceTeamDirectory.instance;
    final originalTeams = directory.teams.value;
    final originalState = directory.state.value;
    addTearDown(() {
      directory.teams.value = originalTeams;
      directory.state.value = originalState;
    });
    directory.teams.value = const [];
    directory.state.value = MaintenanceTeamDirectoryState.loaded;

    var closeCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(
          team: _adminMaintenanceTeamFixture(),
          onBackToTeams: () => closeCalls += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Team not found'), findsOneWidget);
    expect(find.byTooltip('Go back'), findsOneWidget);
    expect(find.text('Back to Teams'), findsNothing);
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();
    expect(closeCalls, 1);
  });

  testWidgets('Admin Team Details preserves native system Back navigation', (
    WidgetTester tester,
  ) async {
    final team = _seedAdminMaintenanceTeamFixture();
    await _openMaintenanceTeamDetailsRoute(tester, team: team);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Open team details'), findsOneWidget);
    expect(find.byType(AdminMaintenanceTeamDetailsScreen), findsNothing);
  });

  testWidgets('Admin Team Details shows the empty-team message only for no member IDs', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture().copyWith(
      memberUserIds: const [],
      leadUserId: null,
    );
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: const [],
      state: AdminUserDirectoryState.unavailable,
      loading: false,
      hasLiveSnapshot: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();

    expect(
      find.text('No maintenance staff have been added to this team yet.'),
      findsOneWidget,
    );
    expect(find.text('Member details are unavailable. This team has assigned members, but their details cannot be shown yet.'), findsNothing);
  });

  testWidgets('Admin Team Details identifies unavailable member data', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture();
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: const [],
      state: AdminUserDirectoryState.unavailable,
      loading: false,
      hasLiveSnapshot: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Member details are unavailable. This team has assigned members, '
        'but their details cannot be shown yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('No maintenance staff have been added to this team yet.'), findsNothing);
  });

  testWidgets('Admin Team Details identifies loading member data', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture();
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: const [],
      state: AdminUserDirectoryState.loading,
      loading: true,
      hasLiveSnapshot: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();

    expect(find.text('Loading member details for this team.'), findsOneWidget);
  });

  testWidgets('Admin Team Details rebuilds when confirmed member data arrives', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture();
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: const [],
      state: AdminUserDirectoryState.loading,
      loading: true,
      hasLiveSnapshot: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();
    expect(find.text('Loading member details for this team.'), findsOneWidget);

    _setAdminUserDirectoryState(
      users: _maintenanceMemberFixtures(),
      state: AdminUserDirectoryState.loaded,
      loading: false,
      hasLiveSnapshot: true,
    );
    await tester.pump();

    expect(find.text('Yaw Asare'), findsOneWidget);
    expect(find.text('Kojo Mensah-Boateng'), findsOneWidget);
    expect(find.text('Loading member details for this team.'), findsNothing);
  });

  testWidgets('Admin Team Details identifies partially unresolved members', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture();
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: [_maintenanceMemberFixtures().first],
      state: AdminUserDirectoryState.loaded,
      loading: false,
      hasLiveSnapshot: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();

    expect(find.text('Yaw Asare'), findsOneWidget);
    expect(find.text('Kojo Mensah-Boateng'), findsNothing);
    expect(
      find.text('Some member details are unavailable. 1 assigned member could not be resolved.'),
      findsOneWidget,
    );
  });

  testWidgets('Admin Team Details marks failed-refresh member data as stale', (
    WidgetTester tester,
  ) async {
    _preserveAdminUserDirectory();
    final team = _adminMaintenanceTeamFixture();
    _seedMaintenanceTeamDirectoryFixture(team);
    _setAdminUserDirectoryState(
      users: _maintenanceMemberFixtures(),
      state: AdminUserDirectoryState.failed,
      loading: false,
      hasLiveSnapshot: true,
      error: 'Refresh failed',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AdminMaintenanceTeamDetailsScreen(team: team),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Member details may be out of date. Showing previously loaded '
        'information.',
      ),
      findsOneWidget,
    );
    expect(find.text('Yaw Asare'), findsOneWidget);
    expect(find.text('Kojo Mensah-Boateng'), findsOneWidget);
  });

  testWidgets("Admin's bell opens the honest unavailable notifications page", (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const app.CivicVoiceApp(initialRoute: app.AppRoutes.adminDashboard),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(AppIcons.notifications));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Admin Notifications'), findsOneWidget);
    expect(find.text('Admin notifications unavailable'), findsOneWidget);
    expect(
      find.text(
        'Notifications will appear here when the secure Admin notification '
        'service is available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Recent Activity'), findsNothing);
    expect(find.text('Ama Boateng'), findsNothing);
    expect(find.text('Account deactivated'), findsNothing);
    expect(find.text('New account created'), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    expect(find.byType(Dismissible), findsNothing);
  });

  testWidgets(
    "Admin System Activity's bell also opens notifications (was wired to "
    'nothing)',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const app.CivicVoiceApp(
          initialRoute: app.AppRoutes.adminSystemActivity,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byIcon(AppIcons.notifications));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Admin Notifications'), findsOneWidget);
      expect(find.text('Admin notifications unavailable'), findsOneWidget);
    },
  );

  testWidgets(
    'Admin Notifications has no inferred user navigation or local inbox actions',
    (WidgetTester tester) async {
      var openedUserId = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: AdminNotificationsScreen(
            onOpenUser: (_) => openedUserId++,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Admin notifications unavailable'), findsOneWidget);
      expect(find.byType(Dismissible), findsNothing);
      expect(find.text('Clear all'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.byType(RefreshIndicator), findsNothing);
      expect(openedUserId, 0);
    },
  );

  testWidgets(
    'Admin Notifications preserves native Back and stays usable on narrow large text',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MediaQuery(
                    data: MediaQueryData(
                      textScaler: TextScaler.linear(1.5),
                    ),
                    child: AdminNotificationsScreen(
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ),
              child: const Text('Open notifications'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Admin notifications unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open notifications'), findsOneWidget);
    },
  );
}
