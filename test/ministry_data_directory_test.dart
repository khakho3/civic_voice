import 'dart:async';

import 'package:civic_voice/features/ministry/services/ministry_data_directory.dart';
import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _report(String id, {String title = 'Drain repair'}) =>
    <String, dynamic>{
      'id': id,
      'publicReference': 'CV-$id',
      'title': title,
      'category': 'SANITATION',
      'status': 'UNDER_REVIEW',
      'location': 'Accra',
      'region': 'greaterAccra',
      'assembly': 'Accra',
      'createdAt': '2026-10-18T12:00:00.000Z',
    };

Map<String, dynamic> _contact(String name) => <String, dynamic>{
  'publicId': 'MO-1',
  'fullName': name,
  'phone': '+233200000000',
  'region': 'greaterAccra',
  'assembly': 'Accra',
};

MinistryDataDirectory _directory({
  required Future<List<Map<String, dynamic>>> Function(String) reportsFetch,
  required Future<List<Map<String, dynamic>>> Function(String) contactsFetch,
  required ValueNotifier<List<IncomingReportItem>> reports,
}) =>
    MinistryDataDirectory.forTesting(
      firebaseAvailable: () => true,
      tokenProvider: () async => 'test-token',
      reportsFetcher: reportsFetch,
      contactsFetcher: contactsFetch,
      reportsNotifier: reports,
    );

Future<void> _settle() async {
  await Future<void>.microtask(() {});
  await Future<void>.microtask(() {});
}

void main() {
  test('a newer successful refresh remains authoritative after an older success',
      () async {
    final olderReports = Completer<List<Map<String, dynamic>>>();
    final olderContacts = Completer<List<Map<String, dynamic>>>();
    final newerReports = Completer<List<Map<String, dynamic>>>();
    final newerContacts = Completer<List<Map<String, dynamic>>>();
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    var requests = 0;
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => requests++ == 0 ? olderReports.future : newerReports.future,
      contactsFetch: (_) => requests == 1 ? olderContacts.future : newerContacts.future,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerReports.complete([_report('newer')]);
    newerContacts.complete([_contact('Newer officer')]);
    await newer;
    olderReports.complete([_report('older')]);
    olderContacts.complete([_contact('Older officer')]);
    await older;

    expect(reports.value.single.referenceId, 'CV-newer');
    expect(directory.performance.regionalLeaders.single.officerName, 'Newer officer');
    expect(directory.state.value, MinistryDataDirectoryState.loaded);
    expect(directory.loading.value, isFalse);
    expect(directory.error.value, isNull);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('an older failure cannot replace a newer success', () async {
    final olderReports = Completer<List<Map<String, dynamic>>>();
    final newerReports = Completer<List<Map<String, dynamic>>>();
    final contacts = Future<List<Map<String, dynamic>>>.value(const []);
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    var requests = 0;
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => requests++ == 0 ? olderReports.future : newerReports.future,
      contactsFetch: (_) => contacts,
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerReports.complete([_report('newer')]);
    await newer;
    olderReports.completeError(StateError('older failed'));
    await expectLater(older, throwsStateError);

    expect(reports.value.single.referenceId, 'CV-newer');
    expect(directory.state.value, MinistryDataDirectoryState.loaded);
    expect(directory.error.value, isNull);
    expect(directory.loading.value, isFalse);
  });

  test('an older success cannot clear a newer failure', () async {
    final olderReports = Completer<List<Map<String, dynamic>>>();
    final newerReports = Completer<List<Map<String, dynamic>>>();
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    var requests = 0;
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => requests++ == 0 ? olderReports.future : newerReports.future,
      contactsFetch: (_) async => const [],
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerReports.completeError(StateError('newer failed'));
    await expectLater(newer, throwsStateError);
    olderReports.complete([_report('older')]);
    await older;

    expect(reports.value, isEmpty);
    expect(directory.state.value, MinistryDataDirectoryState.unavailable);
    expect(directory.error.value, contains('newer failed'));
    expect(directory.loading.value, isFalse);
    expect(directory.hasLiveSnapshot, isFalse);
  });

  test('a latest failure retains a confirmed snapshot as stale', () async {
    final failedReports = Completer<List<Map<String, dynamic>>>();
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    var requests = 0;
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => requests++ == 0
          ? Future<List<Map<String, dynamic>>>.value([_report('confirmed')])
          : failedReports.future,
      contactsFetch: (_) async => const [],
    );
    await directory.refresh();

    final latest = directory.refresh();
    await _settle();
    expect(directory.loading.value, isTrue);
    failedReports.completeError(StateError('latest failed'));
    await expectLater(latest, throwsStateError);

    expect(reports.value.single.referenceId, 'CV-confirmed');
    expect(directory.hasLiveSnapshot, isTrue);
    expect(directory.state.value, MinistryDataDirectoryState.failed);
    expect(directory.error.value, contains('latest failed'));
    expect(directory.loading.value, isFalse);
  });

  test('a successful empty fetch is distinct from an unfetched directory',
      () async {
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) async => const [],
      contactsFetch: (_) async => const [],
    );

    expect(directory.state.value, MinistryDataDirectoryState.unavailable);
    expect(directory.hasLiveSnapshot, isFalse);
    await directory.refresh();

    expect(reports.value, isEmpty);
    expect(directory.state.value, MinistryDataDirectoryState.loaded);
    expect(directory.hasLiveSnapshot, isTrue);
  });

  test('reports and contacts publish together only after both responses arrive',
      () async {
    final reportResponse = Completer<List<Map<String, dynamic>>>();
    final contactResponse = Completer<List<Map<String, dynamic>>>();
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => reportResponse.future,
      contactsFetch: (_) => contactResponse.future,
    );
    String? officerAtReportPublication;
    reports.addListener(() {
      if (reports.value.isNotEmpty) {
        officerAtReportPublication =
            directory.performance.regionalLeaders.single.officerName;
      }
    });

    final refresh = directory.refresh();
    await _settle();
    reportResponse.complete([_report('atomic')]);
    await _settle();
    expect(reports.value, isEmpty);
    expect(directory.hasLiveSnapshot, isFalse);
    expect(directory.state.value, MinistryDataDirectoryState.loading);

    contactResponse.complete([_contact('Atomic officer')]);
    await refresh;
    expect(reports.value.single.referenceId, 'CV-atomic');
    expect(directory.performance.regionalLeaders.single.officerName, 'Atomic officer');
    expect(officerAtReportPublication, 'Atomic officer');
    expect(directory.state.value, MinistryDataDirectoryState.loaded);
  });

  test('only the latest refresh owns loading and session clearing invalidates reads',
      () async {
    final olderReports = Completer<List<Map<String, dynamic>>>();
    final newerReports = Completer<List<Map<String, dynamic>>>();
    final reports = ValueNotifier<List<IncomingReportItem>>(const []);
    var requests = 0;
    final directory = _directory(
      reports: reports,
      reportsFetch: (_) => requests++ == 0 ? olderReports.future : newerReports.future,
      contactsFetch: (_) async => const [],
    );

    final older = directory.refresh();
    await _settle();
    final newer = directory.refresh();
    await _settle();
    newerReports.complete([_report('newer')]);
    await newer;
    expect(directory.loading.value, isFalse);
    olderReports.complete([_report('older')]);
    await older;
    expect(reports.value.single.referenceId, 'CV-newer');

    final pendingReports = Completer<List<Map<String, dynamic>>>();
    final invalidated = _directory(
      reports: ValueNotifier<List<IncomingReportItem>>(const []),
      reportsFetch: (_) => pendingReports.future,
      contactsFetch: (_) async => const [],
    );
    final pending = invalidated.refresh();
    await _settle();
    invalidated.clearSession();
    pendingReports.complete([_report('stale')]);
    await pending;

    expect(invalidated.reports, isEmpty);
    expect(invalidated.hasLiveSnapshot, isFalse);
    expect(invalidated.state.value, MinistryDataDirectoryState.unavailable);
    expect(invalidated.loading.value, isFalse);
  });
}
