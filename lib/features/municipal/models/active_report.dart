import '../../../models/report_status.dart';

/// A single row in MUN-006 Active Reports — a report that has moved past
/// triage and is now assigned to (or being worked by) a maintenance team.
class ActiveReportItem {
  const ActiveReportItem({
    required this.referenceId,
    required this.title,
    required this.locationLabel,
    required this.status,
    required this.progressPercent,
    required this.teamName,
    required this.etaLabel,
    required this.updatedLabel,
  });

  final String referenceId;
  final String title;
  final String locationLabel;
  final ReportStatus status;

  /// 0-100. Resolved reports are always 100.
  final int progressPercent;
  final String teamName;

  /// Pre-formatted remaining-time text (e.g. "35m", "1h 10m", "Done") —
  /// not a [Duration], since "Done" isn't a numeric value.
  final String etaLabel;

  /// Pre-formatted "last updated" text (e.g. "2m ago").
  final String updatedLabel;

  /// Placeholder content matching the approved MUN-006 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  ///
  /// The first entry is the same pothole report followed through Report
  /// Review → Verification → Assign Team ([referenceId] `REQ-8421`,
  /// assigned to Unit Alpha there) — the approved frame showed it with the
  /// screen's own spec ID ("MUN-005") in place of a report reference and
  /// "Main Ave" in place of "Main St.", the same slip already corrected in
  /// [AssignTeamData.mock]. Every other card in the approved frame had the
  /// same spec-ID substitution (MUN-006 through MUN-009 — this project's own
  /// issue numbering, not report references), so all five are given proper
  /// `REQ-` identifiers here.
  static List<ActiveReportItem> mock() => const [
    ActiveReportItem(
      referenceId: 'REQ-8421',
      title: 'Severe Pothole on Main St.',
      locationLabel: 'Main St · Downtown',
      status: ReportStatus.inProgress,
      progressPercent: 60,
      teamName: 'Unit Alpha',
      etaLabel: '35m',
      updatedLabel: '2m ago',
    ),
    ActiveReportItem(
      referenceId: 'REQ-8317',
      title: 'Broken Streetlight',
      locationLabel: '5th & Oak · Downtown',
      status: ReportStatus.assigned,
      progressPercent: 20,
      teamName: 'Unit Bravo',
      etaLabel: '1h 10m',
      updatedLabel: '12m ago',
    ),
    ActiveReportItem(
      referenceId: 'REQ-8298',
      title: 'Overflowing Trash Bin',
      locationLabel: 'Park Ln · Riverside',
      status: ReportStatus.inProgress,
      progressPercent: 45,
      teamName: 'Unit Charlie',
      etaLabel: '48m',
      updatedLabel: '22m ago',
    ),
    ActiveReportItem(
      referenceId: 'REQ-8402',
      title: 'Water Leak Near Curb',
      locationLabel: 'Cedar St · Uptown',
      status: ReportStatus.assigned,
      progressPercent: 10,
      teamName: 'Unit Delta',
      etaLabel: '2h 05m',
      updatedLabel: '31m ago',
    ),
    ActiveReportItem(
      referenceId: 'REQ-8189',
      title: 'Sidewalk Crack',
      locationLabel: 'Elm Rd · Southside',
      status: ReportStatus.resolved,
      progressPercent: 100,
      teamName: 'Unit Alpha',
      etaLabel: 'Done',
      updatedLabel: '1h ago',
    ),
  ];
}

/// Status-based filter chips for MUN-006 — a strict subset of [ReportStatus]:
/// only statuses relevant once a report has moved past triage into active
/// maintenance work.
enum ActiveReportFilter {
  all('All'),
  assigned('Assigned'),
  inProgress('In Progress'),
  resolved('Resolved');

  const ActiveReportFilter(this.label);

  final String label;
}

enum ActiveReportSort {
  mostRecent('Most Recent'),
  highestProgress('Highest Progress'),
  lowestProgress('Lowest Progress');

  const ActiveReportSort(this.label);

  final String label;
}
