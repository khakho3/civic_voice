import '../../../models/region.dart';
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

  /// The top 3 [MunicipalPerformanceData.mock] entries by resolved rate,
  /// reusing [RegionalLeaderItem] directly rather than a separate
  /// `MunicipalityPerformanceItem` model — the old one carried its own
  /// disconnected mock values (different municipalities, different
  /// percentages than Municipal Performance's own list), so the same
  /// municipality could read two different numbers depending which screen
  /// you were on. One shared model with one shared officer contact record
  /// is also what makes tapping a row here open the same detail screen
  /// Municipal Performance's own rows open.
  final List<RegionalLeaderItem> topMunicipalities;

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
      // The top 3 of MunicipalPerformanceData.mock's own regionalLeaders by
      // resolvedPercent — kept in sync by hand for now since these are two
      // separate mock() calls, but at least the same entries with the same
      // numbers, not a parallel dataset that can silently drift.
      topMunicipalities: [
        RegionalLeaderItem(
          name: 'Accra Metropolitan',
          region: Region.greaterAccra,
          resolvedPercent: 92,
          responseTimeLabel: '14h',
          officerName: 'Kwame Owusu',
          officerPhone: '+233 24 555 0101',
        ),
        RegionalLeaderItem(
          name: 'Kumasi Metropolitan',
          region: Region.ashanti,
          resolvedPercent: 86,
          responseTimeLabel: '18h',
          officerName: 'Abena Boateng',
          officerPhone: '+233 24 555 0102',
        ),
        RegionalLeaderItem(
          name: 'Sunyani Municipal',
          region: Region.bono,
          resolvedPercent: 83,
          responseTimeLabel: '17h',
          officerName: 'Comfort Osei',
          officerPhone: '+233 24 555 0114',
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
