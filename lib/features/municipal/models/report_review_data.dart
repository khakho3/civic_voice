import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/report_severity.dart';
import '../../../models/report_status.dart';
import 'incoming_report.dart';

enum TimelineStepState { completed, current, pending }

/// A single milestone in a report's review history — distinct from
/// [ReportStatus]: a real implementation reads these from an audit-log
/// collection (Issue 03 "All status changes recorded"), not derived from
/// the single current-status enum.
class ReportTimelineStep {
  const ReportTimelineStep({
    required this.label,
    required this.icon,
    required this.state,
    this.timestamp,
  });

  final String label;
  final IconData icon;
  final TimelineStepState state;

  /// Null when [state] is [TimelineStepState.pending] — shows "Pending"
  /// instead.
  final String? timestamp;
}

/// Full data payload for MUN-003 Report Review.
class ReportReviewData {
  const ReportReviewData({
    required this.referenceId,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.citizenName,
    required this.citizenPhone,
    required this.evidencePhotoUrls,
    required this.locationLabel,
    required this.timeline,
  });

  final String referenceId;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportSeverity severity;
  final ReportStatus status;
  final String citizenName;
  final String citizenPhone;

  /// Empty list renders the No-Evidence inline empty state.
  final List<String> evidencePhotoUrls;
  final String locationLabel;
  final List<ReportTimelineStep> timeline;

  /// Placeholder content matching the approved MUN-003 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  factory ReportReviewData.mock({bool withEvidence = true}) {
    return ReportReviewData(
      referenceId: 'REQ-8421',
      title: 'Pothole on Main St.',
      description:
          'Large pothole in the right lane near the intersection of Main '
          'St and 4th Ave. Causing vehicles to swerve into oncoming '
          'traffic.',
      category: ReportCategory.infrastructure,
      severity: ReportSeverity.high,
      status: ReportStatus.submitted,
      citizenName: 'John Smith',
      citizenPhone: '+1 (555) 019-8421',
      evidencePhotoUrls: withEvidence
          ? const ['placeholder-1', 'placeholder-2']
          : const [],
      locationLabel: '4th Ave & Main St, Sector 7',
      timeline: const [
        ReportTimelineStep(
          label: 'Submitted',
          icon: AppIcons.reportVerified,
          state: TimelineStepState.completed,
          timestamp: 'Oct 24, 09:14 AM',
        ),
        ReportTimelineStep(
          label: 'Under Review',
          icon: AppIcons.municipalOfficer,
          state: TimelineStepState.current,
          timestamp: 'Oct 24, 10:02 AM',
        ),
        ReportTimelineStep(
          label: 'Awaiting Assignment',
          icon: AppIcons.success,
          state: TimelineStepState.pending,
        ),
      ],
    );
  }
}
