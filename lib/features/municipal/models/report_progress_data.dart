import '../../../models/report_status.dart';
import 'incoming_report.dart';

/// One entry in the Status Timeline card.
class ProgressTimelineStep {
  const ProgressTimelineStep({
    required this.label,
    required this.timestamp,
    required this.description,
    this.isCurrent = false,
  });

  final String label;
  final String timestamp;
  final String description;

  /// The in-progress/"LIVE" step — rendered with the primary highlight
  /// instead of the completed-step treatment.
  final bool isCurrent;
}

/// One entry in the Offline state's "Recent Activity (Cached)" log.
class ActivityLogEntry {
  const ActivityLogEntry({
    required this.timeAgo,
    required this.label,
    required this.description,
  });

  final String timeAgo;
  final String label;
  final String description;
}

/// The case-recap card shown on the Success state after resolving.
class CaseSummary {
  const CaseSummary({
    required this.referenceId,
    required this.title,
    required this.resolutionDate,
    required this.reporterName,
    required this.evidencePhotoCount,
  });

  final String referenceId;
  final String title;
  final String resolutionDate;
  final String reporterName;
  final int evidencePhotoCount;
}

/// Full data payload for MUN-007 Report Progress.
class ReportProgressData {
  const ReportProgressData({
    required this.referenceId,
    required this.title,
    required this.districtLabel,
    required this.officerName,
    required this.officerPhone,
    required this.status,
    required this.completionPercent,
    required this.timeline,
    required this.latestUpdateTeam,
    required this.latestUpdateTimeAgo,
    required this.latestUpdateNote,
    required this.cachedActivity,
    required this.caseSummary,
  });

  final String referenceId;
  final String title;
  final String districtLabel;
  final String officerName;

  /// E.164-ish Ghana mobile format (e.g. "+233 24 555 0123") — same format
  /// `tel:`/`sms:` URIs expect, so it can be handed straight to
  /// [OfficerContactRow] with no reformatting.
  final String officerPhone;
  final ReportStatus status;
  final int completionPercent;
  final List<ProgressTimelineStep> timeline;
  final String latestUpdateTeam;
  final String latestUpdateTimeAgo;
  final String latestUpdateNote;

  /// Shown only in the Offline state.
  final List<ActivityLogEntry> cachedActivity;
  final CaseSummary caseSummary;

  /// Placeholder content matching the approved MUN-007 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  ///
  /// This is the same pothole report followed through Report Review →
  /// Verification → Assign Team → Active Reports (assigned to Unit Alpha
  /// there, which the approved frame's own timeline/update note confirm —
  /// "Unit Alpha dispatched", "2h ago · Unit Alpha") — so [referenceId] is
  /// corrected from the frame's own "MUN-10293" to the established
  /// `REQ-8421`, and the header subtitle format to match the other three
  /// detail screens ("#REQ-8421" rather than "REF MUN-10293").
  ///
  /// The Success state's case-recap card and the Offline state's cached
  /// activity log showed content for an entirely different, unrelated case
  /// in the approved frame (a "Street Light Outage" resolution, and
  /// compliance/facility-permit log entries) — reads as leftover content
  /// from a different mockup rather than this screen's own report, so both
  /// are replaced with entries that are actually about this report.
  factory ReportProgressData.mock() {
    return const ReportProgressData(
      referenceId: 'REQ-8421',
      title: 'Main St. Pothole Repair',
      districtLabel: 'North District, Zone 4',
      officerName: 'Alex Johnston',
      officerPhone: '+233 24 555 0142',
      status: ReportStatus.inProgress,
      completionPercent: 65,
      timeline: [
        ProgressTimelineStep(
          label: 'Submitted',
          timestamp: 'Oct 24, 08:30',
          description: 'Citizen report received via CivicVoice app.',
        ),
        ProgressTimelineStep(
          label: 'Verified',
          timestamp: 'Oct 24, 10:15',
          description: 'Officer J. Smith approved the request.',
        ),
        ProgressTimelineStep(
          label: 'Assigned',
          timestamp: 'Oct 25, 09:00',
          description: 'Unit Alpha dispatched with equipment.',
        ),
        ProgressTimelineStep(
          label: 'In Progress',
          timestamp: 'Today, 11:45',
          description: 'Patching in progress on main section.',
          isCurrent: true,
        ),
      ],
      latestUpdateTeam: 'Unit Alpha',
      latestUpdateTimeAgo: '2h ago',
      latestUpdateNote:
          'Patching in progress. Applying cold-mix asphalt to main '
          'section. Leveling completed for 60% of the area.',
      cachedActivity: [
        ActivityLogEntry(
          timeAgo: 'Just now',
          label: 'Photo Upload — Queued',
          description: 'Evidence photo of completed patching queued for sync.',
        ),
        ActivityLogEntry(
          timeAgo: 'Yesterday',
          label: 'Status Update',
          description: 'Unit Alpha logged progress: 60% leveling complete.',
        ),
        ActivityLogEntry(
          timeAgo: '2 days ago',
          label: 'Assignment Note',
          description: 'Team dispatched with cold-mix asphalt equipment.',
        ),
      ],
      caseSummary: CaseSummary(
        referenceId: 'REQ-8421',
        title: 'Main St. Pothole Repair',
        resolutionDate: 'Oct 25, 2026',
        // Matches Report Review's Citizen Information for this same report.
        reporterName: 'John Smith',
        evidencePhotoCount: 2,
      ),
    );
  }

  factory ReportProgressData.fromReport(IncomingReportItem report) {
    final progress = report.progressPercent ?? 0;
    final team = report.teamName ?? 'Maintenance team not assigned';
    return ReportProgressData(
      referenceId: report.referenceId,
      title: report.title,
      districtLabel: report.assembly ?? report.locationLabel,
      officerName: report.reviewerName ?? 'Reviewing officer unavailable',
      officerPhone: report.reviewerPhone ?? 'Contact unavailable',
      status: report.status,
      completionPercent: progress,
      timeline: [
        ProgressTimelineStep(
          label: 'Submitted',
          timestamp: report.timeAgo,
          description: 'Citizen report received by Civic Voice.',
        ),
        if (report.hasReviewer)
          ProgressTimelineStep(
            label: 'Reviewed',
            timestamp: report.updatedLabel ?? 'Completed',
            description: '${report.reviewerName} reviewed the report.',
          ),
        if (report.teamName != null)
          ProgressTimelineStep(
            label: 'Assigned',
            timestamp: report.updatedLabel ?? 'Assigned',
            description: '$team is responsible for this report.',
            isCurrent: report.status == ReportStatus.assigned,
          ),
        if (report.status == ReportStatus.inProgress)
          ProgressTimelineStep(
            label: 'In Progress',
            timestamp: report.updatedLabel ?? 'In progress',
            description: '$team reported $progress% completion.',
            isCurrent: true,
          ),
      ],
      latestUpdateTeam: team,
      latestUpdateTimeAgo: report.updatedLabel ?? 'No update yet',
      latestUpdateNote:
          report.resolutionNotes ??
          (report.status == ReportStatus.assigned
              ? 'The assigned team has not posted a progress update yet.'
              : 'Current completion reported at $progress%.'),
      cachedActivity: const [],
      caseSummary: CaseSummary(
        referenceId: report.referenceId,
        title: report.title,
        resolutionDate: report.status == ReportStatus.resolved
            ? (report.updatedAt ?? DateTime.now())
                  .toLocal()
                  .toString()
                  .split(' ')
                  .first
            : 'Not resolved',
        reporterName: report.citizenName ?? 'Citizen',
        evidencePhotoCount: report.resolutionPhotoUrls.length,
      ),
    );
  }
}
