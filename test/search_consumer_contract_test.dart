import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_maintenance_team_data.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/models/admin_system_activity_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_maintenance_teams_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_system_activity_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_user_management_screen.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/features/admin/services/admin_user_directory.dart';
import 'package:civic_voice/features/citizen/models/civic_report.dart';
import 'package:civic_voice/features/citizen/screens/citizen_reports_screen.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/features/ministry/models/ministry_reports_data.dart';
import 'package:civic_voice/features/ministry/screens/ministry_reports_screen.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/screens/municipal_active_reports_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_assign_team_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_inbox_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'package:civic_voice/features/municipal/services/municipal_report_directory.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/ghana_assemblies_data.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:civic_voice/widgets/focused_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'consumer-contract');
    await MockAuthService().initialize();
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.superAdmin,
    );
    addTearDown(() => MockAuthService().clearUser());
    final municipal = MunicipalReportDirectory.instance;
    final oldMunicipal = municipal.reports.value;
    final oldMunicipalLive = municipal.hasLiveSnapshot;
    addTearDown(() {
      municipal.reports.value = oldMunicipal;
      municipal.hasLiveSnapshot = oldMunicipalLive;
    });
    municipal.hasLiveSnapshot = true;
    municipal.reports.value = [
      for (var i = 0; i < 60; i++)
        IncomingReportItem(
          referenceId: 'CONTRACT-$i',
          title: 'Record $i',
          description: 'Contract test report',
          locationLabel: 'Test street',
          category: ReportCategory.sanitation,
          status: [
            ReportStatus.underReview,
            ReportStatus.assigned,
            ReportStatus.resolved,
          ][i % 3],
          timeAgo: 'Today',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
    ];
    final citizen = ReportCrudService.instance;
    final oldCitizen = citizen.reports.value;
    addTearDown(() => citizen.reports.value = oldCitizen);
    citizen.reports.value = [
      for (var i = 0; i < 30; i++)
        CivicReport(
          id: 'citizen-$i',
          title: 'Record $i',
          category: 'Sanitation',
          description: 'Contract test report',
          location: 'Test street',
          timeLabel: 'Today',
          status: ReportStatus.submitted,
        ),
    ];
    final users = AdminUserDirectory.instance;
    final oldUsers = users.users.value;
    final oldUserState = users.state.value;
    final oldUserLive = users.hasLiveSnapshot;
    addTearDown(() {
      users.users.value = oldUsers;
      users.state.value = oldUserState;
      users.hasLiveSnapshot = oldUserLive;
    });
    users.hasLiveSnapshot = true;
    users.state.value = AdminUserDirectoryState.loaded;
    users.users.value = [
      for (var i = 0; i < 30; i++)
        AdminUserItem(
          name: 'Record $i',
          phone: '+233200000000',
          role: AppRole.citizen,
          status: AdminUserStatus.active,
          userId: 'USER-$i',
          lastSignIn: DateTime.now(),
          accountCreated: DateTime(2026),
        ),
    ];
    final teams = MaintenanceTeamDirectory.instance;
    final oldTeams = teams.teams.value;
    final oldTeamState = teams.state.value;
    addTearDown(() {
      teams.teams.value = oldTeams;
      teams.state.value = oldTeamState;
    });
    teams.state.value = MaintenanceTeamDirectoryState.loaded;
    teams.teams.value = [
      for (var i = 0; i < 30; i++)
        MaintenanceTeam(
          teamId: 'TEAM-$i',
          name: 'Record $i',
          region: Region.ashanti,
          assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
          memberUserIds: const [],
          createdAt: DateTime(2026),
        ),
    ];
    final tasks = MaintenanceTaskDirectory.instance;
    final oldTasks = tasks.tasks.value;
    addTearDown(() => tasks.tasks.value = oldTasks);
    tasks.tasks.value = [
      for (var i = 0; i < 30; i++)
        MaintenanceTask(
          id: 'TASK-$i',
          title: 'Record $i',
          description: 'Contract task',
          category: 'Sanitation',
          locationLabel: 'Test street',
          latitude: 5.5,
          longitude: -0.2,
          status: MaintenanceTaskStatus.assigned,
          eta: '1 hour',
          distanceLabel: 'Nearby',
          teamNote: 'Test',
          teamId: 'TEAM-0',
        ),
    ];
    final activity = AdminSystemActivityDirectory.instance;
    final oldActivity = activity.items.value;
    final oldActivityState = activity.state.value;
    final oldActivityLive = activity.hasLiveSnapshot;
    addTearDown(() {
      activity.items.value = oldActivity;
      activity.state.value = oldActivityState;
      activity.hasLiveSnapshot = oldActivityLive;
    });
    activity.hasLiveSnapshot = true;
    activity.state.value = AdminSystemActivityDirectoryState.loaded;
    activity.items.value = [
      for (var i = 0; i < 30; i++)
        ActivityItem(
          id: 'ACT-$i',
          title: 'Record $i',
          description: 'Contract activity',
          timestamp: DateTime.now(),
          severity: ActivitySeverity.info,
          category: ActivityCategory.userModification,
          tag: 'Administration',
        ),
    ];
  });

  final screens = <String, Widget Function()>{
    'Citizen reports': () => const CitizenReportsScreen(),
    'Maintenance tasks': () => const AssignedTasksScreen(),
    'Municipal inbox': () => const MunicipalInboxScreen(),
    'Municipal active': () => const MunicipalActiveReportsScreen(),
    'Municipal closed': () => const MunicipalResolvedReportsScreen(),
    'Municipal assign team': () => const MunicipalAssignTeamScreen(),
    'Admin users': () => const AdminUserManagementScreen(),
    'Admin teams': () => const AdminMaintenanceTeamsScreen(),
    'Admin activity': () => const AdminSystemActivityScreen(),
    'Ministry reports': () => MinistryReportsScreen(
      data: MinistryReportsData(
        stats: const MinistryReportsStats(
          aggregatedReports: 30,
          underReview: 30,
          resolved: 0,
        ),
        reports: [
          for (var i = 0; i < 30; i++)
            const ReportSummaryItem(
              title: 'Record',
              municipality: 'Test municipality',
              region: Region.ashanti,
              category: 'Sanitation',
              status: ReportStatus.underReview,
              dateLabel: 'Today',
            ),
        ],
      ),
    ),
  };
  for (final entry in screens.entries) {
    for (final width in [320.0, 390.0, 412.0, 1440.0]) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key}: search contract $width dark=$dark', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: entry.value(),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(SearchTriggerField), findsOneWidget);
          final vertical = tester
              .stateList<ScrollableState>(find.byType(Scrollable))
              .where(
                (state) =>
                    axisDirectionToAxis(state.position.axisDirection) ==
                    Axis.vertical,
              )
              .last;
          final list = find.byWidget(vertical.widget);
          await tester.drag(list, const Offset(0, -520));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
          final offset = vertical.position.pixels;
          await tester.tap(find.byType(SearchTriggerField));
          await tester.pumpAndSettle();
          expect(find.byType(FocusedSearchPanel), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'Record');
          await tester.pumpAndSettle();
          expect(
            find.descendant(
              of: find.byType(FocusedSearchPanel),
              matching: find.byType(ListTile),
            ),
            findsWidgets,
          );
          await tester.tap(find.byTooltip('Close search'));
          await tester.pumpAndSettle();
          expect(vertical.position.pixels, offset);
          expect(find.byKey(const ValueKey('collapsed_rail')), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          await tester.pumpWidget(const SizedBox.shrink());
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
