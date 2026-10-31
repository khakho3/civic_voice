import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final dashboard in [false, true]) {
    for (final empty in [false, true]) {
      testWidgets('pull refresh dashboard=$dashboard empty=$empty', (
        tester,
      ) async {
        final directory = MaintenanceTaskDirectory.instance;
        final previous = directory.tasks.value;
        addTearDown(() => directory.tasks.value = previous);
        directory.tasks.value = empty ? [] : [mockMaintenanceTasks().first];
        var calls = 0;
        Future<void> refresh() async {
          calls++;
          directory.tasks.value = [mockMaintenanceTasks().first];
        }

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: dashboard
                ? DashboardScreen(refreshTasks: refresh)
                : AssignedTasksScreen(refreshTasks: refresh),
          ),
        );
        await tester.pumpAndSettle();
        await tester.dragFrom(const Offset(150, 300), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.text('Broken Street Light at Main Ave'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
