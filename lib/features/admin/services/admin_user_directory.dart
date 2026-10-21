import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';
import '../../../services/api_client.dart';

/// In-memory cache of the authorized Admin user directory. Records are only
/// populated from confirmed server responses; previews and tests seed their
/// own explicit fixtures.
enum AdminUserDirectoryState { unavailable, loading, loaded, failed }

class AdminUserDirectory {
  AdminUserDirectory._();

  static final AdminUserDirectory instance = AdminUserDirectory._();

  final ValueNotifier<List<AdminUserItem>> users = ValueNotifier(
    const <AdminUserItem>[],
  );
  final ValueNotifier<AdminUserDirectoryState> state = ValueNotifier(
    AdminUserDirectoryState.unavailable,
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;

  /// Invalidates only list reads. A successful mutation advances it *after*
  /// the server confirms the mutation, so a racing list read cannot replace
  /// that confirmed result.
  int _listReadRevision = 0;
  int _sessionGeneration = 0;

  /// Active mutation revision per user. Entries are removed once their
  /// operation finishes; revisions themselves come from the monotonic counter
  /// below so an old completion can never become current after cleanup.
  final Map<String, int> _mutationRevisions = <String, int>{};
  int _nextMutationRevision = 0;
  String? currentApiUserId;

  @visibleForTesting
  bool? firebaseAvailableForTesting;
  @visibleForTesting
  Future<String?> Function()? tokenProviderForTesting;
  @visibleForTesting
  Future<List<Map<String, dynamic>>> Function(String token)? listUsersForTesting;
  @visibleForTesting
  Future<Map<String, dynamic>> Function(
    String userId,
    String token,
    Map<String, dynamic> fields,
  )?
  updateUserForTesting;
  @visibleForTesting
  Future<void> Function(String userId, String token)? deleteUserForTesting;

  bool get canRefresh => firebaseAvailableForTesting ?? Firebase.apps.isNotEmpty;

  /// A caller that starts an async operation can retain this value and reject
  /// its result when the signed-in session has since been cleared.
  int get sessionGeneration => _sessionGeneration;

  bool isSessionGenerationCurrent(int generation) =>
      generation == _sessionGeneration;

  @visibleForTesting
  int get pendingMutationCount => _mutationRevisions.length;

  AdminUserItem? get currentUser {
    final id = currentApiUserId;
    if (id == null) return null;
    for (final user in users.value) {
      if (user.apiRecordId == id) return user;
    }
    return null;
  }

  Future<void> refresh() async {
    final sessionGeneration = _sessionGeneration;
    final revision = ++_listReadRevision;
    if (!canRefresh) {
      _setUnavailable(
        'User data is unavailable because Firebase is not configured.',
      );
      throw StateError('User data is unavailable without Firebase');
    }
    loading.value = true;
    state.value = AdminUserDirectoryState.loading;
    error.value = null;
    try {
      final token = await _idToken();
      if (!_isCurrentListRead(revision, sessionGeneration)) return;
      if (token == null) {
        throw StateError('A signed-in Admin is required');
      }
      final response = await _listUsers(token);
      if (!_isCurrentListRead(revision, sessionGeneration)) return;
      users.value = response.map(AdminUserItem.fromApi).toList();
      hasLiveSnapshot = true;
      state.value = AdminUserDirectoryState.loaded;
    } catch (exception) {
      if (!_isCurrentListRead(revision, sessionGeneration)) return;
      error.value = exception.toString();
      state.value = AdminUserDirectoryState.failed;
      rethrow;
    } finally {
      if (_isCurrentListRead(revision, sessionGeneration)) {
        loading.value = false;
      }
    }
  }

  /// Inserts a record only after a successful authoritative API response and
  /// returns that exact parsed record to the caller.
  AdminUserItem upsertFromApi(
    Map<String, dynamic> json, {
    int? sessionGeneration,
  }) {
    if (sessionGeneration != null &&
        !isSessionGenerationCurrent(sessionGeneration)) {
      throw StateError('User response belongs to a previous session');
    }
    final user = AdminUserItem.fromApi(json);
    // Match on the stable database id, not userId — userId mirrors the
    // backend's publicId, which the server deliberately mints fresh
    // whenever role changes (CIT-000123 -> MUN-000045, still the same
    // row). Matching on userId meant a role edit's response never matched
    // its own pre-edit entry here, so it got prepended as a second row
    // instead of replacing the first — same account, same everything,
    // just two entries with different roles.
    users.value = [
      user,
      for (final existing in users.value)
        if (existing.apiId != user.apiId) existing,
    ];
    _applyConfirmedMutation();
    return user;
  }

  Future<void> saveOnServer(AdminUserItem user) async {
    final operation = _beginMutation(user.apiRecordId);
    try {
      if (!canRefresh) {
        throw StateError('User updates are unavailable without Firebase');
      }
      final token = await _idToken();
      _requireCurrentMutation(operation);
      if (token == null) throw StateError('A signed-in Admin is required');
      final fields = {
        'role': _backendRole(user.role),
        'active': user.status != AdminUserStatus.inactive,
        'adminTier': user.adminTier?.name,
        'region': user.region?.name,
        'assembly': user.assembly?.name,
      };
      final response = await _updateUser(
        user.apiRecordId,
        token,
        fields,
      );
      _requireCurrentMutation(operation);
      upsertFromApi(
        response,
        sessionGeneration: operation.sessionGeneration,
      );
    } finally {
      _finishMutation(operation);
    }
  }

  Future<void> deleteOnServer(AdminUserItem user) async {
    final operation = _beginMutation(user.apiRecordId);
    try {
      if (!canRefresh) {
        throw StateError('User deletion is unavailable without Firebase');
      }
      final token = await _idToken();
      _requireCurrentMutation(operation);
      if (token == null) throw StateError('A signed-in Admin is required');
      await _deleteUser(user.apiRecordId, token);
      _requireCurrentMutation(operation);
      _applyConfirmedMutation();
      users.value = users.value
          .where((existing) => existing.apiId != user.apiRecordId)
          .toList();
    } finally {
      _finishMutation(operation);
    }
  }

  Future<void> toggleActiveOnServer(AdminUserItem user) async {
    final updated = user.copyWith(
      status: user.status == AdminUserStatus.inactive
          ? AdminUserStatus.active
          : AdminUserStatus.inactive,
    );
    await saveOnServer(updated);
  }

  void _setUnavailable(String message) {
    loading.value = false;
    error.value = message;
    state.value = hasLiveSnapshot
        ? AdminUserDirectoryState.failed
        : AdminUserDirectoryState.unavailable;
  }

  /// Applies a single-record server result without claiming a complete list
  /// was fetched. It invalidates reads only after the mutation is confirmed.
  void _applyConfirmedMutation() {
    _listReadRevision++;
    if (loading.value) {
      loading.value = false;
    }
    state.value = hasLiveSnapshot
        ? AdminUserDirectoryState.loaded
        : AdminUserDirectoryState.unavailable;
    error.value = null;
  }

  /// Shared session owners must call this instead of writing directory
  /// notifiers directly, so stale authenticated reads cannot repopulate data
  /// after session clear.
  void invalidateAndClear() {
    _sessionGeneration++;
    _listReadRevision++;
    _mutationRevisions.clear();
    users.value = const <AdminUserItem>[];
    loading.value = false;
    error.value = null;
    hasLiveSnapshot = false;
    currentApiUserId = null;
    state.value = AdminUserDirectoryState.unavailable;
  }

  _UserMutationOperation _beginMutation(String apiId) {
    final revision = ++_nextMutationRevision;
    _mutationRevisions[apiId] = revision;
    return _UserMutationOperation(
      apiId: apiId,
      revision: revision,
      sessionGeneration: _sessionGeneration,
    );
  }

  bool _isCurrentListRead(int revision, int sessionGeneration) =>
      revision == _listReadRevision &&
      isSessionGenerationCurrent(sessionGeneration);

  bool _isCurrentMutation(_UserMutationOperation operation) =>
      isSessionGenerationCurrent(operation.sessionGeneration) &&
      _mutationRevisions[operation.apiId] == operation.revision;

  void _requireCurrentMutation(_UserMutationOperation operation) {
    if (!_isCurrentMutation(operation)) {
      throw StateError('User operation is no longer current');
    }
  }

  void _finishMutation(_UserMutationOperation operation) {
    if (_mutationRevisions[operation.apiId] == operation.revision) {
      _mutationRevisions.remove(operation.apiId);
    }
  }

  Future<String?> _idToken() async {
    final testTokenProvider = tokenProviderForTesting;
    if (testTokenProvider != null) {
      return testTokenProvider();
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return currentUser.getIdToken();
  }

  Future<List<Map<String, dynamic>>> _listUsers(String token) =>
      listUsersForTesting?.call(token) ??
      ApiClient.instance.listUsers(idToken: token);

  Future<Map<String, dynamic>> _updateUser(
    String userId,
    String token,
    Map<String, dynamic> fields,
  ) =>
      updateUserForTesting?.call(userId, token, fields) ??
      ApiClient.instance.updateUser(userId, idToken: token, fields: fields);

  Future<void> _deleteUser(String userId, String token) =>
      deleteUserForTesting?.call(userId, token) ??
      ApiClient.instance.deleteUser(userId, idToken: token);

  static String _backendRole(AppRole role) => switch (role) {
    AppRole.citizen => 'CITIZEN',
    AppRole.municipalOfficer => 'MUNICIPAL',
    AppRole.maintenanceTeam => 'MAINTENANCE',
    AppRole.ministrySupervisor => 'MINISTRY',
    AppRole.systemAdministrator => 'ADMIN',
  };

  AdminUserItem? userById(String userId) {
    for (final user in users.value) {
      if (user.userId == userId) return user;
    }
    return null;
  }

  /// The Municipal Officer account that "represents" [assemblyName]/[region]
  /// wherever only one contact can be shown (e.g. Ministry's per-assembly
  /// performance view) — whichever provisioned officer for that assembly
  /// was created first. `null` when no officer has been provisioned for it
  /// yet, so callers can fall back to placeholder contact info.
  ///
  /// [assemblyName] is matched in `"<name> <type label>"` form (e.g. "Accra
  /// Metropolitan") — the shape [RegionalLeaderItem.name] already uses —
  /// rather than [Assembly.name] alone, since a caller like Ministry's
  /// Municipality Detail only has that composite label on hand, not the
  /// [Assembly] record itself.
  ///
  /// Deliberately not a full hierarchy: an assembly can have several
  /// Municipal Officer accounts (Admins staff their own team as it grows),
  /// but Francis's call was to keep this simple rather than model seniority
  /// — the earliest account is just a stable, unambiguous pick.
  AdminUserItem? correspondentOfficerFor(String assemblyName, Region region) {
    AdminUserItem? earliest;
    for (final user in users.value) {
      if (user.role != AppRole.municipalOfficer) continue;
      final assembly = user.assembly;
      if (assembly == null || assembly.region != region) continue;
      if ('${assembly.name} ${assembly.type.label}' != assemblyName) continue;
      if (earliest == null ||
          user.accountCreated.isBefore(earliest.accountCreated)) {
        earliest = user;
      }
    }
    return earliest;
  }

  /// The System Administrator (Admin-tier) account that "represents"
  /// [assembly] wherever only one contact can be shown (e.g. that assembly's
  /// own Admin Dashboard greeting) — whichever provisioned Admin account for
  /// that assembly was created first, mirroring [correspondentOfficerFor]'s
  /// same reasoning. `null` when no Admin has been provisioned for it yet,
  /// so callers can fall back to a placeholder identity.
  AdminUserItem? correspondentAdminFor(Assembly assembly) {
    AdminUserItem? earliest;
    for (final user in users.value) {
      if (user.role != AppRole.systemAdministrator) continue;
      if (user.adminTier != AdminTier.admin) continue;
      final userAssembly = user.assembly;
      if (userAssembly == null) continue;
      if (userAssembly.name != assembly.name ||
          userAssembly.region != assembly.region) {
        continue;
      }
      if (earliest == null ||
          user.accountCreated.isBefore(earliest.accountCreated)) {
        earliest = user;
      }
    }
    return earliest;
  }

}

class _UserMutationOperation {
  const _UserMutationOperation({
    required this.apiId,
    required this.revision,
    required this.sessionGeneration,
  });

  final String apiId;
  final int revision;
  final int sessionGeneration;
}
