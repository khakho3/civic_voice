import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/civic_report.dart';
import '../models/report_draft.dart';
import 'citizen_data_repository.dart';
import '../../../services/api_client.dart';
import '../../../models/region.dart';

export '../models/report_draft.dart';

class ReportCrudService implements ReportsRepository {
  ReportCrudService._();

  static final ReportCrudService instance = ReportCrudService._();

  final StreamController<List<CivicReport>> _reportsController =
      StreamController<List<CivicReport>>.broadcast();

  @override
  final ValueNotifier<List<CivicReport>> reports =
      ValueNotifier<List<CivicReport>>(<CivicReport>[]);

  Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    return token;
  }

  Future<void> refresh() async {
    final raw = await ApiClient.instance.listReports(idToken: await _token());
    _publishReports(raw.map(_fromApi).toList());
  }

  @override
  Stream<List<CivicReport>> watchReports() async* {
    yield List<CivicReport>.unmodifiable(reports.value);
    yield* _reportsController.stream;
  }

  @override
  Stream<CivicReport?> watchReport(String id) async* {
    yield _findReport(reports.value, id);
    try {
      final remote = await getReport(id);
      if (remote != null) yield remote;
    } catch (_) {
      // Preserve the last cached value while offline or in widget tests.
    }
    await for (final updatedReports in watchReports()) {
      yield _findReport(updatedReports, id);
    }
  }

  @override
  Future<List<CivicReport>> listReports() async {
    await refresh();
    return List<CivicReport>.unmodifiable(reports.value);
  }

  @override
  Future<CivicReport?> getReport(String id) async {
    try {
      return _fromApi(
        await ApiClient.instance.getReport(id, idToken: await _token()),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<CivicReport> createReport(ReportDraft draft) async {
    final raw = await ApiClient.instance.createReport(
      idToken: await _token(),
      fields: {
        'title': draft.title.trim().isEmpty
            ? 'Untitled report'
            : draft.title.trim(),
        'description': draft.description.trim(),
        'category': draft.category.trim().isEmpty
            ? 'General'
            : draft.category.trim(),
        'location': draft.location.trim().isEmpty
            ? 'Current GPS location'
            : draft.location.trim(),
        'community': draft.community.trim(),
        if (draft.latitude != null) 'latitude': '${draft.latitude}',
        if (draft.longitude != null) 'longitude': '${draft.longitude}',
        if (draft.region != null) 'region': draft.region!.name,
        if (draft.assembly != null) 'assembly': draft.assembly!,
      },
      photoPaths: draft.photoPaths,
    );
    final report = _fromApi(raw);

    _publishReports(<CivicReport>[report, ...reports.value]);
    return report;
  }

  @override
  Future<CivicReport?> updateReport(
    String id,
    CivicReport updatedReport,
  ) async {
    try {
      final raw = await ApiClient.instance.updateReport(
        id,
        idToken: await _token(),
        fields: {
          'title': updatedReport.title,
          'description': updatedReport.description,
          'category': updatedReport.category,
        },
      );
      final saved = _fromApi(raw);
      _publishReports([
        for (final report in reports.value)
          if (report.id == id) saved else report,
      ]);
      return saved;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<CivicReport?> updateReportStatus(
    String id,
    ReportStatus status,
  ) async {
    final existing = await getReport(id);
    if (existing == null) return null;

    final raw = await ApiClient.instance.updateReport(
      id,
      idToken: await _token(),
      fields: {'status': _statusToApi(status)},
    );
    final updated = _fromApi(raw);
    _publishReports([
      for (final report in reports.value)
        if (report.id == id) updated else report,
    ]);
    return updated;
  }

  @override
  Future<bool> deleteReport(String id) async {
    try {
      await ApiClient.instance.deleteReport(id, idToken: await _token());
      _publishReports(
        reports.value.where((report) => report.id != id).toList(),
      );
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 404) return false;
      rethrow;
    }
  }

  CivicReport? _findReport(List<CivicReport> source, String id) {
    for (final report in source) {
      if (report.id == id) return report;
    }
    return null;
  }

  void _publishReports(List<CivicReport> updatedReports) {
    final immutableReports = List<CivicReport>.unmodifiable(updatedReports);
    reports.value = immutableReports;
    _reportsController.add(immutableReports);
  }

  CivicReport _fromApi(Map<String, dynamic> json) {
    final created = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final urls = (json['photoUrls'] as List? ?? const []).cast<String>();
    return CivicReport(
      id: json['id'] as String,
      referenceNumber:
          json['publicReference'] as String? ?? json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      location: json['location'] as String? ?? '',
      community: json['community'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      region: _region(json['region'] as String?),
      assembly: json['assembly'] as String?,
      photoCount: urls.length,
      photoPaths: urls.map(ApiClient.assetUrl).toList(),
      submittedAt: created,
      rejectionReason: json['rejectionReason'] as String?,
      rejectedAt: DateTime.tryParse(json['rejectedAt'] as String? ?? ''),
      timeLabel: created == null ? '' : _relative(created),
      status: _statusFromApi(json['status'] as String?),
    );
  }
}

Region? _region(String? name) {
  for (final value in Region.values) {
    if (value.name == name) return value;
  }
  return null;
}

ReportStatus _statusFromApi(String? value) => switch (value) {
  'UNDER_REVIEW' => ReportStatus.underReview,
  'ASSIGNED' => ReportStatus.assigned,
  'IN_PROGRESS' => ReportStatus.inProgress,
  'RESOLVED' => ReportStatus.resolved,
  'REJECTED' => ReportStatus.rejected,
  _ => ReportStatus.submitted,
};

String _statusToApi(ReportStatus value) => switch (value) {
  ReportStatus.submitted => 'SUBMITTED',
  ReportStatus.underReview => 'UNDER_REVIEW',
  ReportStatus.assigned => 'ASSIGNED',
  ReportStatus.inProgress => 'IN_PROGRESS',
  ReportStatus.resolved => 'RESOLVED',
  ReportStatus.rejected => 'REJECTED',
};

String _relative(DateTime value) {
  final age = DateTime.now().difference(value.toLocal());
  if (age.inMinutes < 1) return 'Just now';
  if (age.inHours < 1) return '${age.inMinutes}m ago';
  if (age.inDays < 1) return '${age.inHours}h ago';
  return '${age.inDays}d ago';
}
