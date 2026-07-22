import 'incoming_report.dart';

/// A single item in the Verification Checklist — static content (label +
/// description); completion state is tracked separately by the screen.
class ChecklistItem {
  const ChecklistItem({required this.label, required this.description});

  final String label;
  final String description;
}

/// Quick-select reasons for the "Reason for rejection" field.
enum QuickRejectionReason {
  duplicateReport('Duplicate Report'),
  falseReport('False Report'),
  insufficientEvidence('Insufficient Evidence');

  const QuickRejectionReason(this.label);

  final String label;

  String get apiValue => switch (this) {
    QuickRejectionReason.duplicateReport => 'DUPLICATE_REPORT',
    QuickRejectionReason.falseReport => 'FALSE_REPORT',
    QuickRejectionReason.insufficientEvidence => 'INSUFFICIENT_EVIDENCE',
  };
}

/// Full data payload for MUN-004 Verify / Reject Report.
class VerificationData {
  const VerificationData({
    required this.referenceId,
    required this.title,
    required this.locationSummary,
    required this.category,
    required this.citizenName,
    required this.officerName,
    required this.officerPhone,
    required this.checklist,
    this.confidence,
  });

  final String referenceId;
  final String title;
  final String locationSummary;
  final ReportCategory category;
  final String citizenName;

  /// The Municipal Officer verifying this report — see [OfficerContactRow].
  final String officerName;
  final String officerPhone;
  final List<ChecklistItem> checklist;
  final ReportConfidence? confidence;

  /// Placeholder content matching the approved MUN-004 design, used until
  /// the Cloud Firestore-backed service (Issue 03 dependency) is wired up.
  factory VerificationData.mock() {
    return const VerificationData(
      referenceId: 'REQ-8421',
      title: 'Severe Pothole on Main St.',
      locationSummary: '1200 Block, Main St · Reported 2h ago',
      category: ReportCategory.infrastructure,
      citizenName: 'Eleanor Vance',
      officerName: 'Alex Johnston',
      officerPhone: '+233 24 555 0142',
      checklist: [
        ChecklistItem(
          label: 'Issue confirmed',
          description: 'Description matches evidence',
        ),
        ChecklistItem(
          label: 'Photos reviewed',
          description: 'Visuals confirm the reported issue',
        ),
        ChecklistItem(
          label: 'Location validated',
          description: 'GPS coordinates match landmarks',
        ),
        ChecklistItem(
          label: 'Not duplicate',
          description: 'No open report for the same issue',
        ),
        ChecklistItem(
          label: 'Citizen contacted',
          description: 'Optional — for follow-up questions',
        ),
      ],
      confidence: ReportConfidence(
        score: 75,
        baseScore: 67,
        seconderContribution: 8,
        seconderCount: 2,
      ),
    );
  }

  factory VerificationData.fromReport(IncomingReportItem report) {
    return VerificationData(
      referenceId: report.referenceId,
      title: report.title,
      locationSummary: '${report.locationLabel} · ${report.timeAgo}',
      category: report.category,
      citizenName: report.citizenName ?? 'Citizen',
      officerName: report.citizenName ?? 'Citizen',
      officerPhone: report.citizenPhone ?? 'Phone unavailable',
      checklist: const [
        ChecklistItem(
          label: 'Issue confirmed',
          description: 'Description matches the reported issue',
        ),
        ChecklistItem(
          label: 'Photos reviewed',
          description: 'Available evidence has been reviewed',
        ),
        ChecklistItem(
          label: 'Location validated',
          description: 'Location details match the report',
        ),
        ChecklistItem(
          label: 'Not duplicate',
          description: 'No open duplicate was identified',
        ),
        ChecklistItem(
          label: 'Citizen contacted',
          description: 'Optional — for follow-up questions',
        ),
      ],
      confidence: report.confidence,
    );
  }
}
