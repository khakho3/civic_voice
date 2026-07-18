import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/ghana_assemblies_data.dart';
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
    this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.userId,
    required this.lastSignIn,
    required this.accountCreated,
    this.adminTier,
    this.region,
    this.assembly,
  });

  final String name;

  /// Not collected on account creation yet — there's no SMTP integration to
  /// send anything to it, so asking for it up front would just be data
  /// collected for its own sake. Existing accounts created before this
  /// still carry one; new ones simply have none until that changes.
  final String? email;
  final String phone;
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
  /// (they act on reports filed within one region), and for a
  /// [AppRole.systemAdministrator] account holding [AdminTier.admin] (one
  /// per assembly — see [roleRequiresAssembly]). Null for
  /// [AppRole.ministrySupervisor] (national-scope) and for
  /// [AppRole.citizen] (citizens aren't region-provisioned; their reports
  /// carry their own region instead).
  final Region? region;

  /// The specific Metropolitan/Municipal/District Assembly this account is
  /// scoped to, one level more specific than [region] — see
  /// [roleRequiresAssembly].
  final Assembly? assembly;

  /// Whether [role] is one of the two region-scoped staff roles — the
  /// single source of truth [AdminUserItem.copyWith], the details form, and
  /// the create-user form all key off, so "which roles need a region"
  /// only has to be decided in one place.
  static bool roleRequiresRegion(AppRole role) =>
      role == AppRole.municipalOfficer || role == AppRole.maintenanceTeam;

  /// Whether an account of [role] (and, for System Administrator, [tier])
  /// needs an [assembly] — true for the two region-scoped staff roles, and
  /// for a System Administrator holding [AdminTier.admin] (one per
  /// assembly; [AdminTier.superAdmin] is national and needs neither region
  /// nor assembly).
  static bool roleRequiresAssembly(AppRole role, [AdminTier? tier]) =>
      roleRequiresRegion(role) ||
      (role == AppRole.systemAdministrator && tier == AdminTier.admin);

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
    return name.toLowerCase().contains(q) ||
        phone.contains(q) ||
        (email?.toLowerCase().contains(q) ?? false);
  }

  AdminUserItem copyWith({
    AppRole? role,
    AdminUserStatus? status,
    AdminTier? adminTier,
    Region? region,
    Assembly? assembly,
  }) {
    final effectiveRole = role ?? this.role;
    final effectiveTier = effectiveRole == AppRole.systemAdministrator
        ? (adminTier ?? this.adminTier ?? AdminTier.admin)
        : null;
    final needsAssembly = roleRequiresAssembly(effectiveRole, effectiveTier);
    return AdminUserItem(
      name: name,
      email: email,
      phone: phone,
      role: effectiveRole,
      status: status ?? this.status,
      userId: userId,
      lastSignIn: lastSignIn,
      accountCreated: accountCreated,
      adminTier: effectiveTier,
      region: (roleRequiresRegion(effectiveRole) || needsAssembly)
          ? (region ?? this.region)
          : (role == null ? this.region : null),
      assembly: needsAssembly
          ? (assembly ?? this.assembly)
          : (role == null ? this.assembly : null),
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
      phone: '+233 24 111 2222',
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
      phone: '+233 24 333 4444',
      role: AppRole.municipalOfficer,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0102',
      lastSignIn: now.subtract(const Duration(hours: 3)),
      accountCreated: DateTime(2025, 2, 3),
      region: Region.greaterAccra,
      assembly: assemblyNamed(Region.greaterAccra, 'Accra'),
    ),
    AdminUserItem(
      name: 'Esi Owusu',
      email: 'esi.owusu@civicvoice.gov',
      phone: '+233 20 555 6666',
      role: AppRole.ministrySupervisor,
      status: AdminUserStatus.review,
      userId: 'CV-USER-0103',
      lastSignIn: DateTime(2025, 11, 28, 9, 30),
      accountCreated: DateTime(2025, 3, 18),
    ),
    AdminUserItem(
      name: 'Yaw Asare',
      email: 'yaw.asare@civicvoice.gov',
      phone: '+233 27 777 8888',
      role: AppRole.maintenanceTeam,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0104',
      lastSignIn: now.subtract(const Duration(hours: 8, minutes: 40)),
      accountCreated: DateTime(2025, 1, 12),
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    ),
    AdminUserItem(
      name: 'Kojo Mensah-Boateng',
      email: 'kojo.mensahboateng@civicvoice.gov',
      phone: '+233 27 444 5555',
      role: AppRole.maintenanceTeam,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0110',
      lastSignIn: now.subtract(const Duration(hours: 3, minutes: 10)),
      accountCreated: DateTime(2025, 4, 22),
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    ),
    AdminUserItem(
      name: 'Kwame Nyarko',
      email: 'kwame.nyarko@gmail.com',
      phone: '+233 54 999 0000',
      role: AppRole.citizen,
      status: AdminUserStatus.review,
      userId: 'CV-USER-0105',
      lastSignIn: DateTime(2025, 11, 20, 14, 12),
      accountCreated: DateTime(2025, 6, 9),
    ),
    AdminUserItem(
      name: 'Genevieve Amadapah',
      email: 'genevieve.amadapah@civicvoice.gov',
      phone: '+233 26 222 3333',
      role: AppRole.citizen,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0106',
      lastSignIn: now.subtract(const Duration(days: 1, hours: 2)),
      accountCreated: DateTime(2025, 7, 22),
    ),
    AdminUserItem(
      name: 'Efua Darko',
      email: 'efua.darko@civicvoice.gov',
      phone: '+233 24 444 5555',
      role: AppRole.systemAdministrator,
      status: AdminUserStatus.active,
      userId: 'CV-USER-0107',
      lastSignIn: now.subtract(const Duration(hours: 5)),
      accountCreated: DateTime(2025, 4, 14),
      adminTier: AdminTier.admin,
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    ),
  ];
}
