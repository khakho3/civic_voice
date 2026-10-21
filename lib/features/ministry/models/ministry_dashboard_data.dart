import '../../../models/report_status.dart';
import 'municipal_performance_data.dart';

/// Data backing MIN-001 Ministry Dashboard's loaded state.
class MinistryDashboardData {
  const MinistryDashboardData({
    required this.stats,
    required this.reportStatistics,
    required this.insights,
    required this.topMunicipalities,
  });

  final MinistryDashboardStats stats;
  final ReportStatistics reportStatistics;
  final QuickInsights insights;

  /// A national ranking is only displayed when it comes from available
  /// scoped report data.
  final List<RegionalLeaderItem> topMunicipalities;

  /// An honest national zero-data projection. It deliberately contains no
  /// chart series or municipality rows: those would imply activity that does
  /// not exist.
  static const zero = MinistryDashboardData(
    stats: MinistryDashboardStats(
      statusCounts: {
        ReportStatus.submitted: 0,
        ReportStatus.underReview: 0,
        ReportStatus.assigned: 0,
        ReportStatus.inProgress: 0,
        ReportStatus.pendingApproval: 0,
        ReportStatus.resolved: 0,
        ReportStatus.rejected: 0,
      },
      activeMunicipalities: 0,
    ),
    reportStatistics: ReportStatistics(
      monthlyValues: [0],
      rangeLabel: '',
      totalLabel: '',
    ),
    insights: QuickInsights(
      statusCounts: {
        ReportStatus.submitted: 0,
        ReportStatus.underReview: 0,
        ReportStatus.assigned: 0,
        ReportStatus.inProgress: 0,
        ReportStatus.pendingApproval: 0,
        ReportStatus.resolved: 0,
        ReportStatus.rejected: 0,
      },
    ),
    topMunicipalities: [],
  );
}

/// The four National Summary stat cards.
class MinistryDashboardStats {
  const MinistryDashboardStats({
    required this.statusCounts,
    required this.activeMunicipalities,
  });

  /// Every lifecycle status is represented, including closed statuses. This
  /// keeps the dashboard total auditable and prevents approval work from
  /// disappearing from active workload.
  final Map<ReportStatus, int> statusCounts;

  final int activeMunicipalities;

  int count(ReportStatus status) => statusCounts[status] ?? 0;

  int get totalReports => statusCounts.values.fold(0, (sum, value) => sum + value);

  int get openWork =>
      count(ReportStatus.submitted) +
      count(ReportStatus.underReview) +
      count(ReportStatus.assigned) +
      count(ReportStatus.inProgress) +
      count(ReportStatus.pendingApproval);

  int get resolved => count(ReportStatus.resolved);
}

/// The "Report Statistics" bar chart section.
class ReportStatistics {
  const ReportStatistics({
    required this.monthlyValues,
    required this.rangeLabel,
    required this.totalLabel,
  });

  /// Relative bar heights — proportions only, not absolute counts.
  final List<int> monthlyValues;
  final String rangeLabel;
  final String totalLabel;
}

/// Status-share data for the dashboard's active-work highlights.
class QuickInsights {
  const QuickInsights({required this.statusCounts});

  /// Retains the complete status projection even when the UI only highlights
  /// active work. Rejected reports therefore remain part of the total.
  final Map<ReportStatus, int> statusCounts;

  int count(ReportStatus status) => statusCounts[status] ?? 0;

  int percent(ReportStatus status) {
    final total = statusCounts.values.fold(0, (sum, value) => sum + value);
    if (total == 0) return 0;
    return ((count(status) / total) * 100).round();
  }
}
