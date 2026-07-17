import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';
import '../../../models/region.dart';
import 'admin_role_management_data.dart';

/// Quick-filter chips — [all]'s the default; [admins]/[staff] split by
/// [AppRole], [inactive] by [AdminUserStatus]. Matches the approved frame's
/// chip row exactly. Citizens fall under neither [admins] nor [staff] (they
/// aren't platform staff) — only [all] and, if flagged, [inactive] surface
/// them.
enum AdminUserFilter {
  all('All'),
  admins('Admins'),
  staff('Staff'),
  inactive('Inactive');

  const AdminUserFilter(this.label);

  final String label;

  static const _staffRoles = {
    AppRole.municipalOfficer,
    AppRole.maintenanceTeam,
    AppRole.ministrySupervisor,
  };

  bool matches(AdminUserItem user) => switch (this) {
    AdminUserFilter.all => true,
    AdminUserFilter.admins => user.role == AppRole.systemAdministrator,
    AdminUserFilter.staff => _staffRoles.contains(user.role),
    AdminUserFilter.inactive => user.status == AdminUserStatus.inactive,
  };
}

/// [review] doubles as "new staff account awaiting approval" and "citizen
/// account flagged for review" (e.g. a pattern of false reports) — both are
/// just "an admin needs to look at this account," and inventing a fourth,
/// narrower status for the citizen case wasn't worth the extra complexity.
enum AdminUserStatus {
  active('Active', AppColors.statusResolved),
  review('Review', AppColors.warning),
  inactive('Inactive', AppColors.error);

  const AdminUserStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// One row in the User Management list — also the record ADM-003 User
/// Details drills into, so it carries a few fields (`userId`, sign-in/
/// creation timestamps, `adminTier`) the list cards themselves never
/// display but the detail screen does.
class AdminUserItem {
  const AdminUserItem({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.userId,
    required this.lastSignIn,
    required this.accountCreated,
    this.adminTier,
    this.region,
  });

  final String name;
  final String email;
  final AppRole role;
  final AdminUserStatus status;
  final String userId;
  final DateTime lastSignIn;
  final DateTime accountCreated;

  /// Only meaningful when [role] is [AppRole.systemAdministrator] — every
  /// other role has no admin-team privilege tier to hold. See
  /// [AdminTier]'s own doc comment for why this exists.
  final AdminTier? adminTier;

  /// The jurisdiction this account is scoped to — required for
  /// [AppRole.municipalOfficer] and [AppRole.maintenanceTeam] accounts
  /// (they act on reports filed within one region), null for
  /// [AppRole.systemAdministrator] and [AppRole.ministrySupervisor] (both
  /// national-scope roles) and for [AppRole.citizen] (citizens aren't
  /// region-provisioned; their reports carry their own region instead).
  final Region? region;

  /// Whether [role] is one of the two region-scoped staff roles — the
  /// single source of truth [AdminUserItem.copyWith], the details form, and
  /// the create-user form all key off, so "which roles need a region"
  /// only has to be decided in one place.
  static bool roleRequiresRegion(AppRole role) =>
      role == AppRole.municipalOfficer || role == AppRole.maintenanceTeam;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase();
  }

  /// Illustrative capabilities for [role] — descriptive only (this app has
  /// no backend to enforce any of it), matching [AdminTier.grantedPermissionLabels]'s
  /// own "documentation, not enforcement" framing. Admin accounts draw
  /// theirs from [adminTier] instead of a fixed per-role list, since that's
  /// the one role where the granted set actually varies by account.
  List<String> get permissionSummary => switch (role) {
    AppRole.citizen => const [
      'Submit reports',
      'View own reports',
      'Read notifications',
    ],
    AppRole.municipalOfficer => const [
      'Verify reports',
      'Assign reports',
      'View municipal dashboard',
    ],
    AppRole.maintenanceTeam => const [
      'Submit reports',
      'Update reports',
      'View assigned zone',
      'Read notifications',
    ],
    AppRole.ministrySupervisor => const [
      'View analytics',
      'Export reports',
      'Read notifications',
    ],
    AppRole.systemAdministrator =>
      adminTier?.grantedPermissionLabels ?? const [],
  };

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || email.toLowerCase().contains(q);
  }

  AdminUserItem copyWith({
    AppRole? role,
    AdminUserStatus? status,
    AdminTier? adminTier,
    Region? region,
  }) {
    final effectiveRole = role ?? this.role;
    return AdminUserItem(
      name: name,
      email: email,
      role: effectiveRole,
      status: status ?? this.status,
      userId: userId,
      lastSignIn: lastSignIn,
      accountCreated: accountCreated,
      adminTier: effectiveRole == AppRole.systemAdministrator
          ? (adminTier ?? this.adminTier ?? AdminTier.admin)
          : (role == null ? this.adminTier : null),
      region: roleRequiresRegion(effectiveRole)
          ? (region ?? this.region)
          : (role == null ? this.region : null),
    );
  }
}

/// Placeholder content matching the approved ADM-002 design, used until the
/// Cloud Firestore-backed user service (Issue 05 dependency) is wired up.
///
/// The approved frame's four users carried made-up roles ("Moderator",
/// "Support", "Auditor") that don't correspond to anything in CivicVoice's
/// actual five-role system — replaced with real [AppRole]s. Also adds a
/// Citizen entry: admins don't provision citizen accounts (citizens
/// self-register), but they can still moderate one — flagging or
/// deactivating an account with a pattern of false reports, for instance —
/// so citizens belong in this list even though "Admins"/"Staff" don't
/// claim them.
List<AdminUserItem> mockAdminUsers() {
  final now = DateTime.now();
  return [
    AdminUserItem(
      name: 'Ama Boateng',
      email: 'admin@civicvoice.gov',
      role: AppRole.systemAdministrator,
      status: AdminUserStatus.inactive,
      userId: 'CV-USER-0101',
      lastSignIn: DateTime(2025, 12, 2, 16, 5),
      accountCreated: DateTime(2025, 1, 12),
      adminTier: AdminTier.superAdmin,
    ),
    AdminUserItem(
      name: 'Kojo Mensah',
      email: 'kojo.mensah@civicvoice.gov',
      role: AppRole.municipalOfficer,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0102',
      lastSignIn: now.subtract(const Duration(hours: 3)),
      accountCreated: DateTime(2025, 2, 3),
      region: Region.greaterAccra,
    ),
    AdminUserItem(
      name: 'Esi Owusu',
      email: 'esi.owusu@civicvoice.gov',
      role: AppRole.ministrySupervisor,
      status: AdminUserStatus.review,
      userId: 'CV-USER-0103',
      lastSignIn: DateTime(2025, 11, 28, 9, 30),
      accountCreated: DateTime(2025, 3, 18),
    ),
    AdminUserItem(
      name: 'Yaw Asare',
      email: 'yaw.asare@civicvoice.gov',
      role: AppRole.maintenanceTeam,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0104',
      lastSignIn: now.subtract(const Duration(hours: 8, minutes: 40)),
      accountCreated: DateTime(2025, 1, 12),
      region: Region.ashanti,
    ),
    AdminUserItem(
      name: 'Kwame Nyarko',
      email: 'kwame.nyarko@gmail.com',
      role: AppRole.citizen,
      status: AdminUserStatus.review,
      userId: 'CV-USER-0105',
      lastSignIn: DateTime(2025, 11, 20, 14, 12),
      accountCreated: DateTime(2025, 6, 9),
    ),
    AdminUserItem(
      name: 'Genevieve Amadapah',
      email: 'genevieve.amadapah@civicvoice.gov',
      role: AppRole.citizen,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0106',
      lastSignIn: now.subtract(const Duration(days: 1, hours: 2)),
      accountCreated: DateTime(2025, 7, 22),
    ),
  ];
}
