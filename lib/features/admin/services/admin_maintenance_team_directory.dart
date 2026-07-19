import 'package:flutter/foundation.dart';

import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../services/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/admin_maintenance_team_data.dart';

class MaintenanceTeamDirectory {
  MaintenanceTeamDirectory._();

  static final MaintenanceTeamDirectory instance = MaintenanceTeamDirectory._();

  final ValueNotifier<List<MaintenanceTeam>> teams = ValueNotifier(
    mockMaintenanceTeams(),
  );

  int _nextTeamNumber = 2;

  Future<void> refreshForMunicipal() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in officer is required');
    final rows = await ApiClient.instance.listMunicipalMaintenanceOptions(
      idToken: token,
    );
    teams.value = [
      for (final row in rows)
        if (_assemblyFromApi(row) case final assembly?)
          MaintenanceTeam(
            teamId: row['id'] as String,
            name: row['name'] as String,
            region: assembly.region,
            assembly: assembly,
            memberUserIds: (row['members'] as List? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map((member) => member['publicId'] as String)
                .toList(),
            createdAt: DateTime.now(),
          ),
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

  void addMember(MaintenanceTeam team, String userId) {
    // TODO(notifications): Notify the maintenance user when team
    // membership changes once the app has a real notification system.
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
