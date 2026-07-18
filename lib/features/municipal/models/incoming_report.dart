import '../../../models/report_category.dart';
import '../../../models/report_status.dart';

export '../../../models/report_category.dart';

/// A single report, shared by every Municipal list that shows one — MUN-002
/// Incoming Reports, MUN-001 Dashboard's Recent Reports, and MUN-006 Active
/// Reports. One model instead of separate per-screen mocks means a report's
/// status is real: verifying it or assigning it a team (see
/// `MunicipalReportDirectory`) actually moves it between these lists rather
/// than each screen showing its own disconnected snapshot.
class IncomingReportItem {
  const IncomingReportItem({
    required this.referenceId,
    required this.title,
    required this.description,
    required this.locationLabel,
    required this.category,
    required this.status,
    required this.timeAgo,
    this.teamName,
    this.progressPercent,
    this.updatedLabel,
    this.photoUrl,
  });

  final String referenceId;
  final String title;
  final String description;
  final String locationLabel;
  final ReportCategory category;
  final ReportStatus status;
  final String timeAgo;

  /// Set once a maintenance team takes the case — see
  /// [MunicipalReportDirectory.assignTeam]. Null beforehand: a report still
  /// in triage (submitted/under review) has no team yet.
  final String? teamName;

  /// 0-100. Null until assigned, mirroring [teamName] — there's no progress
  /// to show before a team is on the case.
  final int? progressPercent;

  /// Pre-formatted "last updated" text (e.g. "2m ago"). Null until assigned,
  /// mirroring [teamName]/[progressPercent].
  final String? updatedLabel;

  /// Null until Firebase Storage is wired up (Issue 03 dependency) — the
  /// leading avatar falls back to a placeholder icon when absent.
  final String? photoUrl;

  IncomingReportItem copyWith({
    ReportStatus? status,
    String? teamName,
    int? progressPercent,
    String? updatedLabel,
  }) {
    return IncomingReportItem(
      referenceId: referenceId,
      title: title,
      description: description,
      locationLabel: locationLabel,
      category: category,
      status: status ?? this.status,
      timeAgo: timeAgo,
      teamName: teamName ?? this.teamName,
      progressPercent: progressPercent ?? this.progressPercent,
      updatedLabel: updatedLabel ?? this.updatedLabel,
      photoUrl: photoUrl,
    );
  }

  /// Placeholder content matching the approved MUN-002/MUN-006 designs, used
  /// until the Cloud Firestore-backed service (Issue 03 dependency) is wired
  /// up.
  ///
  /// The first two entries are MUN-002's original Incoming Reports pair — a
  /// brand-new submission and one already reviewed but still awaiting a
  /// team, which is exactly what should still show in Inbox per the real
  /// status split. The remaining five are the same reports MUN-006 Active
  /// Reports always showed (REQ-8421 is the pothole report followed through
  /// Report Review → Verification → Assign Team elsewhere in the app) —
  /// merged in here rather than kept as a separate mock so a report's
  /// status actually determines which list it shows up in.
  static List<IncomingReportItem> mock() => [
    const IncomingReportItem(
      referenceId: 'CV-1042',
      title: 'Traffic Light Malfunction',
      description:
          'Main St & 4th Ave intersection lights are completely out. '
          'Causing major delays.',
      locationLabel: 'Main St & 4th Ave',
      category: ReportCategory.safety,
      status: ReportStatus.submitted,
      timeAgo: '10 min ago',
    ),
    const IncomingReportItem(
      referenceId: 'CV-1041',
      title: 'Pothole on Elm Street',
      description:
          'Large pothole forming in the right lane northbound. Several '
          'cars swerving to avoid it.',
      locationLabel: 'Elm Street',
      category: ReportCategory.infrastructure,
      status: ReportStatus.underReview,
      timeAgo: '45 min ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8421',
      title: 'Severe Pothole on Main St.',
      description:
          'Deep pothole in the right lane causing vehicles to swerve into '
          'oncoming traffic.',
      locationLabel: 'Main St · Downtown',
      category: ReportCategory.infrastructure,
      status: ReportStatus.inProgress,
      timeAgo: '2 hrs ago',
      teamName: 'Unit Alpha',
      progressPercent: 60,
      updatedLabel: '2m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8317',
      title: 'Broken Streetlight',
      description:
          'Streetlight has been out for several nights, leaving the '
          'corner unlit.',
      locationLabel: '5th & Oak · Downtown',
      category: ReportCategory.safety,
      status: ReportStatus.assigned,
      timeAgo: '5 hrs ago',
      teamName: 'Unit Bravo',
      progressPercent: 20,
      updatedLabel: '12m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8298',
      title: 'Overflowing Trash Bin',
      description:
          'Public trash bin has been overflowing for days, attracting '
          'pests.',
      locationLabel: 'Park Ln · Riverside',
      category: ReportCategory.sanitation,
      status: ReportStatus.inProgress,
      timeAgo: '8 hrs ago',
      teamName: 'Unit Charlie',
      progressPercent: 45,
      updatedLabel: '22m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8402',
      title: 'Water Leak Near Curb',
      description:
          'Steady water leak pooling near the curb, likely a broken main.',
      locationLabel: 'Cedar St · Uptown',
      category: ReportCategory.infrastructure,
      status: ReportStatus.assigned,
      timeAgo: '10 hrs ago',
      teamName: 'Unit Delta',
      progressPercent: 10,
      updatedLabel: '31m ago',
    ),
    const IncomingReportItem(
      referenceId: 'REQ-8189',
      title: 'Sidewalk Crack',
      description: 'Large crack in the sidewalk creating a trip hazard.',
      locationLabel: 'Elm Rd · Southside',
      category: ReportCategory.infrastructure,
      status: ReportStatus.resolved,
      timeAgo: '1 day ago',
      teamName: 'Unit Alpha',
      progressPercent: 100,
      updatedLabel: '1h ago',
    ),
  ];
}
