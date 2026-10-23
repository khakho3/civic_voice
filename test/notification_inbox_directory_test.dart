import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/notification_inbox.dart';
import 'package:civic_voice/services/notification_inbox_directory.dart';

Map<String, dynamic> row(String id, {String? destination, bool read = false}) =>
    {
      'id': id,
      'title': 'Report $id',
      'body': 'Your report was reviewed.',
      'destination': destination ?? '/app/reports?report=report-$id',
      'createdAt': '2026-10-23T10:00:00Z',
      'readAt': read ? '2026-10-23T11:00:00Z' : null,
    };
Map<String, dynamic> page({
  List<Map<String, dynamic>>? rows,
  int unread = 4,
  String? next,
}) => {
  'notifications': rows ?? [row('one')],
  'unreadCount': unread,
  'nextCursor': next,
};

void main() {
  test(
    'parses authoritative count and immutable rows, independent of current page',
    () {
      final parsed = InboxPage.parse(
        page(rows: [row('one', read: true)], unread: 30),
        AppRole.citizen,
      );
      expect(parsed.unreadCount, 30);
      expect(parsed.rows.single.read, isTrue);
      expect(parsed.rows.single.reportId, 'report-one');
      expect(() => parsed.rows.clear(), throwsUnsupportedError);
    },
  );
  for (final destination in [
    'https://evil.test/app/reports',
    '//evil.test',
    '/app/admin/activity',
    '/app/reports?report=a&extra=b',
    '/app/reports?report=../x',
    '/app/reports#evil',
  ]) {
    test('rejects forged citizen destination $destination', () {
      expect(
        () => InboxPage.parse(
          page(rows: [row('one', destination: destination)]),
          AppRole.citizen,
        ),
        throwsFormatException,
      );
    });
  }
  for (final mutation in <void Function(Map<String, dynamic>)>[
    (p) => p['unreadCount'] = -1,
    (p) => p['unreadCount'] = '1',
    (p) => p['nextCursor'] = '../bad',
    (p) => p['notifications'] = [row('one'), row('one')],
    (p) => p['notifications'] = [
      {...row('one'), 'readAt': 'not-a-time'},
    ],
    (p) => p['notifications'] = [
      {...row('one'), 'createdAt': null},
    ],
  ]) {
    test('malformed server envelope fails closed ${mutation.hashCode}', () {
      final data = page();
      mutation(data);
      expect(
        () => InboxPage.parse(data, AppRole.citizen),
        throwsFormatException,
      );
    });
  }
  group('session and mutation boundaries', () {
    InboxOwner? identity;
    late NotificationInboxDirectory inbox;
    late Future<Map<String, dynamic>> Function(String, String?) load;
    late Future<Map<String, dynamic>> Function(String, List<String>, String)
    write;
    late Future<String?> Function() token;
    setUp(() {
      identity = const InboxOwner('account-A|scope-A', AppRole.citizen);
      load = (_, _) async => page();
      write = (_, ids, _) async => {'updated': ids.length};
      token = () async => 'fixture-token';
      inbox = NotificationInboxDirectory(
        owner: () => identity,
        token: () => token(),
        list: (t, c) => load(t, c),
        write: (t, ids, a) => write(t, ids, a),
      );
    });
    tearDown(() => inbox.dispose());
    test('late page is discarded after account change', () async {
      final pending = Completer<Map<String, dynamic>>();
      load = (_, _) => pending.future;
      final request = inbox.refresh();
      await Future<void>.delayed(Duration.zero);
      identity = const InboxOwner('account-B', AppRole.citizen);
      pending.complete(page());
      await request;
      expect(inbox.page, isNull);
      expect(inbox.unreadCount, 0);
    });
    test('same account changed scope hides old page immediately', () async {
      await inbox.refresh();
      expect(inbox.unreadCount, 4);
      identity = const InboxOwner('account-A|scope-B', AppRole.citizen);
      expect(inbox.page, isNull);
      expect(inbox.status, InboxStatus.idle);
      expect(await inbox.act(['one'], 'read'), isFalse);
    });
    test('token wait cannot dispatch a request for an old owner', () async {
      final pending = Completer<String?>();
      var requests = 0;
      token = () => pending.future;
      load = (_, _) async {
        requests++;
        return page();
      };
      final request = inbox.refresh();
      identity = null;
      pending.complete('old-token');
      await request;
      expect(requests, 0);
      expect(inbox.page, isNull);
    });
    test(
      'late write does not overwrite new account or block its refresh',
      () async {
        await inbox.refresh();
        final pending = Completer<Map<String, dynamic>>();
        write = (_, _, _) => pending.future;
        final request = inbox.act(['one'], 'read');
        await Future<void>.delayed(Duration.zero);
        identity = const InboxOwner('account-B', AppRole.citizen);
        load = (_, _) async => page(rows: [row('two')], unread: 1);
        await inbox.refresh();
        pending.complete({'updated': 1});
        expect(await request, isFalse);
        expect(inbox.page!.rows.single.id, 'two');
        expect(inbox.writing, isFalse);
      },
    );
    test('double tap sends once and only explicit visible IDs', () async {
      await inbox.refresh();
      final pending = Completer<Map<String, dynamic>>();
      var writes = 0;
      write = (_, ids, action) {
        writes++;
        expect(ids, ['one']);
        expect(action, 'dismiss');
        return pending.future;
      };
      final request = inbox.act(['one'], 'dismiss');
      await Future<void>.delayed(Duration.zero);
      expect(await inbox.act(['one'], 'dismiss'), isFalse);
      pending.complete({'updated': 1});
      expect(await request, isTrue);
      expect(writes, 1);
    });
    test(
      'foreign, duplicate and invalid action IDs never reach transport',
      () async {
        await inbox.refresh();
        var writes = 0;
        write = (_, _, _) async {
          writes++;
          return {'updated': 1};
        };
        for (final ids in [
          <String>[],
          ['foreign'],
          ['one', 'one'],
        ]) {
          expect(await inbox.act(ids, 'read'), isFalse);
        }
        expect(await inbox.act(['one'], 'delete-all'), isFalse);
        expect(writes, 0);
      },
    );
    test('uncertain write locks mutations until successful refresh', () async {
      await inbox.refresh();
      var writes = 0;
      write = (_, _, _) async {
        writes++;
        throw StateError('connection lost');
      };
      expect(await inbox.act(['one'], 'read'), isFalse);
      expect(inbox.uncertain, isTrue);
      expect(await inbox.act(['one'], 'read'), isFalse);
      expect(writes, 1);
      load = (_, _) async => throw StateError('offline');
      await inbox.refresh();
      expect(inbox.uncertain, isTrue);
      expect(inbox.page, isNull);
      load = (_, _) async => page();
      await inbox.refresh();
      expect(inbox.uncertain, isFalse);
    });
    test('zero/invalid acknowledgment never authorizes navigation', () async {
      for (final response in [
        {'updated': 0},
        {'updated': 2},
        {'updated': '1'},
        <String, dynamic>{},
      ]) {
        await inbox.refresh();
        write = (_, _, _) async => response;
        expect(await inbox.act(['one'], 'read'), isFalse);
      }
    });
    test(
      'pagination freezes cursors; read refresh retains current page',
      () async {
        final cursors = <String?>[];
        load = (_, cursor) async {
          cursors.add(cursor);
          return cursor == null
              ? page(next: 'one')
              : page(rows: [row('two')], unread: 7);
        };
        await inbox.refresh();
        await inbox.next();
        expect(inbox.page!.rows.single.id, 'two');
        expect(inbox.unreadCount, 7);
        expect(await inbox.act(['two'], 'read'), isTrue);
        await inbox.previous();
        expect(cursors, [null, 'one', 'one', null]);
      },
    );
    test('cyclic cursor requires refresh instead of endless paging', () async {
      load = (_, _) async => page(next: 'one');
      await inbox.refresh();
      await inbox.next();
      await inbox.next();
      expect(inbox.uncertain, isTrue);
      await inbox.previous();
      expect(inbox.canPrevious, isTrue);
      await inbox.refresh(reset: true);
      expect(inbox.uncertain, isFalse);
      expect(inbox.canPrevious, isFalse);
    });
    test(
      'badge keeps its verified count during same-owner refresh only',
      () async {
        await inbox.refresh();
        final pending = Completer<Map<String, dynamic>>();
        load = (_, _) => pending.future;
        final request = inbox.refresh();
        expect(inbox.status, InboxStatus.loading);
        expect(inbox.unreadCount, 4);
        identity = const InboxOwner('other-account', AppRole.citizen);
        expect(inbox.unreadCount, 0);
        pending.complete(page());
        await request;
      },
    );
    test('session clear invalidates an in-flight response', () async {
      final pending = Completer<Map<String, dynamic>>();
      load = (_, _) => pending.future;
      final request = inbox.refresh();
      await Future<void>.delayed(Duration.zero);
      inbox.clearSession();
      pending.complete(page());
      await request;
      expect(inbox.page, isNull);
      expect(inbox.status, InboxStatus.idle);
    });
  });
}
