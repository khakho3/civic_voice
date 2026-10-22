import 'dart:async';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/core/widgets/ghana_refresh_indicator.dart';
import 'package:civic_voice/features/maintenance/screens/assigned_tasks_screen.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/widgets/app_state_message.dart';
import 'package:civic_voice/widgets/async_action_button.dart';
import 'package:civic_voice/widgets/busy_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets(
    'state action keeps content, deduplicates, and releases feedback',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        host(
          AppStateMessage(
            icon: Icons.info,
            title: 'No reports yet',
            message: 'Try refreshing.',
            primaryActionLabel: 'Refresh',
            onPrimaryAction: () {
              calls++;
              return pending.future;
            },
          ),
        ),
      );
      final before = tester.getSize(find.byType(FilledButton));
      await tester.tap(find.text('Refresh'));
      await tester.pump();
      expect(find.text('No reports yet'), findsOneWidget);
      expect(find.byType(GhanaLoadingIndicator), findsNothing);
      expect(find.byType(BusyIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)), before);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(calls, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(BusyIndicator), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('failed action is clear and can be retried; disposal is safe', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      host(
        AsyncActionButton(
          label: 'Retry',
          onPressed: () {
            calls++;
            if (calls == 1) return Future<void>.error(StateError('offline'));
            return pending.future;
          },
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not complete this action. Please try again.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final dashboard in [false, true]) {
    testWidgets(
      'maintenance retry stays in place through directory loading: dashboard=$dashboard',
      (tester) async {
        final directory = MaintenanceTaskDirectory.instance;
        final oldTasks = directory.tasks.value;
        final oldError = directory.error.value;
        final oldLoading = directory.loading.value;
        addTearDown(() {
          directory.tasks.value = oldTasks;
          directory.error.value = oldError;
          directory.loading.value = oldLoading;
        });
        directory.tasks.value = [];
        directory.error.value = 'offline';
        directory.loading.value = false;
        final pending = Completer<void>();
        var calls = 0;
        Future<void> refresh() async {
          calls++;
          directory.loading.value = true;
          directory.error.value = null;
          try {
            await pending.future;
          } finally {
            directory.loading.value = false;
          }
        }

        await tester.pumpWidget(
          host(
            dashboard
                ? DashboardScreen(refreshTasks: refresh)
                : AssignedTasksScreen(refreshTasks: refresh),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(dashboard ? 'Unable to load dashboard' : 'Unable to load tasks'), findsOneWidget);
        await tester.tap(find.text('Retry'));
        await tester.pump();
        expect(find.text(dashboard ? 'Unable to load dashboard' : 'Unable to load tasks'), findsOneWidget);
        expect(find.byType(GhanaLoadingIndicator), findsNothing);
        expect(find.byType(BusyIndicator), findsOneWidget);
        expect(calls, 1);
        pending.complete();
        await tester.pumpAndSettle();
        expect(find.byType(BusyIndicator), findsNothing);
        directory.loading.value = true;
        await tester.pump();
        expect(find.byType(GhanaLoadingIndicator), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
