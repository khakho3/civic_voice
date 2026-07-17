import '../../../models/report_category.dart';
import '../../../models/report_severity.dart';
import '../../../models/report_status.dart';

export '../../../models/report_category.dart';

/// A single row in MUN-002 Incoming Reports.
class IncomingReportItem {
  const IncomingReportItem({
    required this.referenceId,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.timeAgo,
    this.photoUrl,
  });

  final String referenceId;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportSeverity severity;
  final ReportStatus status;
  final String timeAgo;

  /// Null until Firebase Storage is wired up (Issue 03 dependency) — the
  /// leading avatar falls back to a placeholder icon when absent.
  final String? photoUrl;

  static List<IncomingReportItem> mock() => const [
    IncomingReportItem(
      referenceId: 'CV-1042',
      title: 'Traffic Light Malfunction',
      description:
          'Main St & 4th Ave intersection lights are completely out. '
          'Causing major delays.',
      category: ReportCategory.safety,
      severity: ReportSeverity.high,
      status: ReportStatus.submitted,
      timeAgo: '10 min ago',
    ),
    IncomingReportItem(
      referenceId: 'CV-1041',
      title: 'Pothole on Elm Street',
      description:
          'Large pothole forming in the right lane northbound. Several '
          'cars swerving to avoid it.',
      category: ReportCategory.infrastructure,
      severity: ReportSeverity.medium,
      status: ReportStatus.underReview,
      timeAgo: '45 min ago',
    ),
    IncomingReportItem(
      referenceId: 'CV-1040',
      title: 'Missed Trash Collection',
      description:
          "Entire block on Maple Drive hasn't had trash picked up for two "
          'days. Bins are overflowing.',
      category: ReportCategory.sanitation,
      severity: ReportSeverity.low,
      status: ReportStatus.assigned,
      timeAgo: '2 hrs ago',
    ),
  ];
}
