import 'package:flutter/widgets.dart';

import '../core/theme/app_theme.dart';

/// A maintenance team's own self-reported work status — set by the team
/// lead from their own Profile (see `lib/features/maintenance/screens/
/// profile_screen.dart`), read wherever a team needs picking (Municipal's
/// Assign Team) or showing (Admin's Maintenance Teams list). Lives on the
/// one real [MaintenanceTeam] record (`lib/features/admin/models/
/// admin_maintenance_team_data.dart`) that `MaintenanceTeamDirectory`
/// manages — not a per-screen mock value.
enum TeamAvailability {
  available('Available'),
  busy('Busy'),
  offDuty('Off Duty');

  const TeamAvailability(this.label);

  final String label;

  /// Semantic color, or `null` for [offDuty] — that state reads as neutral
  /// rather than a colored status, so callers should fall back to a
  /// theme-aware gray (e.g. `colorScheme.onSurfaceVariant`) instead of a
  /// fixed [AppColors] constant.
  Color? get color => switch (this) {
    TeamAvailability.available => AppColors.success,
    TeamAvailability.busy => AppColors.warning,
    TeamAvailability.offDuty => null,
  };
}
