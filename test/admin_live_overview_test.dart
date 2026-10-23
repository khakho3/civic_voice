import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';

Map<String, dynamic> overviewFixture() => {
  'totalUsers': 1234,
  'activeRoles': 5,
  'auditEvents24h': 601,
  'alertEvents': 80,
  'openAlertEvents': 7,
  'acknowledgedAlertEvents': 2,
  'collectionEnabled': false,
  'checkedAt': '2026-10-23T12:00:00Z',
  'window': {'from': '2026-10-22T12:00:00Z', 'to': '2026-10-23T12:00:00Z'},
  'recentActivity': [],
};
Map<String, dynamic> alertFixture({String state = 'OPEN', int revision = 0}) =>
    {
      'id': 'event-one',
      'title': 'System setting changed',
      'description': 'A configuration was updated.',
      'severity': 'ALERT',
      'createdAt': '2026-10-23T10:00:00Z',
      'review': {
        'state': state,
        'revision': revision,
        'updatedAt': revision == 0 ? null : '2026-10-23T12:00:00Z',
      },
    };
void main() {
  test('overview uses server totals beyond bounded directory/feed sizes', () {
    final value = AdminOverview.parse(overviewFixture());
    expect(value.totalUsers, 1234);
    expect(value.auditEvents24h, 601);
    expect(value.openAlerts, 7);
    expect(value.collectionEnabled, isFalse);
  });
  for (final mutate in <void Function(Map<String, dynamic>)>[
    (r) => r['openAlertEvents'] = -1,
    (r) => r['acknowledgedAlertEvents'] = 8,
    (r) => r['activeRoles'] = 6,
    (r) => r['checkedAt'] = 'wrong',
    (r) => r['window'] = {
      'from': '2026-10-22T11:00:00Z',
      'to': '2026-10-23T12:00:00Z',
    },
    (r) => r['recentActivity'] = [
      {'title': 'invented'},
    ],
  ]) {
    test('malformed overview is unavailable ${mutate.hashCode}', () {
      final raw = overviewFixture();
      mutate(raw);
      expect(() => AdminOverview.parse(raw), throwsFormatException);
    });
  }
  test(
    'routine INFO event cannot become an alert; review version is checked',
    () {
      expect(
        () => AdminAlert.parse({...alertFixture(), 'severity': 'INFO'}),
        throwsFormatException,
      );
      expect(
        () => AdminAlert.parse(alertFixture(state: 'RESOLVED')),
        throwsFormatException,
      );
      expect(
        AdminAlert.parse(alertFixture(state: 'RESOLVED', revision: 1)).state,
        'RESOLVED',
      );
      expect(
        () => AdminAlertPage.parse({
          'alerts': [alertFixture(), alertFixture()],
          'total': 2,
          'nextCursor': null,
        }),
        throwsFormatException,
      );
    },
  );
  group('Admin resource ownership and acknowledgment', () {
    String? owner;
    late AdminResource<int> resource;
    late Future<Map<String, dynamic>> Function(String) fetch;
    setUp(() {
      owner = 'admin-A|assembly-A';
      fetch = (_) async => {'count': 7};
      resource = AdminResource<int>(
        fetch: (t) => fetch(t),
        parse: (r) => r['count'] as int,
        owner: () => owner,
        credential: () async => 'fixture',
      );
    });
    tearDown(() => resource.dispose());
    test('late read cannot cross a jurisdiction change', () async {
      final pending = Completer<Map<String, dynamic>>();
      fetch = (_) => pending.future;
      final request = resource.load();
      await Future<void>.delayed(Duration.zero);
      owner = 'admin-A|assembly-B';
      pending.complete({'count': 99});
      await request;
      expect(resource.data, isNull);
      await resource.load();
      expect(resource.data, 99);
    });
    test('signout invalidates a late read', () async {
      final pending = Completer<Map<String, dynamic>>();
      fetch = (_) => pending.future;
      final request = resource.load();
      await Future<void>.delayed(Duration.zero);
      resource.clearSession();
      pending.complete({'count': 99});
      await request;
      expect(resource.data, isNull);
    });
    test(
      'uncertain write requires a fresh read and blocks duplicates',
      () async {
        await resource.load();
        final pending = Completer<void>();
        var writes = 0;
        final request = resource.mutate((_, _) {
          writes++;
          return pending.future;
        });
        expect(
          await resource.mutate((_, _) async {
            writes++;
          }),
          isFalse,
        );
        pending.completeError(StateError('connection lost'));
        expect(await request, isFalse);
        expect(resource.uncertain, isTrue);
        expect(
          await resource.mutate((_, _) async {
            writes++;
          }),
          isFalse,
        );
        expect(writes, 1);
        await resource.load();
        expect(resource.uncertain, isFalse);
      },
    );
    test('acknowledged write must be visible in the refreshed state', () async {
      await resource.load();
      expect(
        await resource.mutate((_, _) async {}, verify: (count) => count == 8),
        isFalse,
      );
      expect(resource.uncertain, isTrue);
      fetch = (_) async => {'count': 8};
      await resource.load();
      expect(
        await resource.mutate((_, _) async {}, verify: (count) => count == 8),
        isTrue,
      );
    });
    test(
      'new owner can refresh while old write finishes without navigation success',
      () async {
        await resource.load();
        final pending = Completer<void>();
        final request = resource.mutate((_, _) => pending.future);
        await Future<void>.delayed(Duration.zero);
        owner = 'other-admin';
        fetch = (_) async => {'count': 2};
        await resource.load();
        pending.complete();
        expect(await request, isFalse);
        expect(resource.data, 2);
      },
    );
    test(
      'malformed response removes previous counts rather than inventing zero',
      () async {
        await resource.load();
        fetch = (_) async => {'count': 'bad'};
        await resource.load();
        expect(resource.data, isNull);
        expect(resource.error, isNotNull);
      },
    );
  });
}
