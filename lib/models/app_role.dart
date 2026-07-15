/// The five CivicVoice user roles.
///
/// Cross-cutting across every module that needs to reference "which role is
/// this account" (User Management, Role Management, User Details) — lives
/// in the shared `lib/models/` location rather than a single feature
/// module, alongside [ReportStatus]/[ReportSeverity]. Reuses [AppIcons]'s
/// existing role icon tokens (already the single source of truth for role
/// iconography across the citizen, municipal, maintenance, ministry, and
/// admin modules) rather than duplicating them.
library;

import 'package:flutter/widgets.dart';

import '../core/theme/app_theme.dart';

enum AppRole {
  citizen('Citizen', AppIcons.citizen),
  municipalOfficer('Municipal Officer', AppIcons.municipalOfficer),
  maintenanceTeam('Maintenance Team', AppIcons.maintenanceTeam),
  ministrySupervisor('Ministry Supervisor', AppIcons.ministrySupervisor),
  systemAdministrator('System Administrator', AppIcons.systemAdministrator);

  const AppRole(this.label, this.icon);

  final String label;
  final IconData icon;
}
