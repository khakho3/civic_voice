import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/biometric_auth_service.dart';
import 'package:civic_voice/widgets/biometric_lock_preference_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await AppCacheService.instance.initialize();
  });

  testWidgets('shows an inert explanation when biometrics are unsupported', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: const Scaffold(body: BiometricLockPreferenceRow()),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.text('App Lock'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsNothing);
  });

  testWidgets('verifies biometrics before enabling App Lock', (tester) async {
    var authenticationCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: Scaffold(
          body: BiometricLockPreferenceRow(
            checkAvailability: () async => BiometricAvailability.available,
            authenticate: () async {
              authenticationCalls++;
              return const BiometricAuthResult.success();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Require fingerprint or face verification when you open or return to CivicVoice',
      ),
      findsNothing,
    );
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(authenticationCalls, 1);
    expect(AppCacheService.instance.biometricLockEnabled, isTrue);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
  });

  testWidgets('leaves App Lock off when biometric verification fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(),
        home: BiometricLockPreferenceRow(
          checkAvailability: () async => BiometricAvailability.available,
          authenticate: () async => const BiometricAuthResult.failure(
            BiometricAuthFailureReason.canceled,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump();

    expect(AppCacheService.instance.biometricLockEnabled, isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });
}
