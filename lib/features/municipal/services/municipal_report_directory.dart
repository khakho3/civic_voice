import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../models/report_status.dart';
import '../../../services/api_client.dart';
import '../models/incoming_report.dart';
import '../models/verification_data.dart';

/// The live, shared report list every Municipal screen reads from — the
/// same "single source of truth" pattern as `AdminUserDirectory`/
/// `MaintenanceTeamDirectory`. Verifying or assigning a team here is what
/// actually moves a report between Inbox and Active Reports, instead of
/// each screen holding its own disconnected mock snapshot.
class MunicipalReportDirectory {
  MunicipalReportDirectory._();

  static final MunicipalReportDirectory instance = MunicipalReportDirectory._();

  final ValueNotifier<List<IncomingReportItem>> reports = ValueNotifier(
    Firebase.apps.isEmpty
        ? IncomingReportItem.mock()
        : const <IncomingReportItem>[],
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;
  final Set<String> changedReferences = {};
  final Map<String, Set<int>> verificationDrafts = {};
  int _sessionRevision = 0;
  int _refreshRevision = 0;
  void clearSession() {
    ++_sessionRevision;
    ++_refreshRevision;
    reports.value = const [];
    loading.value = false;
    error.value = null;
    hasLiveSnapshot = false;
    verificationDrafts.clear();
    changedReferences.clear();
  }

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    final revision = _sessionRevision, refresh = ++_refreshRevision;
    final identity = FirebaseAuth.instance.currentUser;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in officer is required');
    loading.value = true;
    error.value = null;
    try {
      final response = await ApiClient.instance.listReports(idToken: token);
      if (revision != _sessionRevision ||
          refresh != _refreshRevision ||
          identity?.uid != FirebaseAuth.instance.currentUser?.uid) {
        return;
      }
      reports.value = response.map(IncomingReportItem.fromApi).toList();
      hasLiveSnapshot = true;
    } catch (exception) {
      if (revision == _sessionRevision && refresh == _refreshRevision) {
        error.value = exception.toString();
      }
      rethrow;
    } finally {
      if (revision == _sessionRevision && refresh == _refreshRevision) {
        loading.value = false;
      }
    }
  }

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
    changedReferences.add(referenceId);
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
  void reject(String referenceId, String reason) {
    _update(
      referenceId,
      (r) => r.copyWith(
        status: ReportStatus.rejected,
        rejectionReason: reason,
        rejectedAt: DateTime.now(),
      ),
    );
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

  Future<void> approveCompletion(String referenceId) async {
    final report = byReferenceId(referenceId);
    if (report?.status != ReportStatus.pendingApproval) {
      throw StateError('This completion is no longer pending');
    }
    await _updateOnServer(referenceId, const {'status': 'RESOLVED'});
  }

  Future<void> sendBackCompletion(String referenceId, String reason) async {
    if (byReferenceId(referenceId)?.status != ReportStatus.pendingApproval) {
      throw StateError('This completion is no longer pending');
    }
    final clean = reason.trim();
    if (clean.isEmpty || clean.length > 1000) {
      throw ArgumentError(
        'Use between 1 and 1000 characters for the return reason',
      );
    }
    await _updateOnServer(referenceId, {
      'status': 'IN_PROGRESS',
      'sendBackReason': clean,
    });
  }

  Future<void> verifyOnServer(String referenceId) async {
    await _updateOnServer(referenceId, const {'status': 'UNDER_REVIEW'});
  }

  Future<void> rejectOnServer(
    String referenceId,
    String reason,
    QuickRejectionReason? category,
  ) => _updateOnServer(referenceId, {
    'status': 'REJECTED',
    'rejectionReason': reason,
    if (category != null) 'rejectionCategory': category.apiValue,
  });

  Future<IncomingReportItem> claimReviewOnServer(String referenceId) async {
    final revision = _sessionRevision;
    final current = byReferenceId(referenceId);
    if (current == null) throw StateError('Report not found');
    if (current.hasReviewer) return current;
    if (Firebase.apps.isEmpty) return current;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in officer is required');
    final response = await ApiClient.instance.claimReportReview(
      current.apiRecordId,
      idToken: token,
    );
    if (revision != _sessionRevision) throw StateError('Your session changed');
    ++_refreshRevision;
    final updated = IncomingReportItem.fromApi(response);
    _update(referenceId, (_) => updated);
    return updated;
  }

  Future<void> assignTeamOnServer(
    String referenceId,
    String teamId,
    String teamName,
  ) => _updateOnServer(referenceId, {
    'status': 'ASSIGNED',
    'assignedTeamId': teamId,
    'assignedTeamName': teamName,
  });

  Future<void> _updateOnServer(
    String referenceId,
    Map<String, String> fields,
  ) async {
    final revision = _sessionRevision;
    final current = byReferenceId(referenceId);
    if (current == null) throw StateError('Report not found');
    if (Firebase.apps.isEmpty) {
      // The explicit Test Role Selector has no Firebase session. Keep that
      // development/test surface deterministic without allowing production
      // sessions to silently fall back when the real API fails.
      switch (fields['status']) {
        case 'UNDER_REVIEW':
          verify(referenceId);
        case 'REJECTED':
          reject(referenceId, fields['rejectionReason'] ?? 'Not actionable');
        case 'ASSIGNED':
          assignTeam(referenceId, fields['assignedTeamName'] ?? 'Assigned');
        case 'RESOLVED':
          _update(
            referenceId,
            (r) => r.copyWith(
              status: ReportStatus.resolved,
              approvedAt: DateTime.now(),
              clearSendBack: true,
            ),
          );
        case 'IN_PROGRESS':
          _update(
            referenceId,
            (r) => r.copyWith(
              status: ReportStatus.inProgress,
              sendBackReason: fields['sendBackReason'],
            ),
          );
      }
      return;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in officer is required');
    final response = await ApiClient.instance.updateReport(
      current.apiRecordId,
      idToken: token,
      fields: fields,
    );
    if (revision != _sessionRevision) throw StateError('Your session changed');
    ++_refreshRevision;
    final updated = IncomingReportItem.fromApi(response);
    _update(referenceId, (_) => updated);
  }
}
