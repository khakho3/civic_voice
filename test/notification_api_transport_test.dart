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
  test('list uses current bearer and bounded cursor page', () async {
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/notifications');
      expect(request.uri.queryParameters, {
        'limit': '25',
        'cursor': 'cursor-one',
      });
      expect(request.headers.value('authorization'), 'Bearer fixture-token');
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({'notifications': [], 'unreadCount': 0, 'nextCursor': null}),
      );
      await request.response.close();
    });
    expect(
      (await ApiClient.instance.notificationInbox(
        idToken: 'fixture-token',
        cursor: 'cursor-one',
      ))['unreadCount'],
      0,
    );
  });
  test('write sends only explicit IDs/action and current bearer', () async {
    server.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/notifications/actions');
      expect(request.headers.value('authorization'), 'Bearer fixture-token');
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'ids': ['one', 'two'],
        'action': 'read',
      });
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"updated":2}');
      await request.response.close();
    });
    expect(
      (await ApiClient.instance.notificationAction(
        idToken: 'fixture-token',
        ids: ['one', 'two'],
        action: 'read',
      ))['updated'],
      2,
    );
  });
  for (final status in [401, 403, 503]) {
    test(
      'HTTP $status is preserved, never treated as acknowledgment',
      () async {
        server.listen((request) async {
          request.response.statusCode = status;
          request.response.write('{"error":"Unavailable"}');
          await request.response.close();
        });
        await expectLater(
          ApiClient.instance.notificationAction(
            idToken: 'fixture-token',
            ids: ['one'],
            action: 'dismiss',
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'status', status),
          ),
        );
      },
    );
  }
}
