import 'dart:async';

import 'package:civic_voice/features/authentication/screens/bio_lock_screen.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/biometric_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'biometric_lock_enabled_v1': true,
    });
    await AppCacheService.instance.initialize();
  });

  testWidgets('unavailable biometrics can self-heal and continue', (
    tester,
  ) async {
    var authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: BioLockScreen(
          onAuthenticated: () => authenticated = true,
          onLogOut: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(
      find.text(
        'Biometric authentication is no longer available on this device.',
      ),
      findsOneWidget,
    );
    expect(find.text('Log Out'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(authenticated, isTrue);
    expect(AppCacheService.instance.biometricLockEnabled, isFalse);
  });

  testWidgets('Log Out is available when biometrics are unavailable', (
    tester,
  ) async {
    var loggedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: BioLockScreen(
          onAuthenticated: () {},
          onLogOut: () => loggedOut = true,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    await tester.tap(find.text('Log Out'));
    await tester.pump();

    expect(loggedOut, isTrue);
  });

  testWidgets(
    'an old app lock cannot disable the lock or unlock a new session',
    (tester) async {
      var unlocks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BioLockScreen(
            onAuthenticated: () => unlocks++,
            onLogOut: () {},
            checkAvailability: () async => BiometricAvailability.noHardware,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Continue'), findsOneWidget);
      await AppCacheService.instance.activateAccount('new-owner');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(unlocks, 0);
      expect(AppCacheService.instance.biometricLockEnabled, isTrue);
    },
  );

  testWidgets('an old app lock cannot log out a new session', (tester) async {
    var logouts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BioLockScreen(
          onAuthenticated: () {},
          onLogOut: () => logouts++,
          checkAvailability: () async => BiometricAvailability.noHardware,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await AppCacheService.instance.activateAccount('new-owner');
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    expect(logouts, 0);
  });

  testWidgets('late biometric success cannot unlock a reactivated session', (
    tester,
  ) async {
    final verification = Completer<BiometricAuthResult>();
    var prompts = 0, unlocks = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BioLockScreen(
          onAuthenticated: () => unlocks++,
          onLogOut: () {},
          checkAvailability: () async => BiometricAvailability.available,
          authenticate: () {
            prompts++;
            return verification.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(prompts, 1);
    await AppCacheService.instance.activateAccount(
      AppCacheService.instance.activeAccountId,
    );
    verification.complete(const BiometricAuthResult.success());
    await tester.pumpAndSettle();
    expect(unlocks, 0);
  });
}
