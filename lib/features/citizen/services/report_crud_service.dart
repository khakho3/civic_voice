import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:native_exif/native_exif.dart';

import '../models/civic_report.dart';
import '../models/report_draft.dart';
import 'citizen_data_repository.dart';
import '../../../services/api_client.dart';
import '../../../models/region.dart';
import 'report_submission_store.dart';
import '../../../services/app_cache_service.dart';

export '../models/report_draft.dart';

class ReportCrudService implements ReportsRepository {
  ReportCrudService._();

  @visibleForTesting
  ReportCrudService.forTesting({
    required String? Function() account,
    required Future<String> Function() token,
    required ReportSubmissionStore store,
    Future<Map<String, dynamic>> Function(ReportDraft)? send,
  }) : _testAccount = account,
       _testToken = token,
       _testStore = store,
       _testSend = send;

  String? Function()? _testAccount;
  Future<String> Function()? _testToken;
  ReportSubmissionStore? _testStore;
  Future<Map<String, dynamic>> Function(ReportDraft)? _testSend;
  String? _account() => _testAccount != null
      ? _testAccount!()
      : FirebaseAuth.instance.currentUser?.uid;

  static final ReportCrudService instance = ReportCrudService._();
  int _sessionGeneration = 0;
  final Map<String, Future<CivicReport>> _submissions = {};

  final StreamController<List<CivicReport>> _reportsController =
      StreamController<List<CivicReport>>.broadcast();

  @override
  final ValueNotifier<List<CivicReport>> reports =
      ValueNotifier<List<CivicReport>>(<CivicReport>[]);

  Future<String> _token() async {
    if (_testToken != null) return _testToken!();
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    return token;
  }

  Future<void> refresh() async {
    final identity = _account(), generation = _sessionGeneration;
    final token = await _token();
    if (identity != _account() || generation != _sessionGeneration) return;
    final raw = await ApiClient.instance.listReports(idToken: token);
    if (identity != _account() || generation != _sessionGeneration) return;
    _publishReports(raw.map(_fromApi).toList());
  }

  void clearSession() {
    _sessionGeneration++;
    _publishReports(const <CivicReport>[]);
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
  Future<CivicReport> createReport(
    ReportDraft draft, {
    double? submissionLatitude,
    double? submissionLongitude,
  }) async {
    final owner = _account();
    if (owner == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    final active = _submissions[owner];
    if (active != null) return active;
    final task = _createReport(
      owner,
      _sessionGeneration,
      draft,
      submissionLatitude: submissionLatitude,
      submissionLongitude: submissionLongitude,
    );
    _submissions[owner] = task;
    try {
      return await task;
    } finally {
      _submissions.remove(owner);
    }
  }

  Future<CivicReport> _createReport(
    String owner,
    int generation,
    ReportDraft requested, {
    double? submissionLatitude,
    double? submissionLongitude,
  }) async {
    void checkAccount() {
      if (generation != _sessionGeneration || _account() != owner) {
        throw const ApiException(
          statusCode: 401,
          message: 'Account changed. Sign in again to check your submission.',
        );
      }
    }

    final token = await _token();
    checkAccount();
    final store = _testStore ?? ReportSubmissionStore.instance;
    final previous = await store.pending(owner);
    final draft = await store.prepare(owner, requested);
    await store.verifyEvidence(draft);
    checkAccount();
    final photoExif = await _firstPhotoExif(draft.photoPaths);
    checkAccount();
    late final Map<String, dynamic> raw;
    try {
      raw = _testSend != null
          ? await _testSend!(draft)
          : await ApiClient.instance.createReport(
              idToken: token,
              fields: {
                'submissionKey': draft.submissionKey!,
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
                // Routing is derived server-side from this report's issue pin,
                // never from account locality or geocoder display hints.
                if (submissionLatitude != null)
                  'submissionLatitude': '$submissionLatitude',
                if (submissionLongitude != null)
                  'submissionLongitude': '$submissionLongitude',
                'hasLiveCameraPhoto':
                    '${draft.photoIsFromCamera.any((isFromCamera) => isFromCamera)}',
                if (photoExif != null) ...{
                  'photoExifLatitude': '${photoExif.latitude}',
                  'photoExifLongitude': '${photoExif.longitude}',
                  if (photoExif.capturedAt != null)
                    'photoExifCapturedAt': photoExif.capturedAt!
                        .toIso8601String(),
                },
              },
              photoPaths: draft.photoPaths,
            );
    } on ApiException catch (error) {
      // A first, definitive rejection did not save a report. Once a response
      // was uncertain, even a later rejection cannot discard that old intent.
      if (previous == null &&
          const [400, 401, 403, 422, 429].contains(error.statusCode)) {
        await store.acknowledge(owner, draft.submissionKey!);
      }
      rethrow;
    }
    checkAccount();
    final report = _fromApi(raw);
    // Clear the editable source first: a crash between these operations must
    // leave a replayable receipt, never an old draft eligible for a new key.
    await AppCacheService.instance.clearReportDraft(expectedAccount: owner);
    await store.acknowledge(owner, draft.submissionKey!);
    checkAccount();
    _publishReports(<CivicReport>[
      report,
      ...reports.value.where((item) => item.id != report.id),
    ]);
    return report;
  }

  Future<_PhotoExifData?> _firstPhotoExif(List<String> photoPaths) async {
    for (final path in photoPaths) {
      Exif? exif;
      try {
        exif = await Exif.fromPath(path);
        final coordinates = await exif.getLatLong();
        if (coordinates == null) continue;
        return _PhotoExifData(
          latitude: coordinates.latitude,
          longitude: coordinates.longitude,
          capturedAt: await exif.getOriginalDate(),
        );
      } catch (_) {
        // Missing/invalid EXIF is explicitly neutral and never blocks a report.
      } finally {
        if (exif != null) {
          try {
            await exif.close();
          } catch (_) {}
        }
      }
    }
    return null;
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
      assignedAt: DateTime.tryParse(json['assignedAt'] as String? ?? ''),
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      completionSubmittedAt: DateTime.tryParse(
        json['completionSubmittedAt'] as String? ?? '',
      ),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      sendBackReason: json['sendBackReason'] as String?,
      hasMunicipalCoverage: json['hasMunicipalCoverage'] as bool?,
    );
  }
}

class _PhotoExifData {
  const _PhotoExifData({
    required this.latitude,
    required this.longitude,
    this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime? capturedAt;
}

Region? _region(String? name) {
  for (final value in Region.values) {
    if (value.name == name) return value;
  }
  return null;
}

ReportStatus _statusFromApi(String? value) => ReportStatus.fromApi(value);

String _statusToApi(ReportStatus value) => switch (value) {
  ReportStatus.submitted => 'SUBMITTED',
  ReportStatus.underReview => 'UNDER_REVIEW',
  ReportStatus.assigned => 'ASSIGNED',
  ReportStatus.inProgress => 'IN_PROGRESS',
  ReportStatus.pendingApproval => 'PENDING_APPROVAL',
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
