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
  test(
    'Guest registration forwards its token and returns a verified same-UID account',
    () async {
      server.listen((request) async {
        expect(request.uri.path, '/api/auth/citizen-register');
        expect(request.headers.value('authorization'), 'Bearer guest-token');
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'fullName': 'Fixture Citizen',
          'phone': '0200000000',
          'password': 'fixture-password',
          'otp': '1234',
        });
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'user': {
              'id': 'guest-id',
              'publicId': 'CIT-GUEST',
              'firebaseUid': 'guest-owner',
              'role': 'CITIZEN',
              'fullName': 'Fixture Citizen',
              'phone': '+233200000000',
              'isGuest': false,
              'active': true,
              'mustChangePassword': false,
            },
          }),
        );
        await request.response.close();
      });
      final result = await ApiClient.instance.registerCitizen(
        fullName: 'Fixture Citizen',
        phone: '0200000000',
        password: 'fixture-password',
        otp: '1234',
        guestIdToken: 'guest-token',
        expectedUid: 'guest-owner',
      );
      expect(result.firebaseUid, 'guest-owner');
      expect(result.id, 'guest-id');
      expect(result.isGuest, false);
    },
  );
  test(
    'known Guest registration cannot silently fall back to an unauthenticated request',
    () async {
      var calls = 0;
      server.listen((request) async {
        calls++;
        request.response.statusCode = 500;
        await request.response.close();
      });
      await expectLater(
        ApiClient.instance.registerCitizen(
          fullName: 'Fixture Citizen',
          phone: '0200000000',
          password: 'fixture-password',
          otp: '1234',
          expectedUid: 'guest-owner',
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'session required',
            401,
          ),
        ),
      );
      expect(calls, 0);
    },
  );
  test(
    'malformed or foreign registration receipts cannot authorize a handoff',
    () async {
      final valid = <String, dynamic>{
        'id': 'guest-id',
        'publicId': 'CIT-GUEST',
        'firebaseUid': 'guest-owner',
        'role': 'CITIZEN',
        'fullName': 'Fixture Citizen',
        'isGuest': false,
        'active': true,
        'mustChangePassword': false,
      };
      Map<String, dynamic> body = {};
      server.listen((request) async {
        await request.drain<void>();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(body));
        await request.response.close();
      });
      for (final patch in <Map<String, dynamic>>[
        {'id': ''},
        {'publicId': null},
        {'firebaseUid': 'other'},
        {'fullName': 'Other'},
        {'role': 'ADMIN'},
        {'isGuest': true},
        {'active': false},
        {'mustChangePassword': true},
        {'phone': 42},
      ]) {
        body = {
          'user': {...valid, ...patch},
        };
        await expectLater(
          ApiClient.instance.registerCitizen(
            fullName: 'Fixture Citizen',
            phone: '0200000000',
            password: 'fixture-password',
            otp: '1234',
            guestIdToken: 'guest-token',
            expectedUid: 'guest-owner',
          ),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'unverified', 502),
          ),
        );
      }
      body = {'email': 'unused@example.test'};
      await expectLater(
        ApiClient.instance.registerCitizen(
          fullName: 'Fixture Citizen',
          phone: '0200000000',
          password: 'fixture-password',
          otp: '1234',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
