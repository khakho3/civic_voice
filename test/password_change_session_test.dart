import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/auth_transitions.dart';
import 'package:civic_voice/services/password_change_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late AuthTransitions transitions;
  late PasswordChangeSession session;
  late String uid;
  late int credentialCalls;
  late int requests;
  Future<String?> Function()? credential;
  Future<void> Function(HttpRequest)? respond;

  setUp(() async {
    final previous = ApiClient.baseUrl;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    ApiClient.baseUrl = 'http://127.0.0.1:${server.port}';
    addTearDown(() async {
      ApiClient.baseUrl = previous;
      await server.close(force: true);
    });
    transitions = AuthTransitions();
    uid = 'fixture-owner';
    credentialCalls = requests = 0;
    credential = null;
    respond = null;
    session = PasswordChangeSession(
      owner: AuthSessionFence.capture(
        currentUid: () => uid,
        transitions: transitions,
      ),
      credential: () async {
        credentialCalls++;
        return credential == null ? 'synthetic-id-token' : credential!();
      },
    );
    server.listen((request) async {
      requests++;
      if (respond != null) {
        await respond!(request);
      } else {
        await request.drain<void>();
        request.response.statusCode = 500;
        await request.response.close();
      }
    });
  });

  final changed = throwsA(
    isA<ApiException>().having(
      (error) => error.statusCode,
      'session changed',
      401,
    ),
  );

  Future<void> reply(HttpRequest request, Map<String, Object?> body) async {
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  test(
    'current owner sends OTP, verifies grant and saves with existing transport',
    () async {
      final expiry = DateTime.utc(2030, 1, 1);
      respond = (request) async {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(request.method, 'POST');
        switch (request.uri.path) {
          case '/api/auth/change-password-otp':
            expect(
              request.headers.value('authorization'),
              'Bearer synthetic-id-token',
            );
            expect(body, {'phone': '0200000000'});
            await reply(request, {'expiresAt': expiry.toIso8601String()});
          case '/api/auth/verify-change-password-otp':
            expect(
              request.headers.value('authorization'),
              'Bearer synthetic-id-token',
            );
            expect(body, {'otp': '1234'});
            await reply(request, {'resetToken': 'synthetic-grant'});
          case '/api/auth/reset-password':
            expect(request.headers.value('authorization'), isNull);
            expect(body, {
              'phone': '0200000000',
              'resetToken': 'synthetic-grant',
              'newPassword': 'fixture-new-password',
            });
            await reply(request, {});
          default:
            fail('unexpected fixture path: ${request.uri.path}');
        }
      };
      expect(await session.sendCode('0200000000'), expiry);
      expect(await session.verifyCode('1234'), 'synthetic-grant');
      expect(
        await session.savePassword(
          phone: '0200000000',
          resetToken: 'synthetic-grant',
          newPassword: 'fixture-new-password',
        ),
        isTrue,
      );
      expect(credentialCalls, 2);
      expect(requests, 3);
    },
  );

  test('a changed owner cannot fetch credentials or send an OTP', () async {
    uid = 'new-owner';
    await expectLater(session.sendCode('0200000000'), changed);
    expect(credentialCalls, 0);
    expect(requests, 0);
  });

  test(
    'same-UID sign-in while credentials are pending cannot send a stale OTP',
    () async {
      final token = Completer<String?>();
      credential = () => token.future;
      final sending = session.sendCode('0200000000');
      final assertion = expectLater(sending, changed);
      await transitions.run((_) async {});
      token.complete('synthetic-old-token');
      await assertion;
      expect(credentialCalls, 1);
      expect(requests, 0);
    },
  );

  test('late OTP delivery cannot advance a different session', () async {
    final arrived = Completer<void>();
    final release = Completer<void>();
    respond = (request) async {
      await request.drain<void>();
      arrived.complete();
      await release.future;
      await reply(request, {'expiresAt': DateTime.utc(2030).toIso8601String()});
    };
    final assertion = expectLater(session.sendCode('0200000000'), changed);
    await arrived.future;
    uid = 'new-owner';
    release.complete();
    await assertion;
    expect(requests, 1);
  });

  test(
    'late verified grant cannot advance a new sign-in to the same UID',
    () async {
      final arrived = Completer<void>();
      final release = Completer<void>();
      respond = (request) async {
        await request.drain<void>();
        arrived.complete();
        await release.future;
        await reply(request, {'resetToken': 'synthetic-old-grant'});
      };
      final assertion = expectLater(session.verifyCode('1234'), changed);
      await arrived.future;
      await transitions.run((_) async {});
      release.complete();
      await assertion;
      expect(requests, 1);
    },
  );

  test(
    'acknowledged save reports lost completion ownership without false failure',
    () async {
      final arrived = Completer<void>();
      final release = Completer<void>();
      respond = (request) async {
        await request.drain<void>();
        arrived.complete();
        await release.future;
        await reply(request, {});
      };
      final saving = session.savePassword(
        phone: '0200000000',
        resetToken: 'synthetic-grant',
        newPassword: 'fixture-new-password',
      );
      await arrived.future;
      await transitions.close(() async {});
      release.complete();
      expect(await saving, isFalse);
      expect(requests, 1);
    },
  );

  test('a stale form cannot use an old grant to submit a password', () async {
    await transitions.run((_) async {});
    await expectLater(
      session.savePassword(
        phone: '0200000000',
        resetToken: 'synthetic-grant',
        newPassword: 'fixture-new-password',
      ),
      changed,
    );
    expect(credentialCalls, 0);
    expect(requests, 0);
  });

  test('provider failure remains distinct from ownership loss', () async {
    respond = (request) async {
      await request.drain<void>();
      request.response.statusCode = 503;
      await reply(request, {'message': 'fixture unavailable'});
    };
    await expectLater(
      session.verifyCode('1234'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'provider unavailable',
          503,
        ),
      ),
    );
    expect(session.isCurrent, isTrue);
  });
}
