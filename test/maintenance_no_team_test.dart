import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/screens/task_details_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_session.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/main.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void membership(String? team) =>
    MaintenanceSession.instance.setAuthenticatedUser(
      publicId: 'MNT-FIXTURE',
      fullName: 'Fixture Technician',
      phone: '',
      region: 'greaterAccra',
      assembly: 'Ga Central',
      teamId: team,
    );

void main() {
  final directory = MaintenanceTaskDirectory.instance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().clearUser();
    directory.clearSession();
    membership(null);
  });
  tearDown(() {
    directory.clearSession();
    MaintenanceSession.instance.clearSession();
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 375.0, 428.0]) {
      testWidgets('no-team Home and Tasks: dark=$dark width=$width at 2x text', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 950);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Widget host(Widget child) => MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: child,
        );
        // Even an old cached row must not become assigned work without a team.
        directory.tasks.value = [mockMaintenanceTasks().first];
        await tester.pumpWidget(host(const DashboardScreen()));
        await tester.pumpAndSettle();
        expect(find.text('No team assigned'), findsOneWidget);
        expect(find.text('Broken Street Light at Main Ave'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Weekly Completion'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Weekly Completion'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(host(const AssignedTasksScreen()));
        await tester.pumpAndSettle();
        expect(find.text('No team assigned'), findsOneWidget);
        expect(find.text('Unable to load tasks'), findsNothing);
        expect(find.text('No assigned tasks'), findsNothing);
        await tester.ensureVisible(find.text('Retry'));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Tasks Retry picks up a verified assignment', (tester) async {
    var reads = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AssignedTasksScreen(
          refreshTasks: () async {
            reads++;
            membership('TEAM-A');
            directory.tasks.value = [mockMaintenanceTasks().first];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No team assigned'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(reads, 1);
    expect(find.text('No team assigned'), findsNothing);
    expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);
  });

  testWidgets('a genuine failure remains recoverable without a team', (
    tester,
  ) async {
    directory.error.value = 'Fixture network failure';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AssignedTasksScreen(
          refreshTasks: () async {
            directory.error.value = null;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load tasks'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No team assigned'), findsOneWidget);
  });

  testWidgets('mounted task detail drops former-team data on removal', (
    tester,
  ) async {
    membership('TEAM-A');
    final task = mockMaintenanceTasks().first;
    directory.tasks.value = [task];
    await tester.pumpWidget(
      CivicVoiceApp(
        initialRoute: '${AppRoutes.maintenanceTaskDetails}?taskId=${task.id}',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsScreen), findsOneWidget);
    membership(null);
    directory.tasks.value = [];
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsScreen), findsNothing);
    expect(find.text('No team assigned'), findsOneWidget);
    expect(find.text(task.title), findsNothing);
  });

  testWidgets('an unknown task link never opens the first cached task', (
    tester,
  ) async {
    membership('TEAM-A');
    directory.tasks.value = mockMaintenanceTasks();
    await tester.pumpWidget(
      const CivicVoiceApp(
        initialRoute: '${AppRoutes.maintenanceTaskDetails}?taskId=missing',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TaskDetailsScreen), findsNothing);
    expect(find.text('Task not found'), findsOneWidget);
  });

  for (final route in [
    AppRoutes.maintenanceTaskDetails,
    AppRoutes.maintenanceUpdateProgress,
    AppRoutes.maintenanceTaskCompleted,
  ]) {
    testWidgets('no-team deep link $route has recovery and Back to Tasks', (
      tester,
    ) async {
      await tester.pumpWidget(
        CivicVoiceApp(initialRoute: '$route?taskId=former-team-task'),
      );
      await tester.pumpAndSettle();
      expect(find.text('No team assigned'), findsOneWidget);
      await tester.tap(find.byIcon(AppIcons.back));
      await tester.pumpAndSettle();
      expect(find.byType(AssignedTasksScreen), findsOneWidget);
      expect(find.text('No team assigned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
