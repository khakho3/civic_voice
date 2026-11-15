import 'dart:async';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_session.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/features/maintenance/widgets/maintenance_task_access.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SyncedUser member(String? team) => SyncedUser.fromJson({
  'id': 'fixture',
  'publicId': 'MNT-FIXTURE',
  'firebaseUid': 'fixture-owner',
  'fullName': 'Fixture Technician',
  'role': 'MAINTENANCE',
  'active': true,
  'isGuest': false,
  'maintenanceTeamId': team,
});

void main() {
  late MaintenanceSession session;
  late MaintenanceTaskDirectory directory;
  late Future<SyncedUser> Function() read;
  String? team;
  var fetches = 0;
  setUp(() {
    team = null;
    fetches = 0;
    read = () async => member(team);
    session = MaintenanceSession.forTesting(
      owner: () => 'fixture-owner',
      read: () => read(),
    );
    session.setAuthenticatedUser(
      publicId: 'MNT-FIXTURE',
      fullName: 'Fixture Technician',
      phone: '',
      region: '',
      assembly: '',
    );
    directory = MaintenanceTaskDirectory.forTesting(
      session: session,
      owner: () => 'fixture-owner',
      fetch: () async {
        fetches++;
        return [
          {
            'id': 'fixture-task',
            'title': 'Private crew task',
            'status': 'IN_PROGRESS',
            'assignedTeamId': team,
          },
        ];
      },
    );
  });
  tearDown(() {
    directory.dispose();
    session.dispose();
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MaintenanceTaskAccess(
          taskId: 'fixture-task',
          directory: directory,
          builder: (_, task) => Scaffold(
            body: Column(
              children: [
                Text(task.title),
                const TextField(key: ValueKey('draft')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'no-team task link skips report reads, then Retry verifies assignment',
    (tester) async {
      await show(tester);
      expect(find.text('No team assigned'), findsOneWidget);
      expect(fetches, 0);
      team = 'TEAM-A';
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Private crew task'), findsOneWidget);
      expect(fetches, 1);
      team = null;
      await session.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Private crew task'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('No team assigned'), findsOneWidget);
    },
  );

  testWidgets(
    'initial verification failure is recoverable, not empty membership',
    (tester) async {
      read = () async =>
          throw ApiException(statusCode: 503, message: 'Fixture offline');
      await show(tester);
      expect(find.text('Unable to load task'), findsOneWidget);
      expect(find.text('No team assigned'), findsNothing);
      read = () async => member(null);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to load task'), findsNothing);
      expect(find.text('No team assigned'), findsOneWidget);
    },
  );

  testWidgets(
    'same-team refresh and transient failure preserve the mounted draft',
    (tester) async {
      team = 'TEAM-A';
      await show(tester);
      await tester.enterText(find.byType(TextField), 'Keep these notes');
      final pending = Completer<SyncedUser>();
      read = () => pending.future;
      final refresh = directory.refresh();
      await tester.pump();
      expect(find.text('Keep these notes'), findsOneWidget);
      final failure = expectLater(refresh, throwsA(isA<ApiException>()));
      pending.completeError(
        ApiException(statusCode: 503, message: 'Fixture offline'),
      );
      await failure;
      await tester.pumpAndSettle();
      expect(find.text('Keep these notes'), findsOneWidget);
      read = () async => member(team);
      await directory.refresh();
      await tester.pumpAndSettle();
      expect(find.text('Keep these notes'), findsOneWidget);
    },
  );

  testWidgets('a team change between frames discards the former-team draft', (
    tester,
  ) async {
    team = 'TEAM-A';
    await show(tester);
    await tester.enterText(find.byType(TextField), 'Former crew notes');
    team = null;
    await session.refresh();
    team = 'TEAM-B';
    await directory.refresh();
    // Both membership changes happened before Flutter painted another frame.
    await tester.pumpAndSettle();
    expect(find.text('Private crew task'), findsOneWidget);
    expect(find.text('Former crew notes'), findsNothing);
  });
}
