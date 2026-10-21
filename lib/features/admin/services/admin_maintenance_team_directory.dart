import 'package:flutter/foundation.dart';

import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/admin_maintenance_team_data.dart';

/// Whether [teams] came from a confirmed server response. A non-empty list is
/// never manufactured for production presentation; callers can retain a
/// previously confirmed list while a later refresh reports [failed].
enum MaintenanceTeamDirectoryState { unavailable, loading, loaded, failed }

class MaintenanceTeamDirectory {
  MaintenanceTeamDirectory._({
    bool Function()? firebaseAvailable,
    Future<String?> Function()? tokenProvider,
    Future<List<Map<String, dynamic>>> Function(String token)? listFetcher,
    Future<Map<String, dynamic>> Function(
      String token,
      Map<String, dynamic> fields,
    )?
    createFetcher,
    Future<Map<String, dynamic>> Function(
      String teamId,
      String token,
      Map<String, dynamic> fields,
    )?
    updateFetcher,
    Future<void> Function(String teamId, String token)? deleteFetcher,
  })  : _firebaseAvailable = firebaseAvailable ?? (() => Firebase.apps.isNotEmpty),
        _tokenProvider = tokenProvider ?? _firebaseIdToken,
        _listFetcher = listFetcher ??
            ((token) => ApiClient.instance.listMaintenanceTeams(idToken: token)),
        _createFetcher = createFetcher ??
            ((token, fields) => ApiClient.instance.createMaintenanceTeam(
                  idToken: token,
                  fields: fields,
                )),
        _updateFetcher = updateFetcher ??
            ((teamId, token, fields) => ApiClient.instance.updateMaintenanceTeam(
                  teamId,
                  idToken: token,
                  fields: fields,
                )),
        _deleteFetcher = deleteFetcher ??
            ((teamId, token) =>
                ApiClient.instance.deleteMaintenanceTeam(teamId, idToken: token));

  static final MaintenanceTeamDirectory instance = MaintenanceTeamDirectory._();

  static Future<String?> _firebaseIdToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    return currentUser.getIdToken();
  }

  /// Isolated request hooks for deterministic Admin directory tests. Production
  /// continues to use Firebase and the approved Maintenance Team endpoints.
  @visibleForTesting
  factory MaintenanceTeamDirectory.forTesting({
    required bool Function() firebaseAvailable,
    required Future<String?> Function() tokenProvider,
    required Future<List<Map<String, dynamic>>> Function(String token) listFetcher,
    required Future<Map<String, dynamic>> Function(
      String token,
      Map<String, dynamic> fields,
    )
    createFetcher,
    required Future<Map<String, dynamic>> Function(
      String teamId,
      String token,
      Map<String, dynamic> fields,
    )
    updateFetcher,
    required Future<void> Function(String teamId, String token) deleteFetcher,
  }) =>
      MaintenanceTeamDirectory._(
        firebaseAvailable: firebaseAvailable,
        tokenProvider: tokenProvider,
        listFetcher: listFetcher,
        createFetcher: createFetcher,
        updateFetcher: updateFetcher,
        deleteFetcher: deleteFetcher,
      );

  final bool Function() _firebaseAvailable;
  final Future<String?> Function() _tokenProvider;
  final Future<List<Map<String, dynamic>>> Function(String token) _listFetcher;
  final Future<Map<String, dynamic>> Function(
    String token,
    Map<String, dynamic> fields,
  )
  _createFetcher;
  final Future<Map<String, dynamic>> Function(
    String teamId,
    String token,
    Map<String, dynamic> fields,
  )
  _updateFetcher;
  final Future<void> Function(String teamId, String token) _deleteFetcher;

  /// Starts unavailable rather than showing preview records as if they were
  /// a successful production response. Tests may explicitly seed this
  /// notifier with fixtures.
  final ValueNotifier<List<MaintenanceTeam>> teams = ValueNotifier(
    const <MaintenanceTeam>[],
  );

  final ValueNotifier<MaintenanceTeamDirectoryState> state = ValueNotifier(
    MaintenanceTeamDirectoryState.unavailable,
  );

  bool get canRefreshForAdmin => _firebaseAvailable();

  bool _hasConfirmedAdminSnapshot = false;

  /// Last-started Admin list read wins. A confirmed mutation advances this
  /// revision so an earlier (or in-flight) read cannot restore stale rows.
  int _listReadRevision = 0;

  /// Per-team revisions keep overlapping updates/deletes deterministic without
  /// making independent teams wait for one another.
  final Map<String, int> _teamMutationRevisions = <String, int>{};

  /// This sequence is deliberately independent of [_teamMutationRevisions].
  /// The active map is cleaned up when work completes, so deriving a new
  /// revision from it could reuse an older value while an earlier request is
  /// still in flight. A directory-wide sequence keeps each mutation identity
  /// unique for the lifetime of this directory, including after invalidation.
  int _nextTeamMutationRevision = 0;

  /// Invalidates every pending request when a shared session owner adopts the
  /// Admin-owned [invalidateAndClear] integration.
  int _sessionGeneration = 0;

  int _nextTeamNumber = 2;

  bool _isCurrentListRead(int revision, int sessionGeneration) =>
      revision == _listReadRevision && sessionGeneration == _sessionGeneration;

  bool _isCurrentTeamMutation(
    String teamId,
    int revision,
    int sessionGeneration,
  ) =>
      _teamMutationRevisions[teamId] == revision &&
      sessionGeneration == _sessionGeneration;

  int _startTeamMutation(String teamId) {
    final revision = ++_nextTeamMutationRevision;
    _teamMutationRevisions[teamId] = revision;
    return revision;
  }

  @visibleForTesting
  int get activeTeamMutationCount => _teamMutationRevisions.length;

  void _finishTeamMutation(String teamId, int revision) {
    if (_teamMutationRevisions[teamId] == revision) {
      _teamMutationRevisions.remove(teamId);
    }
  }

  void _invalidateListReads() {
    _listReadRevision++;
  }

  StateError _supersededMutationError(String operation, String teamId) =>
      StateError(
        '$operation for $teamId was confirmed by the server but superseded '
        'locally by a newer request. Reload team data before continuing.',
      );

  /// Intended for shared session/logout integration. It is deliberately
  /// local-only: it invalidates pending requests but does not claim to revoke
  /// server authorization or cancel a request already accepted by the server.
  void invalidateAndClear() {
    _sessionGeneration++;
    _invalidateListReads();
    _teamMutationRevisions.clear();
    teams.value = const <MaintenanceTeam>[];
    _hasConfirmedAdminSnapshot = false;
    state.value = MaintenanceTeamDirectoryState.unavailable;
  }

  Future<void> refreshForAdmin() async {
    final revision = ++_listReadRevision;
    final sessionGeneration = _sessionGeneration;
    if (!canRefreshForAdmin) {
      if (_isCurrentListRead(revision, sessionGeneration)) {
        state.value = MaintenanceTeamDirectoryState.unavailable;
      }
      throw StateError('Maintenance team data is unavailable without Firebase');
    }
    state.value = MaintenanceTeamDirectoryState.loading;
    try {
      final token = await _tokenProvider();
      if (!_isCurrentListRead(revision, sessionGeneration)) return;
      if (token == null) throw StateError('A signed-in Admin is required');
      final rows = await _listFetcher(token);
      if (!_isCurrentListRead(revision, sessionGeneration)) return;
      teams.value = rows.map(MaintenanceTeam.fromApi).toList();
      _hasConfirmedAdminSnapshot = true;
      state.value = MaintenanceTeamDirectoryState.loaded;
    } catch (_) {
      if (!_isCurrentListRead(revision, sessionGeneration)) rethrow;
      // Keep a prior confirmed snapshot visible, but never relabel a failed
      // request as loaded or replace it with preview data.
      state.value = _hasConfirmedAdminSnapshot
          ? MaintenanceTeamDirectoryState.failed
          : MaintenanceTeamDirectoryState.unavailable;
      rethrow;
    }
  }

  Future<void> refreshForMunicipal() async {
    final revision = ++_listReadRevision;
    final sessionGeneration = _sessionGeneration;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (!_isCurrentListRead(revision, sessionGeneration)) return;
    if (token == null) throw StateError('A signed-in officer is required');
    final rows = await ApiClient.instance.listMunicipalMaintenanceOptions(
      idToken: token,
    );
    if (!_isCurrentListRead(revision, sessionGeneration)) return;
    teams.value = [
      for (final row in rows)
        if (_assemblyFromApi(row) != null) MaintenanceTeam.fromApi(row),
    ];
  }

  Assembly? _assemblyFromApi(Map<String, dynamic> row) {
    final regionName = row['region'] as String?;
    final assemblyName = row['assembly'] as String?;
    final region = Region.values.cast<Region?>().firstWhere(
      (item) => item?.name == regionName,
      orElse: () => null,
    );
    if (region == null || assemblyName == null) return null;
    return (ghanaAssemblies[region] ?? const []).cast<Assembly?>().firstWhere(
      (item) => item?.name == assemblyName,
      orElse: () => null,
    );
  }

  MaintenanceTeam createTeam({
    required String name,
    required Assembly assembly,
    List<String> memberUserIds = const [],
    String? leadUserId,
  }) {
    final team = MaintenanceTeam(
      teamId: 'TEAM-${(_nextTeamNumber++).toString().padLeft(4, '0')}',
      name: name.trim(),
      region: assembly.region,
      assembly: assembly,
      memberUserIds: List.unmodifiable(memberUserIds),
      leadUserId: leadUserId,
      createdAt: DateTime.now(),
    );
    teams.value = [
      _withoutMembersAlreadyAssigned(team),
      ..._removeMembersFromOtherTeams(memberUserIds),
    ];
    return team;
  }

  Future<MaintenanceTeam> createTeamOnServer({
    required String name,
    required Assembly assembly,
    List<String> memberUserIds = const [],
    String? leadUserId,
  }) async {
    final sessionGeneration = _sessionGeneration;
    if (!_firebaseAvailable()) {
      throw StateError('Maintenance team creation is unavailable without Firebase');
    }
    final token = await _tokenProvider();
    if (sessionGeneration != _sessionGeneration) {
      throw StateError('Maintenance team creation was invalidated by a session change');
    }
    if (token == null) throw StateError('A signed-in Admin is required');
    final row = await _createFetcher(token, {
      'name': name,
      'region': assembly.region.name,
      'assembly': assembly.name,
      'memberUserIds': memberUserIds,
      'leadUserId': leadUserId,
    });
    final team = MaintenanceTeam.fromApi(row);
    // The server accepted this create. Invalidate older list reads even if a
    // later session change prevents local publication of the returned row.
    _invalidateListReads();
    if (sessionGeneration != _sessionGeneration) {
      throw StateError('Maintenance team creation was invalidated by a session change');
    }
    teams.value = [team, ...teams.value];
    _hasConfirmedAdminSnapshot = true;
    state.value = MaintenanceTeamDirectoryState.loaded;
    return team;
  }

  void updateTeam(MaintenanceTeam updated) {
    final cleaned = _withoutMembersAlreadyAssigned(updated);
    teams.value = [
      for (final team in _removeMembersFromOtherTeams(
        cleaned.memberUserIds,
        exceptTeamId: cleaned.teamId,
      ))
        if (team.teamId == cleaned.teamId) cleaned else team,
    ];
  }

  Future<void> updateTeamOnServer(MaintenanceTeam updated) async {
    final sessionGeneration = _sessionGeneration;
    final mutationRevision = _startTeamMutation(updated.teamId);
    if (!_firebaseAvailable()) {
      _finishTeamMutation(updated.teamId, mutationRevision);
      throw StateError('Maintenance team updates are unavailable without Firebase');
    }
    try {
      final token = await _tokenProvider();
      if (!_isCurrentTeamMutation(
        updated.teamId,
        mutationRevision,
        sessionGeneration,
      )) {
        throw StateError('Team update was superseded before it could be sent');
      }
      if (token == null) throw StateError('A signed-in Admin is required');
      final row = await _updateFetcher(updated.teamId, token, {
        'name': updated.name,
        'region': updated.region.name,
        'assembly': updated.assembly.name,
        'memberUserIds': updated.memberUserIds,
        'leadUserId': updated.leadUserId,
      });
      final confirmed = MaintenanceTeam.fromApi(row);
      // The response proves the server accepted a mutation. It may still be
      // superseded locally by a newer same-team request, but all older list
      // reads must be discarded either way.
      _invalidateListReads();
      if (!_isCurrentTeamMutation(
        updated.teamId,
        mutationRevision,
        sessionGeneration,
      )) {
        throw _supersededMutationError('Team update', updated.teamId);
      }
      updateTeam(confirmed);
      _hasConfirmedAdminSnapshot = true;
      state.value = MaintenanceTeamDirectoryState.loaded;
    } finally {
      _finishTeamMutation(updated.teamId, mutationRevision);
    }
  }

  void addMember(MaintenanceTeam team, String userId) {
    // Notifying the affected maintenance user now happens server-side —
    // updateTeamOnServer's real PATCH diffs old vs. new membership and
    // sends a push (see adminTeams.js's PATCH /teams/:id) — this local
    // mutation is just the optimistic/offline-mock path.
    updateTeam(
      team.copyWith(memberUserIds: {...team.memberUserIds, userId}.toList()),
    );
  }

  void removeMember(MaintenanceTeam team, String userId) {
    updateTeam(
      team.copyWith(
        memberUserIds: [
          for (final memberId in team.memberUserIds)
            if (memberId != userId) memberId,
        ],
        // A lead who's no longer a member can't stay the lead — leaves the
        // team without one rather than pointing at someone who's left it.
        leadUserId: team.leadUserId == userId ? null : team.leadUserId,
      ),
    );
  }

  void deleteTeam(MaintenanceTeam team) {
    teams.value = [
      for (final current in teams.value)
        if (current.teamId != team.teamId) current,
    ];
  }

  Future<void> deleteTeamOnServer(MaintenanceTeam team) async {
    final sessionGeneration = _sessionGeneration;
    final mutationRevision = _startTeamMutation(team.teamId);
    if (!_firebaseAvailable()) {
      _finishTeamMutation(team.teamId, mutationRevision);
      throw StateError('Maintenance team deletion is unavailable without Firebase');
    }
    try {
      final token = await _tokenProvider();
      if (!_isCurrentTeamMutation(
        team.teamId,
        mutationRevision,
        sessionGeneration,
      )) {
        throw StateError('Team deletion was superseded before it could be sent');
      }
      if (token == null) throw StateError('A signed-in Admin is required');
      await _deleteFetcher(team.teamId, token);
      _invalidateListReads();
      if (!_isCurrentTeamMutation(
        team.teamId,
        mutationRevision,
        sessionGeneration,
      )) {
        throw _supersededMutationError('Team deletion', team.teamId);
      }
      deleteTeam(team);
      _hasConfirmedAdminSnapshot = true;
      state.value = MaintenanceTeamDirectoryState.loaded;
    } finally {
      _finishTeamMutation(team.teamId, mutationRevision);
    }
  }

  MaintenanceTeam? teamById(String teamId) {
    for (final team in teams.value) {
      if (team.teamId == teamId) return team;
    }
    return null;
  }

  MaintenanceTeam _withoutMembersAlreadyAssigned(MaintenanceTeam team) {
    return team.copyWith(memberUserIds: List.unmodifiable(team.memberUserIds));
  }

  List<MaintenanceTeam> _removeMembersFromOtherTeams(
    List<String> memberUserIds, {
    String? exceptTeamId,
  }) {
    final movedMembers = memberUserIds.toSet();
    return [
      for (final team in teams.value)
        if (team.teamId == exceptTeamId)
          team
        else
          team.copyWith(
            memberUserIds: [
              for (final memberId in team.memberUserIds)
                if (!movedMembers.contains(memberId)) memberId,
            ],
          ),
    ];
  }
}
