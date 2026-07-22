/// Data backing MIN-006 Ministry Profile.
class MinistryProfileData {
  const MinistryProfileData({
    required this.name,
    required this.role,
    required this.ministry,
    required this.email,
    required this.phone,
    required this.metadataBadges,
    this.publicId = 'MIN-000001',
  });

  final String name;

  /// e.g. "Read-only supervisor" — shown as a pill under [name].
  final String role;
  final String ministry;
  final String email;
  final String phone;

  /// "Supervisor" / "Read-only module" / "Analytics access" — read-only
  /// tags in the Account Metadata card, not user-editable.
  final List<String> metadataBadges;
  final String publicId;

  MinistryProfileData copyWith({String? name, String? email, String? phone}) {
    return MinistryProfileData(
      name: name ?? this.name,
      role: role,
      ministry: ministry,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      metadataBadges: metadataBadges,
      publicId: publicId,
    );
  }

  /// Placeholder content matching the approved MIN-006 design, used until
  /// the Cloud Firestore-backed profile service (Issue 05 dependency) is
  /// wired up.
  static MinistryProfileData mock() {
    return const MinistryProfileData(
      name: 'Ministry Supervisor',
      role: 'Read-only supervisor',
      ministry: 'Public Works Ministry',
      email: 'supervisor@ministry.gov',
      phone: '+233 20 000 0000',
      metadataBadges: ['Supervisor', 'Read-only module', 'Analytics access'],
    );
  }
}
