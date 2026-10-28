import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_audit.dart';
import 'package:civic_voice/features/admin/services/admin_activity_repository.dart';
import 'package:civic_voice/features/admin/services/admin_read_failure.dart';
import 'package:civic_voice/services/api_client.dart';

Map<String, dynamic> auditFixture({
  String id = 'event-one',
  String outcome = 'UNKNOWN',
}) => {
  'schemaVersion': 1,
  'id': id,
  'action': 'USER_UPDATED',
  'title': 'Account access updated',
  'description': 'Recorded account update.',
  'createdAt': '2026-10-28T10:23:45.123Z',
  'category': 'USER_MODIFICATION',
  'severity': 'STANDARD',
  'tag': 'Administration',
  'outcome': outcome,
  'actorId': null,
  'actorPublicId': 'CV-ADMIN-42',
  'actorName': 'Recorded administrator',
  'actorRole': 'ADMIN',
  'region': 'greaterAccra',
  'assembly': 'Ga Central',
  'subjectType': 'USER',
  'subjectId': 'removed-target',
  'metadata': {
    'previousObservedRole': 'MAINTENANCE_TEAM',
    'role': 'MUNICIPAL_OFFICER',
    'previousObservedActive': true,
    'active': false,
    'teamId': null,
    'token': 'secret-token',
    'password': 'secret-password',
    'body': {'otp': '123456'},
  },
};
Map<String, dynamic> auditPageFixture({
  String id = 'event-one',
  String? cursor,
  int total = 501,
}) => {
  'activity': [auditFixture(id: id)],
  'total': total,
  'alertCount': 17,
  'collectionEnabled': false,
  'pageInfo': {'limit': 50, 'hasMore': cursor != null, 'nextCursor': cursor},
};

void main() {
  test(
    'audit preserves historical snapshots, UNKNOWN, false and explicit removals',
    () {
      final event = AuditEvent.parse(auditFixture());
      expect(event.outcome, 'UNKNOWN');
      expect(event.fields['actorId'], isNull);
      expect(event.fields['actorName'], 'Recorded administrator');
      expect(event.context['active'], false);
      expect(event.context.containsKey('teamId'), true);
      expect(event.context['teamId'], isNull);
      expect(event.context.keys, isNot(contains('password')));
      expect(event.context.keys, isNot(contains('token')));
      expect(event.context.keys, isNot(contains('body')));
      expect(auditTimestamp(event.item.timestamp), '2026-10-28 10:23:45 UTC');
      expect(
        AuditEvent.parse({...auditFixture(), 'outcome': null}).outcome,
        'UNKNOWN',
      );
      for (final outcome in ['SUCCESS', 'FAILED', 'DENIED']) {
        expect(
          AuditEvent.parse(auditFixture(outcome: outcome)).outcome,
          outcome,
        );
      }
    },
  );
  test(
    'context is event-specific, bounded and scalar; unknown actions disclose none',
    () {
      expect(safeAuditContext('UNKNOWN_EVENT', {'reason': 'private'}), isEmpty);
      expect(
        safeAuditContext('USER_UPDATED', {
          'role': {'token': 'private'},
          'active': 'true',
        }),
        isEmpty,
      );
      expect(
        safeAuditContext('AUTH_LOGIN_SUCCESS', {
          'provider': 'password',
          'token': 'private',
        }),
        {'provider': 'password'},
      );
      expect(
        safeAuditContext('REPORT_UPDATED', {
          'progressPercent': 0,
          'seconderCount': double.nan,
        }),
        {'progressPercent': 0},
      );
      expect(
        safeAuditContext('USER_UPDATED', {
          'role': List.filled(201, 'a').join(),
        }),
        isEmpty,
      );
      expect(
        safeAuditContext('REPORT_LOCALITY_RESOLVED', {
          'reason': 'Issue pin checked',
          'note': 'private',
        }),
        {'reason': 'Issue pin checked'},
      );
    },
  );
  test('malformed events never become verified detail', () {
    for (final patch in [
      {'schemaVersion': 2},
      {'id': '../other'},
      {'title': null},
      {'category': 'OTHER'},
      {'severity': 'OTHER'},
      {'outcome': 'MAYBE'},
      {'createdAt': '2026-10-28T10:23:45'},
      {'createdAt': '2026-02-30T10:23:45Z'},
      {
        'actorName': {'password': 'private'},
      },
    ]) {
      expect(
        () => AuditEvent.parse({...auditFixture(), ...patch}),
        throwsFormatException,
      );
    }
  });
  test(
    'pages preserve authoritative counts/history-off and reject corrupt cursors/duplicates',
    () {
      final page = AuditPage.parse(auditPageFixture(cursor: 'next-page'));
      expect(page.total, 501);
      expect(page.alertCount, 17);
      expect(page.collectionEnabled, false);
      expect(page.nextCursor, 'next-page');
      for (final patch in [
        {'alertCount': 999},
        {'collectionEnabled': null},
        {
          'activity': [auditFixture(), auditFixture()],
        },
        {
          'pageInfo': {'limit': 500, 'hasMore': false, 'nextCursor': null},
        },
        {
          'pageInfo': {'limit': 50, 'hasMore': true, 'nextCursor': '../unsafe'},
        },
      ]) {
        expect(
          () => AuditPage.parse({...auditPageFixture(), ...patch}),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'detail rejects unrelated success and distinguishes missing and access denial',
    () async {
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'token',
        read: (_, id) async => {'activity': auditFixture(id: 'other')},
      );
      final source = repo.detail('event-one');
      addTearDown(source.dispose);
      await source.load();
      expect(source.data, isNull);
      expect(source.error, isNotNull);
      for (final status in [404, 403, 401, 503]) {
        final failing = AdminActivityRepository(
          owner: () => 'admin',
          credential: () async => 'token',
          read: (_, _) async => throw ApiException(
            statusCode: status,
            message: 'private server error',
          ),
        ).detail('event-one');
        await failing.load();
        if (status == 404) {
          expect(failing.data?.event, isNull);
          expect(failing.error, isNull);
          expect(failing.data, isNotNull);
        } else {
          expect(failing.error, isNotNull);
          expect(failing.error, isNot(contains('private')));
          expect(
            failing.failure,
            status == 503
                ? AdminReadFailure.service
                : AdminReadFailure.unauthorized,
          );
        }
        failing.dispose();
      }
    },
  );
  test(
    'unauthorized owner, missing token and invalid ID cannot dispatch a detail read',
    () async {
      var reads = 0, credentials = 0;
      String? owner;
      String? token = 'token';
      final repo = AdminActivityRepository(
        owner: () => owner,
        credential: () async {
          credentials++;
          return token;
        },
        read: (_, _) async {
          reads++;
          return {'activity': auditFixture()};
        },
      );
      final source = repo.detail('event-one');
      await source.load();
      expect(credentials, 0);
      owner = 'admin';
      token = null;
      await source.load();
      expect(reads, 0);
      token = '  ';
      await source.load();
      expect(reads, 0);
      token = 'token';
      final invalid = repo.detail('../other');
      await invalid.load();
      expect(reads, 0);
      source.dispose();
      invalid.dispose();
    },
  );
  for (final failure in [false, true]) {
    test(
      'account/scope changes fence delayed detail ${failure ? 'failure' : 'success'}',
      () async {
        String? owner = 'admin-A|assembly-A';
        final pending = Completer<Map<String, dynamic>>();
        final repo = AdminActivityRepository(
          owner: () => owner,
          credential: () async => 'token',
          read: (_, _) => pending.future,
        );
        final source = repo.detail('event-one');
        final load = source.load();
        await Future<void>.delayed(Duration.zero);
        owner = 'admin-B|assembly-B';
        if (failure) {
          pending.completeError(StateError('old account failure'));
        } else {
          pending.complete({'activity': auditFixture()});
        }
        await load;
        expect(source.data, isNull);
        expect(source.error, isNull);
        expect(source.loading, false);
        source.dispose();
      },
    );
  }
  test(
    'logout/relogin fences token waits and loaded records even with the same account key',
    () async {
      var reads = 0;
      final token = Completer<String?>();
      final repo = AdminActivityRepository(
        owner: () => 'same-admin',
        credential: () => token.future,
        read: (_, _) async {
          reads++;
          return {'activity': auditFixture()};
        },
      );
      final source = repo.detail('event-one');
      final load = source.load();
      AdminActivityRepository.invalidateSession();
      token.complete('old-token');
      await load;
      expect(reads, 0);
      expect(source.data, isNull);
      await source.load();
      expect(source.data?.event?.id, 'event-one');
      AdminActivityRepository.invalidateSession();
      expect(source.data, isNull);
      source.dispose();
    },
  );
  test(
    'newest read wins and page queries are immutable across requests',
    () async {
      final old = Completer<Map<String, dynamic>>();
      var calls = 0;
      final repo = AdminActivityRepository(
        owner: () => 'admin',
        credential: () async => 'token',
        read: (_, _) => ++calls == 1
            ? old.future
            : Future.value({'activity': auditFixture(outcome: 'SUCCESS')}),
        list: (_, query) async {
          expect(query['q'], 'original');
          return auditPageFixture();
        },
      );
      final detail = repo.detail('event-one');
      final first = detail.load();
      await Future<void>.delayed(Duration.zero);
      await detail.load();
      old.complete({'activity': auditFixture(outcome: 'FAILED')});
      await first;
      expect(detail.data?.event?.outcome, 'SUCCESS');
      final query = {'q': 'original'};
      final page = repo.page(query);
      query['q'] = 'changed';
      await page.load();
      expect(page.data?.total, 501);
      detail.dispose();
      page.dispose();
    },
  );
}
