import 'incoming_report.dart';
import '../services/municipal_report_directory.dart';
import '../services/municipal_session.dart';

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
    final reports = MunicipalReportDirectory.instance.reports.value;
    final isLive = MunicipalReportDirectory.instance.hasLiveSnapshot;
    final assignmentGroups = <String, List<int>>{};
    if (isLive) {
      for (final report in reports) {
        final team = report.teamName;
        if (team != null) {
          assignmentGroups
              .putIfAbsent(team, () => [])
              .add(report.progressPercent ?? 0);
        }
      }
    }
    final officer = MunicipalSession.instance.profile.value;
    return MunicipalDashboardData(
      officerName: isLive ? officer.name : 'Alex Johnston',
      municipalityName: isLive ? officer.department : 'Springfield District',
      stats: isLive
          ? MunicipalDashboardStats(
              newReports: reports
                  .where((report) => report.status.name == 'submitted')
                  .length,
              underReview: reports
                  .where((report) => report.status.name == 'underReview')
                  .length,
              assigned: reports
                  .where(
                    (report) =>
                        report.status.name == 'assigned' ||
                        report.status.name == 'inProgress',
                  )
                  .length,
              resolved: reports
                  .where((report) => report.status.name == 'resolved')
                  .length,
            )
          : const MunicipalDashboardStats(
              newReports: 128,
              underReview: 42,
              assigned: 31,
              resolved: 87,
            ),
      recentReports: reports.take(3).toList(),
      assignmentSummary: isLive
          ? [
              for (final entry in assignmentGroups.entries)
                AssignmentProgress(
                  teamName: entry.key,
                  percent:
                      entry.value.reduce((a, b) => a + b) /
                      entry.value.length /
                      100,
                ),
            ]
          : const [
              AssignmentProgress(teamName: 'Public Works', percent: 0.72),
              AssignmentProgress(teamName: 'Sanitation', percent: 0.54),
              AssignmentProgress(teamName: 'Utilities', percent: 0.38),
            ],
    );
  }

  /// Production projection. Unlike [mock], an empty live directory stays
  /// empty and never turns into demonstration statistics.
  factory MunicipalDashboardData.current() {
    final reports = MunicipalReportDirectory.instance.reports.value;
    final assignmentGroups = <String, List<int>>{};
    for (final report in reports) {
      final team = report.teamName;
      if (team != null) {
        assignmentGroups
            .putIfAbsent(team, () => [])
            .add(report.progressPercent ?? 0);
      }
    }
    final officer = MunicipalSession.instance.profile.value;
    return MunicipalDashboardData(
      officerName: officer.name,
      municipalityName: officer.department,
      stats: MunicipalDashboardStats(
        newReports: reports
            .where((report) => report.status.name == 'submitted')
            .length,
        underReview: reports
            .where((report) => report.status.name == 'underReview')
            .length,
        assigned: reports
            .where(
              (report) =>
                  report.status.name == 'assigned' ||
                  report.status.name == 'inProgress',
            )
            .length,
        resolved: reports
            .where((report) => report.status.name == 'resolved')
            .length,
      ),
      recentReports: reports.take(3).toList(),
      assignmentSummary: [
        for (final entry in assignmentGroups.entries)
          AssignmentProgress(
            teamName: entry.key,
            percent:
                entry.value.reduce((a, b) => a + b) / entry.value.length / 100,
          ),
      ],
    );
  }
}
