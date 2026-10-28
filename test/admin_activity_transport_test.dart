import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/services/api_client.dart';

void main() {
  test(
    'audit list/detail send authenticated encoded filters and bounded page size',
    () async {
      final old = ApiClient.baseUrl;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
      addTearDown(() async {
        ApiClient.baseUrl = old;
        await server.close(force: true);
      });
      final seen = <Uri>[];
      server.listen((request) async {
        expect(request.method, 'GET');
        expect(request.headers.value('authorization'), 'Bearer fixture-token');
        seen.add(request.uri);
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
      final query = {
        'q': 'Name & CV/42',
        'action': 'USER_UPDATED',
        'category': 'SECURITY',
        'outcome': 'UNKNOWN',
        'severity': 'ALERT',
        'actorId': 'actor-1',
        'subjectType': 'USER',
        'subjectId': 'target-1',
        'from': '2026-10-27T00:00:00.000Z',
        'to': '2026-10-28T00:00:00.000Z',
        'cursor': 'opaque-cursor',
        'limit': '9999',
      };
      await ApiClient.instance.adminActivityPage(
        idToken: 'fixture-token',
        query: query,
      );
      await ApiClient.instance.adminActivityDetail(
        'event-one',
        idToken: 'fixture-token',
      );
      expect(seen.first.path, '/api/admin/activity');
      expect(seen.first.queryParameters, {...query, 'limit': '50'});
      expect(seen.last.path, '/api/admin/activity/event-one');
    },
  );
}
