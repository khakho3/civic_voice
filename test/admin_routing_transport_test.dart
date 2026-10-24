import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/services/api_client.dart';

void main() {
  late HttpServer server;
  setUp(() async {
    final old = ApiClient.baseUrl;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
    addTearDown(() async {
      ApiClient.baseUrl = old;
      await server.close(force: true);
    });
  });
  test(
    'routing queue/detail use bounded authenticated encoded requests',
    () async {
      final seen = <Uri>[];
      server.listen((r) async {
        expect(r.method, 'GET');
        expect(r.headers.value('authorization'), 'Bearer fixture');
        seen.add(r.uri);
        r.response.headers.contentType = ContentType.json;
        r.response.write('{}');
        await r.response.close();
      });
      await ApiClient.instance.adminRoutingQueue(
        idToken: 'fixture',
        query: 'Road & CV/42',
        cursor: 'next-cursor',
      );
      await ApiClient.instance.adminRoutingReport(
        'report-one',
        idToken: 'fixture',
      );
      expect(seen.first.path, '/api/admin/report-routing');
      expect(seen.first.queryParameters, {
        'limit': '25',
        'q': 'Road & CV/42',
        'cursor': 'next-cursor',
      });
      expect(seen.last.path, '/api/admin/report-routing/report-one');
    },
  );
  test(
    'routing PATCH sends the exact allowlisted concurrency/reason contract',
    () async {
      const body = {
        'region': 'greaterAccra',
        'assembly': 'Ga Central',
        'reason': 'Confirmed the recorded issue pin.',
        'expectedUpdatedAt': '2026-10-23T10:00:00.000Z',
      };
      server.listen((r) async {
        expect(r.method, 'PATCH');
        expect(r.uri.path, '/api/admin/report-routing/report-one');
        expect(r.headers.value('authorization'), 'Bearer fixture');
        expect(jsonDecode(await utf8.decoder.bind(r).join()), body);
        r.response.headers.contentType = ContentType.json;
        r.response.write('{"auditRecorded":false}');
        await r.response.close();
      });
      expect(
        (await ApiClient.instance.routeAdminReport(
          'report-one',
          idToken: 'fixture',
          body: body,
        ))['auditRecorded'],
        false,
      );
    },
  );
}
