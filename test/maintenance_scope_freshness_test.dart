import 'dart:async';

import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_session.dart';
import 'package:civic_voice/features/maintenance/services/maintenance_task_directory.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

SyncedUser user({
  String? team = 'TEAM-A',
  String? lead = 'MNT-A',
  String name = 'Fixture A',
  String uid = 'uid-a',
  String role = 'MAINTENANCE',
  bool active = true,
  bool guest = false,
}) => SyncedUser.fromJson({
  'id': 'a',
  'publicId': 'MNT-A',
  'firebaseUid': uid,
  'role': role,
  'active': active,
  'isGuest': guest,
  'fullName': name,
  'region': 'greaterAccra',
  'assembly': 'Ga West',
  'maintenanceTeamId': team,
  'maintenanceTeamName': team == null ? null : 'Current $team',
  'maintenanceTeamLeadUserId': lead,
});

void signIn(
  MaintenanceSession session, {
  String? team = 'TEAM-A',
  String? lead = 'MNT-A',
}) => session.setAuthenticatedUser(
  publicId: 'MNT-A',
  fullName: 'Fixture A',
  phone: '',
  region: 'greaterAccra',
  assembly: 'Ga West',
  teamId: team,
  teamName: 'Fixture crew',
  teamLeadUserId: lead,
);

Map<String, dynamic> report(String team) => {
  'id': 'report',
  'publicReference': 'CV-FIXTURE',
  'status': 'IN_PROGRESS',
  'assignedTeamId': team,
};

void main() {
  test(
    'latest profile read wins, including explicit removal of the lead',
    () async {
      final old = Completer<SyncedUser>(), fresh = Completer<SyncedUser>();
      var reads = 0;
      final session = MaintenanceSession.forTesting(
        owner: () => 'uid-a',
        read: () => reads++ == 0 ? old.future : fresh.future,
      );
      addTearDown(session.dispose);
      signIn(session);
      final first = session.refresh(), second = session.refresh();
      fresh.complete(user(team: 'TEAM-B', lead: null));
      await second;
      old.complete(user());
      await first;
      expect(session.profile.value.teamId, 'TEAM-B');
      expect(session.profile.value.teamLeadUserId, isNull);
    },
  );

  test(
    'logout and login to the same UID cannot resurrect an older profile',
    () async {
      final pending = Completer<SyncedUser>();
      final session = MaintenanceSession.forTesting(
        owner: () => 'uid-a',
        read: () => pending.future,
      );
      addTearDown(session.dispose);
      signIn(session);
      final read = session.refresh();
      final rejected = expectLater(read, throwsStateError);
      session.clearSession();
      signIn(session, team: 'TEAM-B');
      pending.complete(user());
      await rejected;
      expect(session.profile.value.teamId, 'TEAM-B');
    },
  );

  test('a changed Firebase owner cannot publish an old response', () async {
    var owner = 'uid-a';
    final pending = Completer<SyncedUser>();
    final session = MaintenanceSession.forTesting(
      owner: () => owner,
      read: () => pending.future,
    );
    addTearDown(session.dispose);
    signIn(session);
    final rejected = expectLater(session.refresh(), throwsStateError);
    owner = 'uid-b';
    pending.complete(user());
    await rejected;
    expect(session.verifiedOwner, 'uid-a');
  });

  test(
    'mismatched response UID is rejected instead of assigning its team',
    () async {
      final session = MaintenanceSession.forTesting(
        owner: () => 'uid-a',
        read: () async => user(uid: 'someone-else', team: 'TEAM-FOREIGN'),
      );
      addTearDown(session.dispose);
      signIn(session);
      await expectLater(session.refresh(), throwsStateError);
      expect(session.profile.value.teamId, 'TEAM-A');
    },
  );

  for (final response in [
    user(role: 'CITIZEN'),
    user(active: false),
    user(guest: true),
  ]) {
    test(
      'revoked Maintenance access clears cached identity (${response.role}/${response.active}/${response.isGuest})',
      () async {
        final session = MaintenanceSession.forTesting(
          owner: () => 'uid-a',
          read: () async => response,
        );
        addTearDown(session.dispose);
        signIn(session);
        await expectLater(session.refresh(), throwsStateError);
        expect(session.authenticated, isFalse);
        expect(session.verifiedOwner, isNull);
        expect(session.profile.value.teamId, isNull);
        expect(session.profile.value.publicId, isEmpty);
      },
    );
  }

  for (final status in [401, 403, 503]) {
    test(
      'profile error $status clears revoked access and retains an unavailable snapshot',
      () async {
        final session = MaintenanceSession.forTesting(
          owner: () => 'uid-a',
          read: () async =>
              throw ApiException(statusCode: status, message: 'Fixture error'),
        );
        addTearDown(session.dispose);
        signIn(session);
        await expectLater(session.refresh(), throwsA(isA<ApiException>()));
        expect(session.profile.value.teamId, status == 503 ? 'TEAM-A' : isNull);
      },
    );
  }

  test(
    'a name save during a read survives while current membership still refreshes',
    () async {
      final pending = Completer<SyncedUser>();
      final session = MaintenanceSession.forTesting(
        owner: () => 'uid-a',
        read: () => pending.future,
      );
      addTearDown(session.dispose);
      signIn(session);
      final read = session.refresh();
      session.updateProfile(fullName: 'New name');
      pending.complete(user(team: 'TEAM-B'));
      await read;
      expect(session.profile.value.fullName, 'New name');
      expect(session.profile.value.teamId, 'TEAM-B');
    },
  );

  group('task scope', () {
    late MaintenanceSession session;
    late MaintenanceTaskDirectory directory;
    late SyncedUser current;
    late String? owner;
    late Future<List<Map<String, dynamic>>> Function() fetch;
    setUp(() {
      owner = 'uid-a';
      current = user();
      session = MaintenanceSession.forTesting(
        owner: () => owner,
        read: () async => current,
      );
      signIn(session);
      fetch = () async => [report('TEAM-A')];
      directory = MaintenanceTaskDirectory.forTesting(
        session: session,
        owner: () => owner,
        fetch: () => fetch(),
      );
    });
    tearDown(() {
      directory.dispose();
      session.dispose();
    });

    test(
      'removal clears cached cards immediately and no longer fetches tasks',
      () async {
        await directory.refresh();
        expect(directory.tasks.value, hasLength(1));
        current = user(team: null, lead: null);
        await session.refresh();
        expect(directory.tasks.value, isEmpty);
        var fetched = false;
        fetch = () async {
          fetched = true;
          return [];
        };
        await directory.refresh();
        expect(fetched, isFalse);
        expect(directory.hasLiveSnapshot, isTrue);
      },
    );

    test(
      'a late task response cannot revive cards after a team move and return',
      () async {
        final response = Completer<List<Map<String, dynamic>>>();
        final started = Completer<void>();
        fetch = () {
          started.complete();
          return response.future;
        };
        final read = directory.refresh();
        await started.future;
        current = user(team: 'TEAM-B');
        await session.refresh();
        current = user();
        await session.refresh();
        response.complete([report('TEAM-A')]);
        await read;
        expect(directory.tasks.value, isEmpty);
        expect(directory.hasLiveSnapshot, isFalse);
      },
    );

    test(
      'lead-only changes retain cards and every current member may submit',
      () async {
        await directory.refresh();
        final task = directory.tasks.value.single;
        current = user(lead: 'MNT-B');
        await session.refresh();
        expect(directory.tasks.value, hasLength(1));
        expect(directory.canSubmitEvidence(task), isTrue);
        owner = 'uid-b';
        expect(directory.canSubmitEvidence(task), isFalse);
        owner = null;
        expect(directory.canSubmitEvidence(task), isFalse);
      },
    );

    test('current team and read-only statuses gate submission', () async {
      await directory.refresh();
      expect(
        directory.canSubmitEvidence(MaintenanceTask.fromApi(report('TEAM-B'))),
        isFalse,
      );
      expect(
        directory.canSubmitEvidence(
          MaintenanceTask.fromApi({
            ...report('TEAM-A'),
            'status': 'PENDING_APPROVAL',
          }),
        ),
        isFalse,
      );
      final old = directory.tasks.value.single;
      session.clearSession();
      expect(directory.tasks.value, isEmpty);
      expect(directory.canSubmitEvidence(old), isFalse);
    });
  });
}
