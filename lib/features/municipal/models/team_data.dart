import 'incoming_report.dart';

enum TeamFilter {
  all('All'),
  available('Available');

  const TeamFilter(this.label);

  final String label;
}

/// Full data payload for MUN-005 Assign Maintenance Team — just the
/// report's own info now. The team list itself comes live from
/// `MaintenanceTeamDirectory` (the same real, Admin-provisioned teams
/// Admin's own Maintenance Teams screen manages), not a separate mock —
/// see `MunicipalAssignTeamScreen`'s own `build()`.
class AssignTeamData {
  const AssignTeamData({
    required this.referenceId,
    required this.title,
    required this.locationSummary,
    required this.category,
    required this.officerName,
    required this.officerPhone,
  });

  final String referenceId;
  final String title;
  final String locationSummary;
  final ReportCategory category;

  /// The Municipal Officer assigning this report — see [OfficerContactRow].
  final String officerName;
  final String officerPhone;

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
      officerName: 'Alex Johnston',
      officerPhone: '+233 24 555 0142',
    );
  }

  factory AssignTeamData.fromReport(IncomingReportItem report) {
    return AssignTeamData(
      referenceId: report.referenceId,
      title: report.title,
      locationSummary: '${report.locationLabel} · ${report.timeAgo}',
      category: report.category,
      officerName: report.reviewerName ?? 'Reviewing officer',
      officerPhone: report.reviewerPhone ?? 'Contact unavailable',
    );
  }
}
