import 'package:flutter/foundation.dart';

import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/admin_maintenance_team_data.dart';

class MaintenanceTeamDirectory {
  MaintenanceTeamDirectory._();

  static final MaintenanceTeamDirectory instance = MaintenanceTeamDirectory._();

  final ValueNotifier<List<MaintenanceTeam>> teams = ValueNotifier(
    mockMaintenanceTeams(),
  );

  int _nextTeamNumber = 2;

  Future<void> refreshForAdmin() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final rows = await ApiClient.instance.listMaintenanceTeams(idToken: token);
    teams.value = rows.map(MaintenanceTeam.fromApi).toList();
  }

  Future<void> refreshForMunicipal() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in officer is required');
    final rows = await ApiClient.instance.listMunicipalMaintenanceOptions(
      idToken: token,
    );
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
    if (Firebase.apps.isEmpty) {
      return createTeam(
        name: name,
        assembly: assembly,
        memberUserIds: memberUserIds,
        leadUserId: leadUserId,
      );
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final row = await ApiClient.instance.createMaintenanceTeam(
      idToken: token,
      fields: {
        'name': name,
        'region': assembly.region.name,
        'assembly': assembly.name,
        'memberUserIds': memberUserIds,
        'leadUserId': leadUserId,
      },
    );
    final team = MaintenanceTeam.fromApi(row);
    teams.value = [team, ...teams.value];
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
    if (Firebase.apps.isEmpty) {
      updateTeam(updated);
      return;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final row = await ApiClient.instance.updateMaintenanceTeam(
      updated.teamId,
      idToken: token,
      fields: {
        'name': updated.name,
        'region': updated.region.name,
        'assembly': updated.assembly.name,
        'memberUserIds': updated.memberUserIds,
        'leadUserId': updated.leadUserId,
      },
    );
    updateTeam(MaintenanceTeam.fromApi(row));
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
    if (Firebase.apps.isNotEmpty) {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('A signed-in Admin is required');
      await ApiClient.instance.deleteMaintenanceTeam(
        team.teamId,
        idToken: token,
      );
    }
    deleteTeam(team);
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
