import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/civic_report.dart';
import '../models/report_draft.dart';
import 'citizen_data_repository.dart';

export '../models/report_draft.dart';

class ReportCrudService implements ReportsRepository {
  ReportCrudService._();

  static final ReportCrudService instance = ReportCrudService._();

  final StreamController<List<CivicReport>> _reportsController =
      StreamController<List<CivicReport>>.broadcast();

  @override
  final ValueNotifier<List<CivicReport>> reports =
      ValueNotifier<List<CivicReport>>(<CivicReport>[]);

  int _nextReferenceNumber = 4582;

  @override
  Stream<List<CivicReport>> watchReports() async* {
    yield List<CivicReport>.unmodifiable(reports.value);
    yield* _reportsController.stream;
  }

  @override
  Stream<CivicReport?> watchReport(String id) async* {
    yield await getReport(id);
    await for (final updatedReports in watchReports()) {
      yield _findReport(updatedReports, id);
    }
  }

  @override
  Future<List<CivicReport>> listReports() async {
    return List<CivicReport>.unmodifiable(reports.value);
  }

  @override
  Future<CivicReport?> getReport(String id) async {
    return _findReport(reports.value, id);
  }

  @override
  Future<CivicReport> createReport(ReportDraft draft) async {
    final now = DateTime.now();
    final report = CivicReport(
      id: _createReference(now),
      title: draft.title.trim().isEmpty ? 'Untitled report' : draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category.trim().isEmpty
          ? 'General'
          : draft.category.trim(),
      location: draft.location.trim().isEmpty
          ? 'Current GPS location'
          : draft.location.trim(),
      community: draft.community.trim(),
      latitude: draft.latitude,
      longitude: draft.longitude,
      photoCount: draft.photoCount,
      submittedAt: now,
      timeLabel: 'Just now',
      status: ReportStatus.submitted,
    );

    _publishReports(<CivicReport>[report, ...reports.value]);
    return report;
  }

  @override
  Future<CivicReport?> updateReport(String id, CivicReport updatedReport) async {
    var changed = false;
    final updated = <CivicReport>[
      for (final report in reports.value)
        if (report.id == id) ...[
          updatedReport.copyWith(id: id),
        ] else ...[
          report,
        ],
    ];

    changed = updated.any((report) => report.id == id);
    if (!changed) return null;

    _publishReports(updated);
    return updated.firstWhere((report) => report.id == id);
  }

  @override
  Future<CivicReport?> updateReportStatus(String id, ReportStatus status) async {
    final existing = await getReport(id);
    if (existing == null) return null;

    return updateReport(id, existing.copyWith(status: status));
  }

  @override
  Future<bool> deleteReport(String id) async {
    final updated = reports.value.where((report) => report.id != id).toList();
    if (updated.length == reports.value.length) return false;

    _publishReports(updated);
    return true;
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

  String _createReference(DateTime submittedAt) {
    final year = submittedAt.year.toString();
    final serial = _nextReferenceNumber.toString().padLeft(6, '0');
    _nextReferenceNumber += 1;
    return 'CV-$year-$serial';
  }
}
