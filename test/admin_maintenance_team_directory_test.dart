import 'dart:async';

import 'package:civic_voice/features/admin/models/admin_maintenance_team_data.dart';
import 'package:civic_voice/features/admin/services/admin_maintenance_team_directory.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _team(String id, String name) => <String, dynamic>{
  'id': id,
  'name': name,
  'region': 'ashanti',
  'assembly': 'Kumasi',
  'memberUserIds': const <String>[],
  'createdAt': '2026-10-18T12:00:00.000Z',
};

MaintenanceTeam _teamFixture(String id, String name) =>
    MaintenanceTeam.fromApi(_team(id, name));

MaintenanceTeamDirectory _directory({
  required Future<List<Map<String, dynamic>>> Function(String) listFetch,
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)?
      createFetch,
  Future<Map<String, dynamic>> Function(
    String,
    String,
    Map<String, dynamic>,
  )?
      updateFetch,
  Future<void> Function(String, String)? deleteFetch,
}) =>
    MaintenanceTeamDirectory.forTesting(
      firebaseAvailable: () => true,
      tokenProvider: () async => 'test-token',
      listFetcher: listFetch,
      createFetcher: createFetch ?? (_, __) async => _team('TEAM-new', 'New team'),
      updateFetcher: updateFetch ??
          (teamId, _, fields) async =>
              _team(teamId, fields['name'] as String),
      deleteFetcher: deleteFetch ?? (_, __) async {},
    );

Future<void> _settle() async {
  await Future<void>.microtask(() {});
  await Future<void>.microtask(() {});
}

void main() {
  test('an older refresh success cannot replace a newer confirmed snapshot',
      () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) =>
          requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refreshForAdmin();
    await _settle();
    final newer = directory.refreshForAdmin();
    await _settle();
    newerResponse.complete([_team('TEAM-2', 'Newer team')]);
    await newer;
    olderResponse.complete([_team('TEAM-1', 'Older team')]);
    await older;

    expect(directory.teams.value.single.name, 'Newer team');
    expect(directory.state.value, MaintenanceTeamDirectoryState.loaded);
  });

  test('an older refresh failure cannot replace a newer confirmed snapshot',
      () async {
    final olderResponse = Completer<List<Map<String, dynamic>>>();
    final newerResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) =>
          requests++ == 0 ? olderResponse.future : newerResponse.future,
    );

    final older = directory.refreshForAdmin();
    await _settle();
    final newer = directory.refreshForAdmin();
    await _settle();
    newerResponse.complete([_team('TEAM-2', 'Newer team')]);
    await newer;
    olderResponse.completeError(StateError('older request failed'));
    await expectLater(older, throwsStateError);

    expect(directory.teams.value.single.name, 'Newer team');
    expect(directory.state.value, MaintenanceTeamDirectoryState.loaded);
  });

  test('a refresh started before a confirmed create cannot restore old teams',
      () async {
    final refreshResponse = Completer<List<Map<String, dynamic>>>();
    final createResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      listFetch: (_) => refreshResponse.future,
      createFetch: (_, __) => createResponse.future,
    );
    directory.teams.value = [_teamFixture('TEAM-1', 'Original team')];
    directory.state.value = MaintenanceTeamDirectoryState.loaded;

    final refresh = directory.refreshForAdmin();
    await _settle();
    final create = directory.createTeamOnServer(
      name: 'Created team',
      assembly: _teamFixture('TEAM-1', 'Original team').assembly,
    );
    await _settle();
    createResponse.complete(_team('TEAM-2', 'Created team'));
    await create;
    refreshResponse.complete([_team('TEAM-1', 'Old server team')]);
    await refresh;

    expect(directory.teams.value.map((team) => team.name), [
      'Created team',
      'Original team',
    ]);
    expect(directory.state.value, MaintenanceTeamDirectoryState.loaded);
  });

  test('a refresh started before a confirmed update cannot restore old team data',
      () async {
    final refreshResponse = Completer<List<Map<String, dynamic>>>();
    final updateResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      listFetch: (_) => refreshResponse.future,
      updateFetch: (_, __, ___) => updateResponse.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];
    directory.state.value = MaintenanceTeamDirectoryState.loaded;

    final refresh = directory.refreshForAdmin();
    await _settle();
    final update = directory.updateTeamOnServer(
      original.copyWith(name: 'Updated team'),
    );
    await _settle();
    updateResponse.complete(_team('TEAM-1', 'Updated team'));
    await update;
    refreshResponse.complete([_team('TEAM-1', 'Old server team')]);
    await refresh;

    expect(directory.teams.value.single.name, 'Updated team');
  });

  test('a refresh started before a confirmed delete cannot restore the team',
      () async {
    final refreshResponse = Completer<List<Map<String, dynamic>>>();
    final deleteResponse = Completer<void>();
    final directory = _directory(
      listFetch: (_) => refreshResponse.future,
      deleteFetch: (_, __) => deleteResponse.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];
    directory.state.value = MaintenanceTeamDirectoryState.loaded;

    final refresh = directory.refreshForAdmin();
    await _settle();
    final delete = directory.deleteTeamOnServer(original);
    await _settle();
    deleteResponse.complete();
    await delete;
    refreshResponse.complete([_team('TEAM-1', 'Old server team')]);
    await refresh;

    expect(directory.teams.value, isEmpty);
    expect(directory.state.value, MaintenanceTeamDirectoryState.loaded);
  });

  test('newer same-team mutations win local publication', () async {
    final firstResponse = Completer<Map<String, dynamic>>();
    final secondResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) async => const [],
      updateFetch: (_, __, ___) =>
          requests++ == 0 ? firstResponse.future : secondResponse.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];

    final first = directory.updateTeamOnServer(
      original.copyWith(name: 'First update'),
    );
    await _settle();
    final second = directory.updateTeamOnServer(
      original.copyWith(name: 'Second update'),
    );
    await _settle();
    secondResponse.complete(_team('TEAM-1', 'Second update'));
    await second;
    firstResponse.complete(_team('TEAM-1', 'First update'));
    await expectLater(first, throwsStateError);

    expect(directory.teams.value.single.name, 'Second update');
  });

  test('a late mutation cannot reuse ownership after a newer mutation cleans up',
      () async {
    final firstResponse = Completer<Map<String, dynamic>>();
    final secondResponse = Completer<Map<String, dynamic>>();
    final thirdResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) async => const [],
      updateFetch: (_, __, ___) {
        switch (requests++) {
          case 0:
            return firstResponse.future;
          case 1:
            return secondResponse.future;
          default:
            return thirdResponse.future;
        }
      },
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];

    final first = directory.updateTeamOnServer(
      original.copyWith(name: 'First update'),
    );
    await _settle();
    final second = directory.updateTeamOnServer(
      original.copyWith(name: 'Second update'),
    );
    await _settle();

    secondResponse.complete(_team('TEAM-1', 'Second update'));
    await second;
    expect(directory.activeTeamMutationCount, 0);

    final third = directory.updateTeamOnServer(
      original.copyWith(name: 'Third update'),
    );
    await _settle();
    expect(directory.activeTeamMutationCount, 1);

    firstResponse.complete(_team('TEAM-1', 'First update'));
    await expectLater(first, throwsStateError);
    expect(directory.activeTeamMutationCount, 1);

    thirdResponse.complete(_team('TEAM-1', 'Third update'));
    await third;

    expect(directory.teams.value.single.name, 'Third update');
    expect(directory.activeTeamMutationCount, 0);
  });

  test('completed failed mutation releases only its own active entry', () async {
    final response = Completer<Map<String, dynamic>>();
    final directory = _directory(
      listFetch: (_) async => const [],
      updateFetch: (_, __, ___) => response.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];

    final update = directory.updateTeamOnServer(
      original.copyWith(name: 'Failed update'),
    );
    await _settle();
    expect(directory.activeTeamMutationCount, 1);

    response.completeError(StateError('update failed'));
    await expectLater(update, throwsStateError);

    expect(directory.activeTeamMutationCount, 0);
    expect(directory.teams.value.single.name, 'Original team');
  });

  test('mutations for different teams publish independently', () async {
    final firstResponse = Completer<Map<String, dynamic>>();
    final secondResponse = Completer<Map<String, dynamic>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) async => const [],
      updateFetch: (_, __, ___) =>
          requests++ == 0 ? firstResponse.future : secondResponse.future,
    );
    final first = _teamFixture('TEAM-1', 'First');
    final second = _teamFixture('TEAM-2', 'Second');
    directory.teams.value = [first, second];

    final updateFirst = directory.updateTeamOnServer(
      first.copyWith(name: 'First updated'),
    );
    await _settle();
    final updateSecond = directory.updateTeamOnServer(
      second.copyWith(name: 'Second updated'),
    );
    await _settle();
    secondResponse.complete(_team('TEAM-2', 'Second updated'));
    await updateSecond;
    firstResponse.complete(_team('TEAM-1', 'First updated'));
    await updateFirst;

    expect(
      directory.teams.value.map((team) => team.name),
      containsAll(<String>['First updated', 'Second updated']),
    );
  });

  test('a failed delete preserves confirmed team data', () async {
    final deleteResponse = Completer<void>();
    final directory = _directory(
      listFetch: (_) async => const [],
      deleteFetch: (_, __) => deleteResponse.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];
    directory.state.value = MaintenanceTeamDirectoryState.loaded;

    final delete = directory.deleteTeamOnServer(original);
    await _settle();
    deleteResponse.completeError(StateError('delete failed'));
    await expectLater(delete, throwsStateError);

    expect(directory.teams.value, [original]);
    expect(directory.state.value, MaintenanceTeamDirectoryState.loaded);
  });

  test('a failed latest refresh retains a confirmed snapshot as stale', () async {
    final failedResponse = Completer<List<Map<String, dynamic>>>();
    var requests = 0;
    final directory = _directory(
      listFetch: (_) => requests++ == 0
          ? Future.value([_team('TEAM-1', 'Confirmed team')])
          : failedResponse.future,
    );
    await directory.refreshForAdmin();

    final refresh = directory.refreshForAdmin();
    await _settle();
    failedResponse.completeError(StateError('latest request failed'));
    await expectLater(refresh, throwsStateError);

    expect(directory.teams.value.single.name, 'Confirmed team');
    expect(directory.state.value, MaintenanceTeamDirectoryState.failed);
  });

  test('invalidation prevents a pending refresh from repopulating teams',
      () async {
    final response = Completer<List<Map<String, dynamic>>>();
    final directory = _directory(listFetch: (_) => response.future);

    final refresh = directory.refreshForAdmin();
    await _settle();
    directory.invalidateAndClear();
    response.complete([_team('TEAM-1', 'Late team')]);
    await refresh;

    expect(directory.teams.value, isEmpty);
    expect(directory.state.value, MaintenanceTeamDirectoryState.unavailable);
  });

  test('invalidation prevents a pending mutation from publishing a team',
      () async {
    final updateResponse = Completer<Map<String, dynamic>>();
    final directory = _directory(
      listFetch: (_) async => const [],
      updateFetch: (_, __, ___) => updateResponse.future,
    );
    final original = _teamFixture('TEAM-1', 'Original team');
    directory.teams.value = [original];

    final update = directory.updateTeamOnServer(
      original.copyWith(name: 'Late update'),
    );
    await _settle();
    directory.invalidateAndClear();
    updateResponse.complete(_team('TEAM-1', 'Late update'));
    await expectLater(update, throwsStateError);

    expect(directory.teams.value, isEmpty);
    expect(directory.state.value, MaintenanceTeamDirectoryState.unavailable);
  });
}
