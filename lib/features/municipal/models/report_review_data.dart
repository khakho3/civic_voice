import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';
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
    required this.status,
    required this.citizenName,
    required this.citizenPhone,
    this.citizenIsGuest = false,
    required this.officerName,
    required this.officerPhone,
    required this.evidencePhotoUrls,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.timeline,
    required this.canCurrentOfficerReview,
    this.confidence,
    this.citizenLowTrust = false,
  });

  final String referenceId;
  final String title;
  final String description;
  final ReportCategory category;
  final ReportStatus status;
  final String citizenName;
  final String? citizenPhone;
  final bool citizenIsGuest;

  bool get canContactCitizen =>
      !citizenIsGuest && (citizenPhone?.trim().isNotEmpty ?? false);

  /// The Municipal Officer this report is currently with — shown with
  /// real Call/Message actions via [OfficerContactRow] so anyone else
  /// looking at the report (Maintenance, another officer) knows who to
  /// reach, now that an assembly can have more than one officer account.
  ///
  /// Matches [OfficerProfile.mock]'s own name/phone — this mock always
  /// shows the signed-in officer as the one assigned. There's no real
  /// "whoever verifies becomes the assigned officer" logic yet — that
  /// needs a real session tied to an [AdminUserItem] (see
  /// `AdminSession`/`MockAuthService`), not just a role, which doesn't
  /// exist for Municipal Officer sessions today.
  final String officerName;
  final String officerPhone;

  /// Empty list renders the No-Evidence inline empty state.
  final List<String> evidencePhotoUrls;
  final String locationLabel;

  /// Real coordinates for the Location section's map — see
  /// `_ReportLocationMap` in `municipal_report_review_screen.dart`.
  final double latitude;
  final double longitude;
  final List<ReportTimelineStep> timeline;
  final bool canCurrentOfficerReview;
  final ReportConfidence? confidence;
  final bool citizenLowTrust;

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
      status: ReportStatus.submitted,
      citizenName: 'John Smith',
      citizenPhone: '+1 (555) 019-8421',
      officerName: 'Alex Johnston',
      officerPhone: '+233 24 555 0142',
      evidencePhotoUrls: withEvidence
          ? const ['placeholder-1', 'placeholder-2']
          : const [],
      locationLabel: '4th Ave & Main St, Sector 7',
      latitude: 5.5600,
      longitude: -0.2050,
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
      canCurrentOfficerReview: true,
      confidence: const ReportConfidence(
        score: 75,
        baseScore: 67,
        seconderContribution: 8,
        seconderCount: 2,
        hasLiveCameraPhoto: true,
        photoCount: 2,
        liveGpsDistanceMeters: 42,
        photoExifDistanceMeters: 86,
      ),
    );
  }

  factory ReportReviewData.fromReport(IncomingReportItem report) {
    return ReportReviewData(
      referenceId: report.referenceId,
      title: report.title,
      description: report.description,
      category: report.category,
      status: report.status,
      citizenName: report.citizenName ?? 'Citizen',
      citizenPhone: report.citizenPhone,
      citizenIsGuest: report.citizenIsGuest,
      officerName: report.reviewerName ?? 'Not claimed yet',
      officerPhone: report.reviewerPhone ?? 'Contact unavailable',
      evidencePhotoUrls: report.photoUrls,
      locationLabel: report.locationLabel,
      latitude: report.latitude ?? 5.6037,
      longitude: report.longitude ?? -0.1870,
      timeline: [
        ReportTimelineStep(
          label: 'Submitted',
          icon: AppIcons.reportVerified,
          state: report.status == ReportStatus.submitted
              ? TimelineStepState.current
              : TimelineStepState.completed,
          timestamp: report.timeAgo,
        ),
        ReportTimelineStep(
          label: 'Under Review',
          icon: AppIcons.municipalOfficer,
          state: report.status == ReportStatus.submitted
              ? TimelineStepState.pending
              : report.status == ReportStatus.underReview
              ? TimelineStepState.current
              : TimelineStepState.completed,
          timestamp: report.status == ReportStatus.submitted
              ? null
              : report.updatedLabel,
        ),
        ReportTimelineStep(
          label: 'Team Assignment',
          icon: AppIcons.success,
          state:
              report.status == ReportStatus.submitted ||
                  report.status == ReportStatus.underReview
              ? TimelineStepState.pending
              : TimelineStepState.current,
          timestamp: report.teamName,
        ),
      ],
      canCurrentOfficerReview: report.canCurrentOfficerReview,
      confidence: report.confidence,
      citizenLowTrust: report.citizenLowTrust,
    );
  }
}
