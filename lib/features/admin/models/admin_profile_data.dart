/// The outcome of a "Save Changes" attempt on the editable fields — same
/// shape and same reasoning as `SystemSettingsSaveState`: kept out of the
/// screen's own load-state enum since these are transient results of an
/// in-place interaction, and [failed] has no reachable trigger through
/// normal interaction (no backend to fail a save against), so it's
/// preview-only via `AdminProfileScreen.initialSaveState`.
enum AdminProfileSaveState { idle, saving, saved, failed, validationError }

/// The account details shown on ADM-008 Admin Profile. Only [fullName] and
/// [department] are ever editable — [email] and [phone] are admin-set
/// credentials (changing either means a real identity change: a different
/// sign-in email, a different verified number), so they render read-only
/// and go through an administrator instead; [adminId] and everything
/// outside "Administrator Information" stay untouched too. The rest
/// exists so the whole record can be tracked and dirty-checked as one
/// value.
class AdminProfileData {
  const AdminProfileData({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.adminId,
    required this.twoFactorEnabled,
    required this.lastActivity,
    required this.governanceChecklistPercent,
    required this.administrativeScope,
    required this.governanceLevel,
  });

  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String adminId;
  final bool twoFactorEnabled;
  final DateTime lastActivity;
  final int governanceChecklistPercent;

  /// Which modules this admin account can reach — e.g. ["Users", "Roles",
  /// "Settings"]. Distinct from `AdminTier.grantedPermissionLabels` (a
  /// different vocabulary for a different job — what a tier grants versus
  /// which modules an account can open) and free-standing rather than
  /// tied to `AdminTier` here, since this screen shows one fixed account's
  /// own scope, not a tier comparison.
  final List<String> administrativeScope;
  final String governanceLevel;

  AdminProfileData copyWith({String? fullName, String? department}) {
    return AdminProfileData(
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone,
      department: department ?? this.department,
      adminId: adminId,
      twoFactorEnabled: twoFactorEnabled,
      lastActivity: lastActivity,
      governanceChecklistPercent: governanceChecklistPercent,
      administrativeScope: administrativeScope,
      governanceLevel: governanceLevel,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminProfileData &&
      other.fullName == fullName &&
      other.email == email &&
      other.phone == phone &&
      other.department == department &&
      other.adminId == adminId;

  @override
  int get hashCode =>
      Object.hash(fullName, email, phone, department, adminId);
}

/// Placeholder content matching the approved ADM-008 design, used until a
/// real account service is wired up.
AdminProfileData mockAdminProfile() {
  return AdminProfileData(
    fullName: 'System Administrator',
    email: 'admin@civicvoice.gov',
    phone: '+233 24 111 2222',
    department: 'Platform Administration',
    adminId: 'ADM-001',
    twoFactorEnabled: true,
    lastActivity: DateTime.now().subtract(const Duration(hours: 1)),
    governanceChecklistPercent: 92,
    administrativeScope: const ['Users', 'Roles', 'Settings'],
    governanceLevel: 'Approved administrator',
  );
}
