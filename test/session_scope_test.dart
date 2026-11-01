import 'dart:async';

import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/auth_transitions.dart';
import 'package:civic_voice/services/session_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await AppCacheService.instance.activateAccount('fixture-owner');
  });

  test('unchanged SDK and cache namespace retain the opening scope', () {
    final scope = SessionScope.capture();
    expect(scope.isCurrent, isTrue);
    expect(scope.check, returnsNormally);
  });

  test('same-UID cache activation invalidates an open action', () async {
    final scope = SessionScope.capture();
    await AppCacheService.instance.activateAccount('fixture-owner');
    expect(scope.isCurrent, isFalse);
    expect(
      scope.check,
      throwsA(
        isA<ApiException>().having(
          (error) => error.statusCode,
          'expired scope',
          401,
        ),
      ),
    );
  });

  test(
    'logout invalidates a scope before uncancellable work finishes',
    () async {
      final transitions = AuthTransitions();
      final scope = SessionScope.capture(
        auth: AuthSessionFence.capture(
          currentUid: () => 'fixture-owner',
          transitions: transitions,
        ),
      );
      final release = Completer<void>();
      final closing = transitions.close(() => release.future);
      expect(scope.isCurrent, isFalse);
      release.complete();
      await closing;
      expect(scope.isCurrent, isFalse);
    },
  );

  test(
    'a subsequent sign-in for the same UID cannot revive an old action',
    () async {
      final transitions = AuthTransitions();
      final scope = SessionScope.capture(
        auth: AuthSessionFence.capture(
          currentUid: () => 'fixture-owner',
          transitions: transitions,
        ),
      );
      await transitions.run((_) async {});
      expect(scope.isCurrent, isFalse);
      final fresh = SessionScope.capture(
        auth: AuthSessionFence.capture(
          currentUid: () => 'fixture-owner',
          transitions: transitions,
        ),
      );
      expect(fresh.isCurrent, isTrue);
    },
  );
}
