import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';

class MaintenanceTeam {
  const MaintenanceTeam({
    required this.teamId,
    required this.name,
    required this.region,
    required this.assembly,
    required this.memberUserIds,
    required this.createdAt,
    this.leadUserId,
  });

  final String teamId;
  final String name;
  final Region region;
  final Assembly assembly;
  final List<String> memberUserIds;
  final DateTime createdAt;

  /// The one member (an [AdminUserItem.userId]) allowed to submit
  /// completion evidence on this team's tasks — `null` means no lead is
  /// set, in which case any member can submit. A Municipal Officer assigns
  /// a whole team to a task (not individual members), so without a lead
  /// every member would otherwise be equally able to submit, which is fine
  /// for a 1-person team but ambiguous once a team has several.
  final String? leadUserId;

  static const _unset = Object();

  /// [leadUserId] takes `_unset` (via the default) to mean "leave
  /// unchanged" — pass an explicit `null` to actually clear the lead,
  /// rather than `null` being indistinguishable from "not passed" the way
  /// a plain nullable parameter would make it.
  MaintenanceTeam copyWith({
    String? name,
    Assembly? assembly,
    List<String>? memberUserIds,
    Object? leadUserId = _unset,
  }) {
    final nextAssembly = assembly ?? this.assembly;
    return MaintenanceTeam(
      teamId: teamId,
      name: name ?? this.name,
      region: nextAssembly.region,
      assembly: nextAssembly,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      createdAt: createdAt,
      leadUserId: identical(leadUserId, _unset)
          ? this.leadUserId
          : leadUserId as String?,
    );
  }

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final normalized = query.trim().toLowerCase();
    return name.toLowerCase().contains(normalized) ||
        assembly.fullName.toLowerCase().contains(normalized) ||
        region.label.toLowerCase().contains(normalized);
  }
}

List<MaintenanceTeam> mockMaintenanceTeams() {
  return [
    MaintenanceTeam(
      teamId: 'TEAM-0001',
      name: 'Kumasi Central Crew',
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
      memberUserIds: const ['CV-USER-0104', 'CV-USER-0110'],
      createdAt: DateTime(2025, 7, 4),
      leadUserId: 'CV-USER-0104',
    ),
  ];
}
