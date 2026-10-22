import 'dart:convert';
import 'dart:io';

import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Directory root;
  late String original;
  setUp(() async {
    original = ApiClient.baseUrl;
    root = await Directory.systemTemp.createTemp('cv-submit-transport-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
  });
  tearDown(() async {
    ApiClient.baseUrl = original;
    await server.close(force: true);
    await root.delete(recursive: true);
  });
  const key = 'frozen_submission_12345';
  for (final replayed in [false, true]) {
    test(
      'multipart sends frozen key and evidence; replay=$replayed is acknowledged',
      () async {
        final photo = await File(
          '${root.path}/a.jpg',
        ).writeAsString('exact-photo-bytes');
        server.listen((request) async {
          expect(request.uri.path, '/api/reports');
          expect(request.headers.value('authorization'), 'Bearer token');
          final body = await utf8.decoder.bind(request).join();
          expect(body, contains('name="submissionKey"\r\n\r\n$key'));
          expect(body, contains('name="photos"; filename="a.jpg"'));
          expect(body, contains('exact-photo-bytes'));
          request.response.headers.contentType = ContentType.json;
          request.response.statusCode = replayed ? 200 : 201;
          request.response.write(
            jsonEncode({
              'submission': {'key': key, 'replayed': replayed},
              'report': {
                'id': 'r',
                'publicReference': 'CV-1',
                'status': replayed ? 'UNDER_REVIEW' : 'SUBMITTED',
              },
            }),
          );
          await request.response.close();
        });
        final report = await ApiClient.instance.createReport(
          idToken: 'token',
          fields: {'submissionKey': key},
          photoPaths: [photo.path],
        );
        expect(report['id'], 'r');
      },
    );
  }
  test('HTTP success with no matching receipt stays uncertain', () async {
    server.listen((request) async {
      await request.drain<void>();
      request.response.write('{"report":{"id":"r","publicReference":"CV-1"}}');
      await request.response.close();
    });
    await expectLater(
      ApiClient.instance.createReport(
        idToken: 'token',
        fields: {'submissionKey': key},
      ),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 502)),
    );
  });
  test(
    'duplicate discovery wire contains issue pin only and parses reports envelope',
    () async {
      final issue = {
        'title': 'Drain',
        'description': 'Blocked',
        'category': 'Sanitation',
        'latitude': 5.8,
        'longitude': -0.1,
      };
      server.listen((request) async {
        expect(request.uri.path, '/api/reports/duplicate-candidates');
        expect(jsonDecode(await utf8.decoder.bind(request).join()), issue);
        request.response.write('{"reports":[]}');
        await request.response.close();
      });
      expect(
        await ApiClient.instance.reportDuplicateCandidates(
          idToken: 'token',
          issue: issue,
        ),
        isEmpty,
      );
    },
  );
}
