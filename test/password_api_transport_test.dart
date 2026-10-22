import 'dart:convert';
import 'dart:io';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'password request sends only phone/password and consumes only customToken',
    () async {
      server.listen((request) async {
        expect(request.method, 'POST');
        expect(request.uri.path, '/api/auth/password-login');
        expect(request.headers.value('authorization'), isNull);
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'phone': '0200000000',
          'password': 'transport-password',
        });
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'customToken': 'handoff', 'ignored': 'value'}),
        );
        await request.response.close();
      });
      expect(
        await ApiClient.instance.passwordLogin(
          phone: '0200000000',
          password: 'transport-password',
        ),
        'handoff',
      );
    },
  );
  for (final status in [401, 429, 503]) {
    test(
      'HTTP $status survives a proxy HTML error without leaking its body',
      () async {
        server.listen((request) async {
          request.response.statusCode = status;
          request.response.write('<html>upstream private diagnostic</html>');
          await request.response.close();
        });
        await expectLater(
          ApiClient.instance.passwordLogin(
            phone: '0200000000',
            password: 'transport-password',
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', status)
                .having(
                  (e) => e.message.contains('private diagnostic'),
                  'private body',
                  false,
                ),
          ),
        );
      },
    );
  }
  for (final body in [
    '[]',
    'null',
    '{"customToken":42}',
    '{"customToken":""}',
    'not json',
  ]) {
    test('malformed successful handoff is rejected: $body', () async {
      server.listen((request) async {
        request.response.write(body);
        await request.response.close();
      });
      await expectLater(
        ApiClient.instance.passwordLogin(
          phone: '0200000000',
          password: 'transport-password',
        ),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 502)),
      );
    });
  }
  test(
    'logout requests use the signed token and exact server event contract',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/api/auth/session-events');
        expect(
          request.headers.value('authorization'),
          'Bearer fixture-id-token',
        );
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'type': 'SIGN_OUT',
        });
        request.response.statusCode = 204;
        await request.response.close();
      });
      await ApiClient.instance.reportSignOut(idToken: 'fixture-id-token');
    },
  );
}
