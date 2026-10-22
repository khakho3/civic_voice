import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/services/admin_user_directory.dart';
import 'package:civic_voice/models/app_role.dart';

void main() {
  final directory = AdminUserDirectory.instance;

  tearDown(() {
    directory.invalidateAndClear();
    directory.firebaseAvailableForTesting = null;
    directory.tokenProviderForTesting = null;
    directory.listUsersForTesting = null;
    directory.updateUserForTesting = null;
    directory.deleteUserForTesting = null;
  });

  Map<String, dynamic> apiUser(
    String id,
    String name, {
    bool active = true,
  }) => {
    'id': id,
    'publicId': 'ADM-$id',
    'fullName': name,
    'phone': '+233240000000',
    'role': 'ADMIN',
    'active': active,
    'createdAt': DateTime(2026).toIso8601String(),
    'updatedAt': DateTime(2026).toIso8601String(),
  };

  test('starts unavailable without fabricated production users', () {
    expect(directory.users.value, isEmpty);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
    expect(directory.hasLiveSnapshot, isFalse);
  });

  test('unavailable refresh, save, and delete do not mutate local users', () async {
    final fixture = mockAdminUsers().first;
    directory.firebaseAvailableForTesting = false;
    directory.users.value = [fixture];
    final before = List<AdminUserItem>.of(directory.users.value);

    await expectLater(directory.refresh(), throwsStateError);
    await expectLater(
      directory.saveOnServer(fixture.copyWith(status: AdminUserStatus.inactive)),
      throwsStateError,
    );
    await expectLater(directory.deleteOnServer(fixture), throwsStateError);

    expect(directory.users.value, before);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.pendingMutationCount, isZero);
  });

  test('successful empty refresh establishes a complete empty snapshot', () async {
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.listUsersForTesting = (_) async => const [];

    await directory.refresh();

    expect(directory.users.value, isEmpty);
    expect(directory.state.value, AdminUserDirectoryState.loaded);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('first-load token failure is failed, not a confirmed empty snapshot', () async {
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => null;

    await expectLater(directory.refresh(), throwsStateError);

    expect(directory.state.value, AdminUserDirectoryState.failed);
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.users.value, isEmpty);
  });

  test('a confirmed mutation invalidates an older in-flight refresh', () async {
    final refreshRows = Completer<List<Map<String, dynamic>>>();
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.listUsersForTesting = (_) => refreshRows.future;

    final refresh = directory.refresh();
    await Future<void>.delayed(Duration.zero);
    final created = directory.upsertFromApi(apiUser('created', 'Created User'));
    refreshRows.complete([apiUser('older', 'Older User')]);
    await refresh;

    expect(directory.users.value.single.apiId, created.apiId);
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
  });

  test('session clear invalidates a delayed refresh without restoring users', () async {
    final rows = Completer<List<Map<String, dynamic>>>();
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.listUsersForTesting = (_) => rows.future;

    final refresh = directory.refresh();
    await Future<void>.delayed(Duration.zero);
    directory.invalidateAndClear();
    rows.complete([apiUser('stale', 'Stale User')]);
    await refresh;

    expect(directory.users.value, isEmpty);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
    expect(directory.loading.value, isFalse);
    expect(directory.hasLiveSnapshot, isFalse);
  });

  test('session clear invalidates a delayed save without restoring users', () async {
    final update = Completer<Map<String, dynamic>>();
    final fixture = AdminUserItem.fromApi(apiUser('save', 'Saved User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => update.future;

    final save = directory.saveOnServer(
      fixture.copyWith(status: AdminUserStatus.inactive),
    );
    await Future<void>.delayed(Duration.zero);
    directory.invalidateAndClear();
    final saveExpectation = expectLater(save, throwsStateError);
    update.complete(apiUser('save', 'Saved User', active: false));

    await saveExpectation;
    expect(directory.users.value, isEmpty);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
    expect(directory.pendingMutationCount, isZero);
  });

  test('session clear invalidates a delayed delete without restoring state', () async {
    final deletion = Completer<void>();
    final fixture = AdminUserItem.fromApi(apiUser('delete', 'Deleted User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.deleteUserForTesting = (_, _) => deletion.future;

    final delete = directory.deleteOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    directory.invalidateAndClear();
    final deleteExpectation = expectLater(delete, throwsStateError);
    deletion.complete();

    await deleteExpectation;
    expect(directory.users.value, isEmpty);
    expect(directory.state.value, AdminUserDirectoryState.unavailable);
    expect(directory.pendingMutationCount, isZero);
  });

  test('a stale create result cannot restore a cleared session', () {
    final session = directory.sessionGeneration;
    directory.invalidateAndClear();

    expect(
      () => directory.upsertFromApi(
        apiUser('created', 'Created User'),
        sessionGeneration: session,
      ),
      throwsStateError,
    );
    expect(directory.users.value, isEmpty);
    expect(directory.hasLiveSnapshot, isFalse);
  });

  test('a confirmed delete invalidates an older in-flight refresh', () async {
    final refreshRows = Completer<List<Map<String, dynamic>>>();
    final fixture = AdminUserItem.fromApi(apiUser('delete-me', 'Delete Me'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.listUsersForTesting = (_) => refreshRows.future;
    directory.deleteUserForTesting = (_, _) async {};

    final refresh = directory.refresh();
    await Future<void>.delayed(Duration.zero);
    await directory.deleteOnServer(fixture);
    refreshRows.complete([apiUser('delete-me', 'Delete Me')]);
    await refresh;

    expect(directory.users.value, isEmpty);
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminUserDirectoryState.loaded);
  });

  test('newer overlapping refresh wins deterministically', () async {
    final firstRows = Completer<List<Map<String, dynamic>>>();
    final secondRows = Completer<List<Map<String, dynamic>>>();
    final requests = [firstRows, secondRows];
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.listUsersForTesting = (_) => requests.removeAt(0).future;

    final first = directory.refresh();
    await Future<void>.delayed(Duration.zero);
    final second = directory.refresh();
    await Future<void>.delayed(Duration.zero);
    secondRows.complete([apiUser('newer', 'Newer User')]);
    await second;
    firstRows.complete([apiUser('older', 'Older User')]);
    await first;

    expect(directory.users.value.single.name, 'Newer User');
    expect(directory.state.value, AdminUserDirectoryState.loaded);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('failed mutation preserves confirmed users and provenance', () async {
    final fixture = AdminUserItem.fromApi(apiUser('stable', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) async {
      throw StateError('server rejected update');
    };

    await expectLater(
      directory.saveOnServer(fixture.copyWith(status: AdminUserStatus.inactive)),
      throwsStateError,
    );

    expect(directory.users.value.single.status, AdminUserStatus.active);
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, AdminUserDirectoryState.loaded);
  });

  test('the newest save for one user wins when responses complete out of order', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    final responses = [first, second];
    final fixture = AdminUserItem.fromApi(apiUser('same', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => responses.removeAt(0).future;

    final older = directory.saveOnServer(
      fixture.copyWith(status: AdminUserStatus.inactive),
    );
    await Future<void>.delayed(Duration.zero);
    final newer = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    second.complete(apiUser('same', 'Newer User'));
    await newer;
    final olderExpectation = expectLater(older, throwsStateError);
    first.complete(apiUser('same', 'Older User', active: false));

    await olderExpectation;
    expect(directory.users.value.single.name, 'Newer User');
    expect(directory.users.value.single.status, AdminUserStatus.active);
    expect(directory.pendingMutationCount, isZero);
  });

  test('completed revisions are cleaned without allowing an older save to win', () async {
    final olderResponse = Completer<Map<String, dynamic>>();
    final newerResponse = Completer<Map<String, dynamic>>();
    final laterResponse = Completer<Map<String, dynamic>>();
    final responses = [olderResponse, newerResponse, laterResponse];
    final fixture = AdminUserItem.fromApi(apiUser('same', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => responses.removeAt(0).future;

    final older = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    final newer = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    newerResponse.complete(apiUser('same', 'Newer User'));
    await newer;
    expect(directory.pendingMutationCount, isZero);

    final later = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    final olderExpectation = expectLater(older, throwsStateError);
    olderResponse.complete(apiUser('same', 'Older User'));
    await olderExpectation;
    expect(directory.pendingMutationCount, 1);

    laterResponse.complete(apiUser('same', 'Later User'));
    await later;
    expect(directory.users.value.single.name, 'Later User');
    expect(directory.pendingMutationCount, isZero);
  });

  test('failed mutations release their revision without changing confirmed data', () async {
    final fixture = AdminUserItem.fromApi(apiUser('failed', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) async {
      throw StateError('server rejected update');
    };

    await expectLater(directory.saveOnServer(fixture), throwsStateError);

    expect(directory.users.value.single.name, 'Stable User');
    expect(directory.pendingMutationCount, isZero);
  });

  test('a newer delete wins over an older save for the same user', () async {
    final update = Completer<Map<String, dynamic>>();
    final deletion = Completer<void>();
    final fixture = AdminUserItem.fromApi(apiUser('same', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => update.future;
    directory.deleteUserForTesting = (_, _) => deletion.future;

    final save = directory.saveOnServer(
      fixture.copyWith(status: AdminUserStatus.inactive),
    );
    await Future<void>.delayed(Duration.zero);
    final delete = directory.deleteOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    deletion.complete();
    await delete;
    final saveExpectation = expectLater(save, throwsStateError);
    update.complete(apiUser('same', 'Late Save', active: false));

    await saveExpectation;
    expect(directory.users.value, isEmpty);
  });

  test('a newer deactivate wins over an older save for the same user', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    final responses = [first, second];
    final fixture = AdminUserItem.fromApi(apiUser('same', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => responses.removeAt(0).future;

    final save = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    final deactivate = directory.toggleActiveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    second.complete(apiUser('same', 'Deactivated User', active: false));
    await deactivate;
    final saveExpectation = expectLater(save, throwsStateError);
    first.complete(apiUser('same', 'Late Save'));

    await saveExpectation;
    expect(directory.users.value.single.name, 'Deactivated User');
    expect(directory.users.value.single.status, AdminUserStatus.inactive);
  });

  test('a newer save wins over an older delete for the same user', () async {
    final deletion = Completer<void>();
    final update = Completer<Map<String, dynamic>>();
    final fixture = AdminUserItem.fromApi(apiUser('same', 'Stable User'));
    directory.users.value = [fixture];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.deleteUserForTesting = (_, _) => deletion.future;
    directory.updateUserForTesting = (_, _, _) => update.future;

    final delete = directory.deleteOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    final save = directory.saveOnServer(fixture);
    await Future<void>.delayed(Duration.zero);
    update.complete(apiUser('same', 'Newer Save', active: false));
    await save;
    final deleteExpectation = expectLater(delete, throwsStateError);
    deletion.complete();

    await deleteExpectation;
    expect(directory.users.value.single.name, 'Newer Save');
    expect(directory.users.value.single.status, AdminUserStatus.inactive);
  });

  test('mutations for different users remain independent', () async {
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    final responses = [first, second];
    final userA = AdminUserItem.fromApi(apiUser('a', 'User A'));
    final userB = AdminUserItem.fromApi(apiUser('b', 'User B'));
    directory.users.value = [userA, userB];
    directory.hasLiveSnapshot = true;
    directory.state.value = AdminUserDirectoryState.loaded;
    directory.firebaseAvailableForTesting = true;
    directory.tokenProviderForTesting = () async => 'token';
    directory.updateUserForTesting = (_, _, _) => responses.removeAt(0).future;

    final saveA = directory.saveOnServer(
      userA.copyWith(status: AdminUserStatus.inactive),
    );
    await Future<void>.delayed(Duration.zero);
    final saveB = directory.saveOnServer(
      userB.copyWith(status: AdminUserStatus.inactive),
    );
    await Future<void>.delayed(Duration.zero);
    second.complete(apiUser('b', 'Updated B', active: false));
    first.complete(apiUser('a', 'Updated A', active: false));
    await Future.wait([saveA, saveB]);

    expect(directory.users.value.map((user) => user.name), containsAll(['Updated A', 'Updated B']));
    expect(directory.pendingMutationCount, isZero);
  });

  test(
    'changing a user role updates the existing entry instead of duplicating it',
    () {
      directory.users.value = [
        AdminUserItem.fromApi({
          'id': 'stable-db-id-123',
          'fullName': 'Genny Amadapah',
          'phone': '+233241234567',
          'role': 'CITIZEN',
          'active': true,
          'publicId': 'CIT-000123',
          'createdAt': DateTime(2026).toIso8601String(),
          'updatedAt': DateTime(2026).toIso8601String(),
        }),
      ];

      expect(directory.users.value.length, 1);

      // Simulate the PATCH response after an Admin changes this account's
      // role to Municipal Officer — same underlying row (same 'id'), but
      // the backend mints a fresh publicId matching the new role (see
      // adminUsers.js's roleChanged branch).
      directory.upsertFromApi({
        'id': 'stable-db-id-123',
        'fullName': 'Genny Amadapah',
        'phone': '+233241234567',
        'role': 'MUNICIPAL',
        'active': true,
        'publicId': 'MUN-000045',
        'region': 'greaterAccra',
        'assembly': 'Accra Metropolitan',
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      });

      expect(
        directory.users.value.length,
        1,
        reason:
            'role change must update the existing row, not add a second one',
      );
      expect(directory.users.value.single.userId, 'MUN-000045');
      expect(directory.users.value.single.role, AppRole.municipalOfficer);
      expect(directory.users.value.single.apiId, 'stable-db-id-123');
      expect(directory.hasLiveSnapshot, isFalse);
      expect(directory.state.value, AdminUserDirectoryState.unavailable);
    },
  );
}
