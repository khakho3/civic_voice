import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';

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

/// One row in the User Management list.
class AdminUserItem {
  const AdminUserItem({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  final String name;
  final String email;
  final AppRole role;
  final AdminUserStatus status;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.map((p) => p.isEmpty ? '' : p[0]).take(2).join().toUpperCase();
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return name.toLowerCase().contains(q) || email.toLowerCase().contains(q);
  }

  AdminUserItem copyWith({AdminUserStatus? status}) {
    return AdminUserItem(
      name: name,
      email: email,
      role: role,
      status: status ?? this.status,
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
  return const [
    AdminUserItem(
      name: 'Ama Boateng',
      email: 'admin@civicvoice.gov',
      role: AppRole.systemAdministrator,
      status: AdminUserStatus.inactive,
    ),
    AdminUserItem(
      name: 'Kojo Mensah',
      email: 'kojo.mensah@civicvoice.gov',
      role: AppRole.municipalOfficer,
      status: AdminUserStatus.active,
    ),
    AdminUserItem(
      name: 'Esi Owusu',
      email: 'esi.owusu@civicvoice.gov',
      role: AppRole.ministrySupervisor,
      status: AdminUserStatus.review,
    ),
    AdminUserItem(
      name: 'Yaw Asare',
      email: 'yaw.asare@civicvoice.gov',
      role: AppRole.maintenanceTeam,
      status: AdminUserStatus.active,
    ),
    AdminUserItem(
      name: 'Kwame Nyarko',
      email: 'kwame.nyarko@gmail.com',
      role: AppRole.citizen,
      status: AdminUserStatus.review,
    ),
    AdminUserItem(
      name: 'Genevieve Amadapah',
      email: 'genevieve.amadapah@civicvoice.gov',
      role: AppRole.citizen,
      status: AdminUserStatus.active,
    ),
  ];
}
