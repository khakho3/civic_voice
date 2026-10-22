import 'dart:convert';
import 'dart:io';

import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/features/citizen/services/report_crud_service.dart';
import 'package:civic_voice/features/citizen/services/report_submission_store.dart';
import 'package:civic_voice/models/region.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final testHttpOverride = HttpOverrides.current;
  late HttpServer server;
  late Directory root;
  late String original;
  setUp(() async {
    // These are real loopback transport tests, not widget-network stubs.
    HttpOverrides.global = null;
    original = ApiClient.baseUrl;
    root = await Directory.systemTemp.createTemp('cv-submit-transport-');
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
  });
  tearDown(() async {
    ApiClient.baseUrl = original;
    await server.close(force: true);
    await root.delete(recursive: true);
    HttpOverrides.global = testHttpOverride;
  });
  const key = 'frozen_submission_12345';
  test('native submission routes by the issue pin and omits stale geocoder locality', () async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize(accountId: 'alice');
    final photos = <String>[];
    for (var index = 0; index < 2; index++) {
      photos.add(
        (await File('${root.path}/$index.jpg').writeAsString('photo-$index'))
            .path,
      );
    }
    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      expect(body, isNot(contains('name="region"')));
      expect(body, isNot(contains('name="assembly"')));
      expect(body, contains('name="latitude"\r\n\r\n5.6'));
      expect(body, contains('name="longitude"\r\n\r\n-0.2'));
      expect(body, contains('name="submissionLatitude"\r\n\r\n7.0'));
      final saved = await ReportSubmissionStore(directory: () async => root)
          .pending('alice');
      request.response.statusCode = 201;
      request.response.write(
        jsonEncode({
          'submission': {'key': saved!.submissionKey, 'replayed': false},
          'report': {
            'id': 'r',
            'publicReference': 'CV-1',
            'status': 'SUBMITTED',
            'region': 'greaterAccra',
            'assembly': 'Ga Central',
          },
        }),
      );
      await request.response.close();
    });
    final subject = ReportCrudService.forTesting(
      account: () => 'alice',
      token: () async => 'token',
      store: ReportSubmissionStore(directory: () async => root),
    );
    final report = await subject.createReport(
      ReportDraft(
        title: 'Drain',
        description: 'Blocked',
        category: 'Sanitation',
        location: 'Issue pin',
        community: 'Test',
        latitude: 5.6,
        longitude: -0.2,
        region: Region.ashanti,
        assembly: 'Kumasi',
        photoPaths: photos,
      ),
      submissionLatitude: 7,
      submissionLongitude: -3,
    );
    expect(report.region, Region.greaterAccra);
    expect(report.assembly, 'Ga Central');
  });
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
