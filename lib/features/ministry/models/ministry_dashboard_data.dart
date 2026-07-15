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
  final List<MunicipalityPerformanceItem> topMunicipalities;

  /// Placeholder content matching the approved MIN-001 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency)
  /// is wired up.
  static MinistryDashboardData mock() {
    return const MinistryDashboardData(
      stats: MinistryDashboardStats(
        totalReports: 24800,
        totalReportsChangePercent: 12,
        underReview: 3200,
        underReviewPercent: 13,
        resolved: 18600,
        resolvedPercent: 75,
        activeMunicipalities: 216,
      ),
      reportStatistics: ReportStatistics(
        // Relative monthly volumes (Jan–Jun) — proportions only, matching
        // the approved frame's bar chart shape.
        monthlyValues: [62, 78, 54, 92, 68, 100],
        rangeLabel: 'Jan–Jun reports',
        totalLabel: '24.8K total',
      ),
      insights: QuickInsights(
        submittedPercent: 24,
        underReviewPercent: 13,
        assignedPercent: 18,
        inProgressPercent: 20,
      ),
      topMunicipalities: [
        MunicipalityPerformanceItem(
          name: 'Greater Accra',
          metricLabel: '92% SLA compliance',
        ),
        MunicipalityPerformanceItem(
          name: 'Kumasi Metro',
          metricLabel: '86% resolution rate',
        ),
        MunicipalityPerformanceItem(
          name: 'Tamale Metro',
          metricLabel: '71% review throughput',
        ),
      ],
    );
  }
}

/// The four National Summary stat cards.
class MinistryDashboardStats {
  const MinistryDashboardStats({
    required this.totalReports,
    required this.totalReportsChangePercent,
    required this.underReview,
    required this.underReviewPercent,
    required this.resolved,
    required this.resolvedPercent,
    required this.activeMunicipalities,
  });

  final int totalReports;

  /// Period-over-period change, e.g. `12` for "+12%".
  final int totalReportsChangePercent;

  final int underReview;

  /// Share of [totalReports] currently under review, e.g. `13` for "13%".
  final int underReviewPercent;

  final int resolved;

  /// Share of [totalReports] resolved, e.g. `75` for "75%".
  final int resolvedPercent;

  final int activeMunicipalities;
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

/// The four "Quick Insights" breakdown cards — status-share percentages of
/// the national report volume.
class QuickInsights {
  const QuickInsights({
    required this.submittedPercent,
    required this.underReviewPercent,
    required this.assignedPercent,
    required this.inProgressPercent,
  });

  final int submittedPercent;
  final int underReviewPercent;
  final int assignedPercent;
  final int inProgressPercent;
}

/// One row in the "Municipality Performance" list — each municipality
/// surfaces whichever metric is most notable for it (SLA compliance,
/// resolution rate, review throughput, ...), matching the approved frame
/// rather than forcing every row onto one fixed metric.
class MunicipalityPerformanceItem {
  const MunicipalityPerformanceItem({
    required this.name,
    required this.metricLabel,
  });

  final String name;
  final String metricLabel;
}
