import 'incoming_report.dart';
import '../services/municipal_report_directory.dart';

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
    required this.officerName,
    required this.municipalityName,
    required this.stats,
    required this.recentReports,
    required this.assignmentSummary,
  });

  /// The signed-in officer — matches [OfficerProfile.mock]'s own name (see
  /// that field's own doc comment for why this is a fixed mock identity,
  /// not yet derived from any real session).
  final String officerName;
  final String municipalityName;
  final MunicipalDashboardStats stats;

  /// The same [IncomingReportItem] records MUN-002/MUN-006 list, read
  /// straight from `MunicipalReportDirectory` — one shared list means
  /// tapping a row here opens the exact report it displays, and its status
  /// is the real one, not a disconnected snapshot.
  final List<IncomingReportItem> recentReports;
  final List<AssignmentProgress> assignmentSummary;

  /// Placeholder content matching the approved MUN-001 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  factory MunicipalDashboardData.mock() {
    return MunicipalDashboardData(
      officerName: 'Alex Johnston',
      municipalityName: 'Springfield District',
      stats: const MunicipalDashboardStats(
        newReports: 128,
        underReview: 42,
        assigned: 31,
        resolved: 87,
      ),
      recentReports: MunicipalReportDirectory.instance.reports.value
          .take(3)
          .toList(),
      assignmentSummary: const [
        AssignmentProgress(teamName: 'Public Works', percent: 0.72),
        AssignmentProgress(teamName: 'Sanitation', percent: 0.54),
        AssignmentProgress(teamName: 'Utilities', percent: 0.38),
      ],
    );
  }
}
