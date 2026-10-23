import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/services/api_client.dart';

void main() {
  late HttpServer server;
  setUp(() async {
    final previous = ApiClient.baseUrl;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
    addTearDown(() async {
      ApiClient.baseUrl = previous;
      await server.close(force: true);
    });
  });
  test(
    'overview reads the aggregate endpoint without requesting the user roster',
    () async {
      server.listen((r) async {
        expect(r.method, 'GET');
        expect(r.uri.path, '/api/admin/overview');
        expect(r.headers.value('authorization'), 'Bearer fixture');
        r.response.headers.contentType = ContentType.json;
        r.response.write('{"totalUsers":1234}');
        await r.response.close();
      });
      expect(
        (await ApiClient.instance.adminOverview(
          idToken: 'fixture',
        ))['totalUsers'],
        1234,
      );
    },
  );
  test(
    'alerts page sends explicit scoped state, bounded limit and encoded search/cursor',
    () async {
      server.listen((r) async {
        expect(r.uri.path, '/api/admin/alerts');
        expect(r.uri.queryParameters, {
          'limit': '25',
          'state': 'RESOLVED',
          'q': 'system settings',
          'cursor': 'cursor-one',
        });
        r.response.headers.contentType = ContentType.json;
        r.response.write('{"alerts":[],"total":0,"nextCursor":null}');
        await r.response.close();
      });
      expect(
        (await ApiClient.instance.adminAlerts(
          idToken: 'fixture',
          state: 'RESOLVED',
          query: 'system settings',
          cursor: 'cursor-one',
        ))['total'],
        0,
      );
    },
  );
  test(
    'review sends only explicit action, expected revision and reason',
    () async {
      server.listen((r) async {
        expect(r.method, 'PATCH');
        expect(r.uri.path, '/api/admin/alerts/event-one');
        expect(r.headers.value('authorization'), 'Bearer fixture');
        expect(jsonDecode(await utf8.decoder.bind(r).join()), {
          'action': 'RESOLVE',
          'expectedRevision': 2,
          'note': 'Investigated and corrected.',
        });
        r.response.headers.contentType = ContentType.json;
        r.response.write('{"review":{"state":"RESOLVED","revision":3}}');
        await r.response.close();
      });
      expect(
        (await ApiClient.instance.reviewAdminAlert(
          'event-one',
          idToken: 'fixture',
          action: 'RESOLVE',
          revision: 2,
          note: 'Investigated and corrected.',
        ))['review']['revision'],
        3,
      );
    },
  );
}
