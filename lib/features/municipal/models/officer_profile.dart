/// The signed-in municipal officer's own account details, shown on MUN-009
/// Municipal Profile.
class OfficerProfile {
  const OfficerProfile({
    required this.name,
    required this.role,
    required this.employeeId,
    required this.verifiedOfficial,
    required this.phone,
    required this.department,
    required this.region,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String employeeId;
  final bool verifiedOfficial;

  final String phone;

  /// Assigned by an administrator, not self-service — shown read-only on
  /// the edit form rather than as an editable field.
  final String department;
  final String region;
  final String? avatarUrl;

  OfficerProfile copyWith({String? name, String? phone, String? avatarUrl}) {
    return OfficerProfile(
      name: name ?? this.name,
      role: role,
      employeeId: employeeId,
      verifiedOfficial: verifiedOfficial,
      phone: phone ?? this.phone,
      department: department,
      region: region,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  /// Placeholder content matching the approved MUN-009 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  static OfficerProfile mock() {
    return const OfficerProfile(
      name: 'Alex Johnston',
      role: 'Senior Municipal Coordinator',
      employeeId: 'MUN-000002',
      verifiedOfficial: true,
      phone: '+233 24 555 0142',
      department: 'Springfield District',
      region: 'Greater Accra',
    );
  }
}
