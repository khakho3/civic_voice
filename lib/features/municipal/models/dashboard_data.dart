import '../../../models/report_status.dart';

/// Aggregate counters shown on the Municipal Dashboard stat cards.
class MunicipalDashboardStats {
  const MunicipalDashboardStats({
    required this.newReports,
    required this.underReview,
    required this.assigned,
    required this.resolved,
  });

  final int newReports;
  final int underReview;
  final int assigned;
  final int resolved;

  static const zero = MunicipalDashboardStats(
    newReports: 0,
    underReview: 0,
    assigned: 0,
    resolved: 0,
  );
}

/// A single row in the Dashboard's "Recent Reports" card.
class RecentReportItem {
  const RecentReportItem({
    required this.referenceId,
    required this.title,
    required this.category,
    required this.timeAgo,
    required this.status,
  });

  final String referenceId;
  final String title;
  final String category;
  final String timeAgo;
  final ReportStatus status;
}

/// A single row in the Dashboard's "Assignment Summary" card — a maintenance
/// team's completion progress across its currently assigned reports.
class AssignmentProgress {
  const AssignmentProgress({required this.teamName, required this.percent});

  final String teamName;

  /// 0.0–1.0
  final double percent;
}

/// Full data payload for MUN-001 Municipal Dashboard.
class MunicipalDashboardData {
  const MunicipalDashboardData({
    required this.municipalityName,
    required this.stats,
    required this.recentReports,
    required this.assignmentSummary,
  });

  final String municipalityName;
  final MunicipalDashboardStats stats;
  final List<RecentReportItem> recentReports;
  final List<AssignmentProgress> assignmentSummary;

  /// Placeholder content matching the approved MUN-001 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  factory MunicipalDashboardData.mock() {
    return const MunicipalDashboardData(
      municipalityName: 'Springfield District',
      stats: MunicipalDashboardStats(
        newReports: 128,
        underReview: 42,
        assigned: 31,
        resolved: 87,
      ),
      recentReports: [
        RecentReportItem(
          referenceId: 'CV-1042',
          title: 'Pothole on Oak Avenue',
          category: 'Roads',
          timeAgo: '24 min ago',
          status: ReportStatus.submitted,
        ),
        RecentReportItem(
          referenceId: 'CV-1041',
          title: 'Streetlight outage near Ward 4',
          category: 'Utilities',
          timeAgo: '1 hr ago',
          status: ReportStatus.underReview,
        ),
        RecentReportItem(
          referenceId: 'CV-1040',
          title: 'Overflowing waste bin at Civic Park',
          category: 'Sanitation',
          timeAgo: 'Today',
          status: ReportStatus.assigned,
        ),
        RecentReportItem(
          referenceId: 'CV-1039',
          title: 'Graffiti cleanup request',
          category: 'Public Works',
          timeAgo: 'Yesterday',
          status: ReportStatus.inProgress,
        ),
      ],
      assignmentSummary: [
        AssignmentProgress(teamName: 'Public Works', percent: 0.72),
        AssignmentProgress(teamName: 'Sanitation', percent: 0.54),
        AssignmentProgress(teamName: 'Utilities', percent: 0.38),
      ],
    );
  }
}
