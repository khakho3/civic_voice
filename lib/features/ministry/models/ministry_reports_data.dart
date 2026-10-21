import '../../../models/region.dart';
import '../../../models/report_status.dart';

export '../../../models/report_status.dart';

/// Status filter chips for Ministry's report overview.
///
/// The chips intentionally group the read-only report list more coarsely than
/// the canonical lifecycle. All seven statuses remain visible under [all].
enum ReportStatusFilter {
  all('All'),
  submitted('Submitted'),
  review('Review'),
  resolved('Resolved');

  const ReportStatusFilter(this.label);

  final String label;

  bool matches(ReportStatus status) => switch (this) {
    ReportStatusFilter.all => true,
    ReportStatusFilter.submitted => status == ReportStatus.submitted,
    ReportStatusFilter.review => status == ReportStatus.underReview,
    ReportStatusFilter.resolved => status == ReportStatus.resolved,
  };
}

/// One static, read-only report row in the Ministry overview.
class ReportSummaryItem {
  const ReportSummaryItem({
    required this.title,
    required this.municipality,
    required this.region,
    required this.category,
    required this.status,
    required this.dateLabel,
  });

  final String title;
  final String municipality;
  final Region? region;
  final String category;
  final ReportStatus status;
  final String dateLabel;

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final normalized = query.toLowerCase();
    return title.toLowerCase().contains(normalized) ||
        municipality.toLowerCase().contains(normalized) ||
        category.toLowerCase().contains(normalized);
  }
}

/// National report totals, calculated before any screen-local filtering.
class MinistryReportsStats {
  const MinistryReportsStats({
    required this.aggregatedReports,
    required this.underReview,
    required this.resolved,
  });

  final int aggregatedReports;
  final int underReview;
  final int resolved;
}

/// Data backing MIN-004 Reports Overview.
///
/// Production callers must provide this from a genuine report source. Test
/// fixtures are supplied by tests rather than embedded in the module.
class MinistryReportsData {
  const MinistryReportsData({required this.stats, required this.reports});

  final MinistryReportsStats stats;
  final List<ReportSummaryItem> reports;
}
