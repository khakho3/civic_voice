/// A single resolved report shown on MUN-008 Resolved Reports (list card
/// and its Resolution Details drill-down).
class ResolvedReportItem {
  const ResolvedReportItem({
    required this.referenceId,
    required this.title,
    required this.locationLabel,
    required this.department,
    required this.resolvedDate,
    required this.resolvedTimeLabel,
    required this.durationDays,
    required this.slaPercent,
    required this.evidencePhotoCount,
    required this.resolutionNote,
  });

  final String referenceId;
  final String title;
  final String locationLabel;
  final String department;

  /// Real [DateTime] (not a fixed string) so "This Week"/"This Month" can
  /// filter against it honestly, and so the mock data doesn't read as
  /// stale if this app is still being tested months after these lines were
  /// written — computed relative to [DateTime.now] in [mock].
  final DateTime resolvedDate;

  /// Time-of-day the resolution was logged, e.g. "2:45 PM" — kept as a
  /// plain string since it's flavor detail, not something anything filters
  /// or sorts on.
  final String resolvedTimeLabel;

  final int durationDays;
  final int slaPercent;
  final int evidencePhotoCount;
  final String resolutionNote;

  /// Placeholder content matching the approved MUN-008 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  ///
  /// The approved frame showed these three reports with `MUN-002`/
  /// `MUN-003`/`MUN-004` as report references — this project's own screen
  /// spec numbering (MUN-001 through MUN-009), not a report ID format used
  /// anywhere else in the app. Same category of mockup slip already
  /// corrected on Assign Team/Active Reports/Report Progress, so these are
  /// given proper `REQ-` identifiers here too. None of the three is the
  /// pothole report followed through the rest of the flow (REQ-8421) — it's
  /// still "In Progress" on Report Progress, not resolved yet, so it
  /// wouldn't belong in this list.
  static List<ResolvedReportItem> mock() {
    final now = DateTime.now();
    return [
      ResolvedReportItem(
        referenceId: 'REQ-8355',
        title: 'Streetlight Outage — 4th Ave',
        locationLabel: '1240 Main St',
        department: 'Public Works',
        resolvedDate: now.subtract(const Duration(days: 2)),
        resolvedTimeLabel: '2:45 PM',
        durationDays: 2,
        slaPercent: 98,
        evidencePhotoCount: 2,
        resolutionNote: 'Technician completed repair and tested.',
      ),
      ResolvedReportItem(
        referenceId: 'REQ-8244',
        title: 'Pothole Cluster — Elm Rd',
        locationLabel: '88 Elm Rd',
        department: 'Road Maintenance',
        resolvedDate: now.subtract(const Duration(days: 4)),
        resolvedTimeLabel: '11:20 AM',
        durationDays: 3,
        slaPercent: 95,
        evidencePhotoCount: 2,
        resolutionNote: 'Potholes filled and resurfaced.',
      ),
      ResolvedReportItem(
        referenceId: 'REQ-8201',
        title: 'Graffiti Removal — Bridge',
        locationLabel: 'Riverside Bridge',
        department: 'Public Works',
        resolvedDate: now.subtract(const Duration(days: 9)),
        resolvedTimeLabel: '9:00 AM',
        durationDays: 1,
        slaPercent: 100,
        evidencePhotoCount: 1,
        resolutionNote: 'Graffiti pressure-washed and surface sealed.',
      ),
    ];
  }
}

/// Filter chips for MUN-008 — mixes a time window (This Week/This Month)
/// with a department spot-check (Public Works), matching the approved
/// frame exactly rather than normalizing to a single filter dimension.
enum ResolvedReportFilter {
  all('All'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  publicWorks('Public Works');

  const ResolvedReportFilter(this.label);

  final String label;
}

/// Aggregate stats shown at the top of the list — fixed regardless of the
/// active filter/search, matching Dashboard's stats grid (which likewise
/// doesn't react to Recent Reports' own filtering).
///
/// The approved frame's third stat was an "Avg Rating" star score. Dropped
/// deliberately: each resolved report would only ever have one possible
/// rater (the original reporter), so per-report stars are n=1 sentiment
/// presented as an aggregate — and subjective scores are the most gameable
/// surface in an app whose whole premise is being resistant to political
/// manipulation. SLA compliance carries the same "how well are we doing"
/// signal, but derived from timestamps nobody can brigade.
class ResolvedReportStats {
  const ResolvedReportStats({
    required this.resolvedThisMonth,
    required this.avgResolutionDays,
    required this.slaMetPercent,
  });

  final int resolvedThisMonth;
  final double avgResolutionDays;
  final int slaMetPercent;

  static const mock = ResolvedReportStats(
    resolvedThisMonth: 128,
    avgResolutionDays: 2.4,
    slaMetPercent: 94,
  );
}

/// Simple manual "MMM d, yyyy" formatter — no `intl` dependency for this
/// one call site (shared by the list and detail screens).
String formatResolvedDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
