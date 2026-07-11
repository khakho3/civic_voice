import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_severity.dart';
import 'incoming_report.dart';

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

class MaintenanceTeam {
  const MaintenanceTeam({
    required this.name,
    required this.specialty,
    required this.leadName,
    required this.availability,
    required this.distanceKm,
    required this.memberCount,
    required this.rating,
    required this.etaMinutes,
  });

  final String name;
  final String specialty;
  final String leadName;
  final TeamAvailability availability;
  final double distanceKm;
  final int memberCount;
  final double rating;
  final int etaMinutes;
}

enum TeamFilter {
  all('All'),
  available('Available'),
  nearest('Nearest'),
  highestRated('Highest Rated');

  const TeamFilter(this.label);

  final String label;
}

/// Full data payload for MUN-005 Assign Maintenance Team.
class AssignTeamData {
  const AssignTeamData({
    required this.referenceId,
    required this.title,
    required this.locationSummary,
    required this.category,
    required this.severity,
    required this.teams,
  });

  final String referenceId;
  final String title;
  final String locationSummary;
  final ReportCategory category;
  final ReportSeverity severity;
  final List<MaintenanceTeam> teams;

  /// Placeholder content matching the approved MUN-005 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  ///
  /// [referenceId], [title] and [locationSummary] are carried over verbatim
  /// from [VerificationData.mock] — this is the same report moving through
  /// Report Review → Verification → Assign Team, so its identity shouldn't
  /// drift between screens. The approved MUN-005 frame instead showed the
  /// screen's own spec ID ("MUN-005") in place of the report reference and
  /// "Main Ave" in place of "Main St." — both read as mockup slips rather
  /// than a deliberate different report, so they're corrected here.
  factory AssignTeamData.mock() {
    return const AssignTeamData(
      referenceId: 'REQ-8421',
      title: 'Severe Pothole on Main St.',
      locationSummary: '1200 Block, Main St · Reported 2h ago',
      category: ReportCategory.infrastructure,
      severity: ReportSeverity.high,
      teams: [
        MaintenanceTeam(
          name: 'Unit Alpha',
          specialty: 'Roadworks',
          leadName: 'M. Reyes',
          availability: TeamAvailability.available,
          distanceKm: 1.2,
          memberCount: 5,
          rating: 4.8,
          etaMinutes: 12,
        ),
        MaintenanceTeam(
          name: 'Unit Bravo',
          specialty: 'Electrical',
          leadName: 'S. Okafor',
          availability: TeamAvailability.available,
          distanceKm: 2.6,
          memberCount: 4,
          rating: 4.6,
          etaMinutes: 22,
        ),
        MaintenanceTeam(
          name: 'Unit Charlie',
          specialty: 'Sanitation',
          leadName: 'P. Nguyen',
          availability: TeamAvailability.busy,
          distanceKm: 3.4,
          memberCount: 6,
          rating: 4.4,
          etaMinutes: 28,
        ),
        MaintenanceTeam(
          name: 'Unit Delta',
          specialty: 'Water & Drainage',
          leadName: 'R. Haddad',
          availability: TeamAvailability.offDuty,
          distanceKm: 4.8,
          memberCount: 5,
          rating: 4.7,
          etaMinutes: 35,
        ),
      ],
    );
  }
}
