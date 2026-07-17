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
  });

  final String teamId;
  final String name;
  final Region region;
  final Assembly assembly;
  final List<String> memberUserIds;
  final DateTime createdAt;

  MaintenanceTeam copyWith({
    String? name,
    Assembly? assembly,
    List<String>? memberUserIds,
  }) {
    final nextAssembly = assembly ?? this.assembly;
    return MaintenanceTeam(
      teamId: teamId,
      name: name ?? this.name,
      region: nextAssembly.region,
      assembly: nextAssembly,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      createdAt: createdAt,
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
      memberUserIds: const ['CV-USER-0104'],
      createdAt: DateTime(2025, 7, 4),
    ),
  ];
}
