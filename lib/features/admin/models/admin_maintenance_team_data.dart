import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
import '../../../models/region.dart';
import '../../../models/team_availability.dart';

class MaintenanceTeam {
  const MaintenanceTeam({
    required this.teamId,
    required this.name,
    required this.region,
    required this.assembly,
    required this.memberUserIds,
    required this.createdAt,
    this.leadUserId,
    this.leadName,
    this.leadPhone,
    this.availability = TeamAvailability.available,
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

  /// Denormalized display fields for [leadUserId] — sourced fresh from the
  /// backend's `lead` object on every fetch (see `MaintenanceTeam.fromApi`),
  /// never derived via a separate directory lookup. Null whenever
  /// [leadUserId] is null.
  final String? leadName;
  final String? leadPhone;

  /// Self-reported by the team lead from Maintenance's own Profile screen
  /// (see `lib/features/maintenance/screens/profile_screen.dart`) — this
  /// is what Municipal's Assign Team actually reads/filters by now,
  /// instead of a fixed-forever mock value.
  final TeamAvailability availability;

  factory MaintenanceTeam.fromApi(Map<String, dynamic> json) {
    final region = Region.values.firstWhere(
      (item) => item.name == json['region'],
    );
    final assembly = assemblyNamed(region, json['assembly'] as String);
    final availability = switch (json['availability']) {
      'BUSY' => TeamAvailability.busy,
      'OFF_DUTY' => TeamAvailability.offDuty,
      _ => TeamAvailability.available,
    };
    return MaintenanceTeam(
      teamId: json['id'] as String,
      name: json['name'] as String,
      region: region,
      assembly: assembly,
      memberUserIds:
          (json['memberUserIds'] as List?)?.whereType<String>().toList() ??
          (json['members'] as List? ?? const <dynamic>[])
              .whereType<Map<String, dynamic>>()
              .map((member) => member['publicId'] as String)
              .toList(),
      leadUserId: json['leadUserId'] as String?,
      leadName: (json['lead'] as Map<String, dynamic>?)?['fullName'] as String?,
      leadPhone: (json['lead'] as Map<String, dynamic>?)?['phone'] as String?,
      availability: availability,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

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
    TeamAvailability? availability,
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
      // leadName/leadPhone are only ever sourced fresh from a real fetch
      // (see fromApi) — if the lead is changing here, stale contact info
      // pointing at the old lead would be worse than none, so clear it
      // until the next refresh re-populates it for real.
      leadName: identical(leadUserId, _unset) ? leadName : null,
      leadPhone: identical(leadUserId, _unset) ? leadPhone : null,
      availability: availability ?? this.availability,
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
      memberUserIds: const ['MNT-000004', 'MNT-000010'],
      createdAt: DateTime(2025, 7, 4),
      leadUserId: 'MNT-000004',
      leadName: 'Yaw Asare',
      leadPhone: '+233 27 777 8888',
    ),
  ];
}
