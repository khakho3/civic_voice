/// The signed-in municipal officer's own account details, shown on MUN-009
/// Municipal Profile.
class OfficerProfile {
  const OfficerProfile({
    required this.name,
    required this.role,
    required this.employeeId,
    required this.verifiedOfficial,
    required this.email,
    required this.phone,
    required this.department,
    required this.reportsTo,
    required this.passwordLastUpdatedLabel,
  });

  final String name;
  final String role;
  final String employeeId;
  final bool verifiedOfficial;

  final String email;
  final String phone;

  /// Assigned by an administrator, not self-service — shown read-only on
  /// the edit form rather than as an editable field.
  final String department;
  final String reportsTo;

  final String passwordLastUpdatedLabel;

  OfficerProfile copyWith({String? name, String? email, String? phone}) {
    return OfficerProfile(
      name: name ?? this.name,
      role: role,
      employeeId: employeeId,
      verifiedOfficial: verifiedOfficial,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department,
      reportsTo: reportsTo,
      passwordLastUpdatedLabel: passwordLastUpdatedLabel,
    );
  }

  /// Placeholder content matching the approved MUN-009 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  static OfficerProfile mock() {
    return const OfficerProfile(
      name: 'Alex Johnston',
      role: 'Senior Municipal Coordinator',
      employeeId: 'MC-4092',
      verifiedOfficial: true,
      email: 'alex.johnston@city.gov',
      phone: '+233 24 555 0142',
      department: 'Urban Planning & Dev',
      reportsTo: 'Director M. Chen',
      passwordLastUpdatedLabel: 'Last updated 3 months ago',
    );
  }
}
