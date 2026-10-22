import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/password_session_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

SyncedUser account({
  String role = 'CITIZEN',
  String uid = 'verified-uid',
  bool active = true,
  bool guest = false,
  bool mustChange = false,
}) => SyncedUser.fromJson({
  'id': 'account-id',
  'publicId': 'PUBLIC-1',
  'role': role,
  'fullName': 'Test Account',
  'phone': '+233200000000',
  'firebaseUid': uid,
  'active': active,
  'isGuest': guest,
  'mustChangePassword': mustChange,
});

void main() {
  for (final role in [
    'CITIZEN',
    'MUNICIPAL',
    'MAINTENANCE',
    'MINISTRY',
    'ADMIN',
  ]) {
    test('$role signs in through verified handoff and sync in order', () async {
      final calls = <String>[];
      final service = PasswordSessionService(
        passwordLogin: (phone, password) async {
          calls.add('password');
          expect(phone, '0200000000');
          expect(password, 'test-password');
          return 'handoff';
        },
        exchange: (token) async {
          calls.add('exchange');
          expect(token, 'handoff');
          return const PasswordIdentity(
            uid: 'verified-uid',
            idToken: 'id-token',
          );
        },
        sync: (token) async {
          calls.add('sync');
          expect(token, 'id-token');
          return account(role: role);
        },
      );
      final session = await service.signIn(
        phone: '0200000000',
        password: 'test-password',
      );
      expect(session.user.role, role);
      expect(session.uid, 'verified-uid');
      expect(calls, ['password', 'exchange', 'sync']);
    });
  }
  for (final status in [401, 403, 404, 429, 503, 0]) {
    test('HTTP $status never falls back to a direct password login', () async {
      var exchanges = 0;
      final service = PasswordSessionService(
        passwordLogin: (_, _) async =>
            throw ApiException(statusCode: status, message: 'Safe failure'),
        exchange: (_) async {
          exchanges++;
          return const PasswordIdentity(uid: 'x', idToken: 'x');
        },
      );
      await expectLater(
        service.signIn(phone: '0200000000', password: 'test-password'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'status', status),
        ),
      );
      expect(exchanges, 0);
    });
  }
  for (final user in [
    account(uid: 'wrong-uid'),
    account(active: false),
    account(guest: true),
    account(role: 'UNKNOWN'),
  ]) {
    test(
      'unverified, inactive, guest or unsupported accounts cannot publish a session: ${user.role}/${user.active}/${user.isGuest}/${user.firebaseUid}',
      () async {
        final service = PasswordSessionService(
          passwordLogin: (_, _) async => 'handoff',
          exchange: (_) async =>
              const PasswordIdentity(uid: 'verified-uid', idToken: 'id'),
          sync: (_) async => user,
        );
        await expectLater(
          service.signIn(phone: '0200000000', password: 'test-password'),
          throwsA(isA<ApiException>()),
        );
      },
    );
  }
  test('empty handoff cannot be exchanged', () async {
    final service = PasswordSessionService(passwordLogin: (_, _) async => '');
    await expectLater(
      service.signIn(phone: '0200000000', password: 'test-password'),
      throwsA(isA<ApiException>()),
    );
  });
  test('custom-token configuration errors are not invalid-password errors', () {
    expect(
      passwordLoginFailure(FirebaseAuthException(code: 'invalid-custom-token')),
      PasswordLoginFailure.unavailable,
    );
    expect(
      passwordLoginFailure(
        FirebaseAuthException(code: 'custom-token-mismatch'),
      ),
      PasswordLoginFailure.unavailable,
    );
    expect(
      passwordLoginFailure(
        const ApiException(statusCode: 404, message: 'missing route'),
      ),
      PasswordLoginFailure.unavailable,
    );
    expect(
      passwordLoginFailure(
        const ApiException(statusCode: 401, message: 'rejected'),
      ),
      PasswordLoginFailure.credentials,
    );
    expect(
      passwordLoginFailure(
        const ApiException(statusCode: 429, message: 'limited'),
      ),
      PasswordLoginFailure.throttled,
    );
    expect(
      passwordLoginFailure(
        const ApiException(statusCode: 503, message: 'down'),
      ),
      PasswordLoginFailure.unavailable,
    );
  });
  test(
    'first-login change obtains a fresh verified session for the same UID',
    () async {
      final calls = <String>[];
      final service = PasswordSessionService(
        changePassword: (token, password) async {
          expect(token, 'old-id');
          expect(password, 'new-password');
          calls.add('change');
        },
        passwordLogin: (phone, password) async {
          expect(password, 'new-password');
          calls.add('password');
          return 'new-handoff';
        },
        exchange: (_) async {
          calls.add('exchange');
          return const PasswordIdentity(uid: 'verified-uid', idToken: 'new-id');
        },
        sync: (_) async {
          calls.add('sync');
          return account();
        },
      );
      final result = await service.completeFirstLogin(
        uid: 'verified-uid',
        phone: '0200000000',
        idToken: 'old-id',
        newPassword: 'new-password',
      );
      expect(result.user.mustChangePassword, false);
      expect(calls, ['change', 'password', 'exchange', 'sync']);
    },
  );
  for (final wrongUid in [false, true]) {
    test(
      'a saved password with failed renewal requires sign-in, not another save: $wrongUid',
      () async {
        final service = PasswordSessionService(
          changePassword: (_, _) async {},
          passwordLogin: (_, _) async {
            if (!wrongUid) {
              throw const ApiException(statusCode: 503, message: 'Unavailable');
            }
            return 'handoff';
          },
          exchange: (_) async =>
              const PasswordIdentity(uid: 'wrong-uid', idToken: 'new-id'),
        );
        await expectLater(
          service.completeFirstLogin(
            uid: 'verified-uid',
            phone: '0200000000',
            idToken: 'old-id',
            newPassword: 'new-password',
          ),
          throwsA(isA<PasswordChangedSignInRequired>()),
        );
      },
    );
  }
  test('failed password save never attempts renewal', () async {
    var renewed = false;
    final service = PasswordSessionService(
      changePassword: (_, _) async =>
          throw const ApiException(statusCode: 503, message: 'Unavailable'),
      passwordLogin: (_, _) async {
        renewed = true;
        return 'handoff';
      },
    );
    await expectLater(
      service.completeFirstLogin(
        uid: 'verified-uid',
        phone: '0200000000',
        idToken: 'old-id',
        newPassword: 'new-password',
      ),
      throwsA(isA<ApiException>()),
    );
    expect(renewed, false);
  });
}
