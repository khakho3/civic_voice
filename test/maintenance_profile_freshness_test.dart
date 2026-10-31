import 'dart:async';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_maintenance_team_data.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:civic_voice/features/maintenance/models/maintenance_profile.dart';
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MaintenanceTeam crew(String? lead) => MaintenanceTeam.fromApi({
  'id': 'TEAM-FIXTURE',
  'name': 'Current crew',
  'region': 'greaterAccra',
  'assembly': 'Ga West',
  'memberUserIds': ['MNT-A', 'MNT-B'],
  'leadUserId': lead,
  'createdAt': '2026-10-31T00:00:00Z',
});

void main() {
  setUp(() {
    final profile = MaintenanceSession.instance.profile.value;
    final teams = MaintenanceTeamDirectory.instance.teams.value;
    addTearDown(() {
      MaintenanceSession.instance.profile.value = profile;
      MaintenanceTeamDirectory.instance.teams.value = teams;
    });
    MaintenanceSession.instance.profile.value = const MaintenanceProfile(
      publicId: 'MNT-A',
      fullName: 'Fixture A',
      phone: '',
      region: 'greaterAccra',
      assembly: 'Ga West',
      teamId: 'TEAM-FIXTURE',
      teamName: 'Cached crew',
      teamLeadUserId: 'MNT-A',
    );
    MaintenanceTeamDirectory.instance.teams.value = [crew('MNT-A')];
  });

  Future<void> show(
    WidgetTester tester, {
    Future<void> Function()? refresh,
  }) async {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ProfileScreen(onRefresh: refresh),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'current directory updates remove a lead pill even when cached sign-in says lead',
    (tester) async {
      await show(tester);
      expect(find.text('Team Lead'), findsOneWidget);
      MaintenanceTeamDirectory.instance.teams.value = [crew(null)];
      await tester.pump();
      expect(find.text('Team Lead'), findsNothing);
      expect(find.text('Current crew'), findsOneWidget);
      MaintenanceTeamDirectory.instance.teams.value = [crew('MNT-B')];
      await tester.pump();
      expect(find.text('Team Lead'), findsNothing);
      MaintenanceTeamDirectory.instance.teams.value = [crew('MNT-A')];
      await tester.pump();
      expect(find.text('Team Lead'), findsOneWidget);
    },
  );

  testWidgets('entry and resume refresh quietly without overlapping reads', (
    tester,
  ) async {
    var reads = 0;
    var pending = Completer<void>();
    await show(
      tester,
      refresh: () {
        reads++;
        return pending.future;
      },
    );
    expect(reads, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(reads, 1);
    expect(find.text('Fixture A'), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    pending = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(reads, 2);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('refresh failure retains profile and a pull retries it', (
    tester,
  ) async {
    var reads = 0;
    await show(
      tester,
      refresh: () async {
        if (++reads == 1) throw StateError('Fixture offline');
      },
    );
    expect(find.text('Unable to refresh team details'), findsOneWidget);
    expect(find.text('Fixture A'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(find.text('Unable to refresh team details'), findsNothing);
  });

  testWidgets(
    'membership removal updates the mounted profile without re-login',
    (tester) async {
      await show(tester);
      MaintenanceSession.instance.profile.value = const MaintenanceProfile(
        publicId: 'MNT-A',
        fullName: 'Fixture A',
        phone: '',
        region: 'greaterAccra',
        assembly: 'Ga West',
      );
      await tester.pump();
      expect(find.text('Not assigned to a team'), findsOneWidget);
      expect(find.text('Team Lead'), findsNothing);
      expect(find.text('Current crew'), findsNothing);
    },
  );
}
