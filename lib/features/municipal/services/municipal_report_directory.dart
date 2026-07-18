import 'package:flutter/foundation.dart';

import '../../../models/report_status.dart';
import '../models/incoming_report.dart';

/// The live, shared report list every Municipal screen reads from — the
/// same "single source of truth" pattern as `AdminUserDirectory`/
/// `MaintenanceTeamDirectory`. Verifying or assigning a team here is what
/// actually moves a report between Inbox and Active Reports, instead of
/// each screen holding its own disconnected mock snapshot.
class MunicipalReportDirectory {
  MunicipalReportDirectory._();

  static final MunicipalReportDirectory instance = MunicipalReportDirectory._();

  final ValueNotifier<List<IncomingReportItem>> reports = ValueNotifier(
    IncomingReportItem.mock(),
  );

  IncomingReportItem? byReferenceId(String referenceId) {
    for (final report in reports.value) {
      if (report.referenceId == referenceId) return report;
    }
    return null;
  }

  void _update(
    String referenceId,
    IncomingReportItem Function(IncomingReportItem report) transform,
  ) {
    reports.value = [
      for (final report in reports.value)
        if (report.referenceId == referenceId) transform(report) else report,
    ];
  }

  /// Confirms an Inbox report as legitimate — moves it from "new" to
  /// "reviewed, awaiting a team". Still shown in Inbox: only [assignTeam]
  /// moves a report out of it.
  void verify(String referenceId) {
    _update(referenceId, (r) => r.copyWith(status: ReportStatus.underReview));
  }

  /// Dismisses an Inbox report as not actionable.
  void reject(String referenceId) {
    _update(referenceId, (r) => r.copyWith(status: ReportStatus.rejected));
  }

  /// The real "moves from Inbox to Active" transition — a team taking the
  /// case is what promotes a report out of triage.
  void assignTeam(String referenceId, String teamName) {
    _update(
      referenceId,
      (r) => r.copyWith(
        status: ReportStatus.assigned,
        teamName: teamName,
        progressPercent: 0,
        updatedLabel: 'Just now',
      ),
    );
  }
}
