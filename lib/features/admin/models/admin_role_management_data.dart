import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The fixed handful of capabilities the "Quick Permissions Check" table
/// compares across tiers — the same catalog each [AdminTier] draws its own
/// granted-permission chips from, so the card and the table always agree.
enum PermissionType {
  deleteRecords('Delete Records'),
  exportReports('Export Reports'),
  editUserRoles('Edit User Roles'),
  viewAuditLogs('View Audit Logs');

  const PermissionType(this.label);

  final String label;
}

/// The two fixed privilege tiers a System Administrator account can hold —
/// distinct from [AppRole]: [AppRole] decides which module an account can
/// open at all, while [AdminTier] decides what a *systemAdministrator*
/// account specifically can do once inside this module. There's no case for
/// this inside the other four roles (a Municipal Officer doesn't need a
/// different permission set from another Municipal Officer), so this stays
/// scoped to admin accounts only, and it stays a closed, fixed set rather
/// than the open-ended, admin-creatable "permission template" this screen
/// started as — nobody needs a third or fourth tier, and this app has no
/// backend to enforce an arbitrary one anyway (see the screen's own doc
/// comment).
enum AdminTier {
  admin(
    label: 'Admin',
    scope: 'Standard Access',
    description:
        'Day-to-day administrative access for account and report '
        'oversight, without destructive or role-management privileges.',
    icon: AppIcons.shieldAlert,
    tint: AppColors.warning,
    permissions: {
      PermissionType.deleteRecords: false,
      PermissionType.exportReports: true,
      PermissionType.editUserRoles: false,
      PermissionType.viewAuditLogs: true,
    },
  ),
  superAdmin(
    label: 'Super Admin',
    scope: 'Full System Authority',
    description:
        'Unrestricted access to every administrator capability, '
        'including account deletion, role assignment, and system '
        'configuration.',
    icon: AppIcons.shield,
    tint: AppColors.primary,
    permissions: {
      PermissionType.deleteRecords: true,
      PermissionType.exportReports: true,
      PermissionType.editUserRoles: true,
      PermissionType.viewAuditLogs: true,
    },
  );

  const AdminTier({
    required this.label,
    required this.scope,
    required this.description,
    required this.icon,
    required this.tint,
    required this.permissions,
  });

  final String label;

  /// Short subtitle under the name (e.g. "Full System Authority").
  final String scope;
  final String description;
  final IconData icon;
  final Color tint;
  final Map<PermissionType, bool> permissions;

  /// The granted permissions as display chips, e.g. "Export Reports" —
  /// derived from [permissions] rather than a separate free-text list, so
  /// a card's chips and the comparison table can never drift apart.
  List<String> get grantedPermissionLabels => [
    for (final entry in permissions.entries)
      if (entry.value) entry.key.label,
  ];
}
