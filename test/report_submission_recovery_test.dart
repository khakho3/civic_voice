import 'dart:async';
import 'dart:io';

import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/citizen/services/report_submission_store.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ReportSubmissionStore store;
  late ReportDraft draft;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'alice');
    root = await Directory.systemTemp.createTemp('cv-receipt-test-');
    store = ReportSubmissionStore(directory: () async => root);
    final a = await File('${root.path}/a.jpg').writeAsBytes([1, 2, 3]);
    final b = await File('${root.path}/b.jpg').writeAsBytes([4, 5, 6]);
    draft = ReportDraft(
      title: 'Blocked drain',
      description: 'Drain is overflowing',
      category: 'Sanitation',
      location: 'Selected pin',
      community: 'Test area',
      latitude: 5.6,
      longitude: -0.2,
      photoPaths: [a.path, b.path],
      photoIsFromCamera: [true, false],
    );
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  Map<String, dynamic> report() => {
    'id': 'report-1',
    'publicReference': 'CV-2026-000001',
    'title': 'Blocked drain',
    'status': 'UNDER_REVIEW',
    'photos': <Object>[],
  };

  test(
    'freeze survives source deletion/restart, account isolation and double prepare',
    () async {
      final both = await Future.wait([
        store.prepare('alice', draft),
        store.prepare('alice', draft),
      ]);
      final saved = both.first;
      expect(both.last.submissionKey, saved.submissionKey);
      expect(saved.submissionKey, matches(RegExp(r'^[a-f0-9]{48}$')));
      await File(draft.photoPaths.first).delete();
      final reopened = ReportSubmissionStore(directory: () async => root);
      final retry = await reopened.prepare(
        'alice',
        draft.copyWith(title: 'Different edit'),
      );
      expect(retry.title, draft.title);
      expect(retry.photoIsFromCamera, [true, false]);
      expect(await File(retry.photoPaths.first).readAsBytes(), [1, 2, 3]);
      expect(await reopened.pending('bob'), isNull);
      await reopened.acknowledge('bob', saved.submissionKey!);
      await reopened.acknowledge('alice', 'wrong-key');
      expect(await reopened.pending('alice'), isNotNull);
      await reopened.verifyEvidence(retry);
    },
  );

  test(
    'missing frozen evidence blocks retry without rotating intent',
    () async {
      final saved = await store.prepare('alice', draft);
      await File(saved.photoPaths.last).delete();
      final retry = await store.prepare('alice', draft);
      await expectLater(store.verifyEvidence(retry), throwsFormatException);
      expect(
        (await store.pending('alice'))!.submissionKey,
        saved.submissionKey,
      );
    },
  );

  test(
    'missing initial evidence sends nothing and leaves no pending receipt',
    () async {
      await File(draft.photoPaths.first).delete();
      await expectLater(
        store.prepare('alice', draft),
        throwsA(isA<FileSystemException>()),
      );
      expect(await store.pending('alice'), isNull);
    },
  );

  test(
    'uncertain save replays exact frozen intent and upserts advanced report',
    () async {
      var sends = 0;
      String? key;
      final response = Completer<Map<String, dynamic>>();
      final service = ReportCrudService.forTesting(
        account: () => 'alice',
        token: () async => 'token',
        store: store,
        send: (frozen) async {
          sends++;
          if (sends == 1) {
            key = frozen.submissionKey;
            return response.future;
          }
          expect(frozen.submissionKey, key);
          expect(frozen.title, draft.title);
          return report();
        },
      );
      final first = service.createReport(draft);
      final concurrent = service.createReport(draft);
      // Wait for the actual send, not a fixed timer or plugin frame count.
      while (sends == 0) {
        await Future<void>.delayed(Duration.zero);
      }
      response.completeError(
        const ApiException(statusCode: 408, message: 'timeout'),
      );
      await expectLater(first, throwsA(isA<ApiException>()));
      await expectLater(concurrent, throwsA(isA<ApiException>()));
      expect(sends, 1);
      expect(await store.pending('alice'), isNotNull);
      final recovered = await service.createReport(
        draft.copyWith(title: 'Changed'),
      );
      expect(recovered.id, 'report-1');
      expect(service.reports.value.length, 1);
      expect(await store.pending('alice'), isNull);
    },
  );

  for (final code in [409, 410, 503]) {
    test('HTTP $code never rotates or drops an uncertain intent', () async {
      final saved = await store.prepare('alice', draft);
      final service = ReportCrudService.forTesting(
        account: () => 'alice',
        token: () async => 'token',
        store: store,
        send: (_) async {
          throw ApiException(statusCode: code, message: 'not acknowledged');
        },
      );
      await expectLater(
        service.createReport(draft),
        throwsA(isA<ApiException>()),
      );
      expect(
        (await store.pending('alice'))!.submissionKey,
        saved.submissionKey,
      );
      expect(service.reports.value, isEmpty);
    });
  }

  test(
    'late response after account change preserves old receipt, publishes nothing',
    () async {
      String? owner = 'alice';
      final response = Completer<Map<String, dynamic>>();
      final sent = Completer<void>();
      final service = ReportCrudService.forTesting(
        account: () => owner,
        token: () async => 'token',
        store: store,
        send: (_) {
          sent.complete();
          return response.future;
        },
      );
      final result = service.createReport(draft);
      await sent.future;
      owner = 'bob';
      await AppCacheService.instance.activateAccount('bob');
      await AppCacheService.instance.saveReportDraft(
        draft.copyWith(title: 'Bob draft'),
      );
      response.complete(report());
      await expectLater(result, throwsA(isA<ApiException>()));
      expect(service.reports.value, isEmpty);
      expect(AppCacheService.instance.reportDraft!.title, 'Bob draft');
      expect(await store.pending('alice'), isNotNull);
    },
  );

  test('first definitive validation rejection allows correction', () async {
    final service = ReportCrudService.forTesting(
      account: () => 'alice',
      token: () async => 'token',
      store: store,
      send: (_) async {
        throw const ApiException(statusCode: 400, message: 'Invalid title');
      },
    );
    await expectLater(
      service.createReport(draft),
      throwsA(isA<ApiException>()),
    );
    expect(await store.pending('alice'), isNull);
  });

  test(
    'receipt validation accepts replay at advanced lifecycle only with matching identity',
    () {
      const key = 'client_submission_12345';
      expect(
        ApiClient.validateReportReceipt({
          'submission': {'key': key, 'replayed': true},
          'report': report(),
        }, key)['id'],
        'report-1',
      );
      for (final bad in <Map<String, dynamic>>[
        {'report': report()},
        {
          'submission': {'key': 'other', 'replayed': true},
          'report': report(),
        },
        {
          'submission': {'key': key, 'replayed': 'true'},
          'report': report(),
        },
        {
          'submission': {'key': key, 'replayed': false},
          'report': {'id': 'report-1'},
        },
        {
          'submission': {'key': key, 'replayed': false},
          'report': {'id': '', 'publicReference': 'CV-1'},
        },
      ]) {
        expect(
          () => ApiClient.validateReportReceipt(bad, key),
          throwsA(isA<ApiException>()),
        );
      }
    },
  );
}
