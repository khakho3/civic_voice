import 'dart:async';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/main.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/set_new_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/idle_session_timer.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:civic_voice/services/notification_directory.dart';
import 'package:civic_voice/services/password_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'password_session_test.dart' show account;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await NotificationDirectory.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().clearUser();
    final previous = ApiClient.baseUrl;
    ApiClient.baseUrl = 'http://127.0.0.1:1';
    addTearDown(() {
      ApiClient.baseUrl = previous;
      IdleSessionTimer.instance.cancel();
    });
  });
  for (final role in {
    'CITIZEN': AppRole.citizen,
    'MUNICIPAL': AppRole.municipalOfficer,
    'MAINTENANCE': AppRole.maintenanceTeam,
    'MINISTRY': AppRole.ministrySupervisor,
    'ADMIN': AppRole.systemAdministrator,
  }.entries) {
    testWidgets(
      'real login route publishes verified ${role.key} and chosen persistence',
      (tester) async {
        final service = PasswordSessionService(
          passwordLogin: (_, _) async => 'handoff',
          exchange: (_) async =>
              const PasswordIdentity(uid: 'verified-uid', idToken: 'id-token'),
          sync: (_) async => account(role: role.key),
        );
        await tester.pumpWidget(
          CivicVoiceApp(
            initialRoute: AppRoutes.login,
            passwordSessions: service,
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<LoginScreen>(find.byType(LoginScreen)).onSignIn!(
          '0200000000',
          'test-password',
          true,
        );
        // Destination dashboards may legitimately keep a loading orb animating
        // while no live directory is injected; settle the route, not that orb.
        for (
          var frame = 0;
          frame < 12 && find.byType(LoginScreen).evaluate().isNotEmpty;
          frame++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        await tester.pump(const Duration(milliseconds: 400));
        expect(MockAuthService().getCurrentRole(), role.value);
        expect(AppCacheService.instance.keepSignedIn, true);
        expect(find.byType(LoginScreen), findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final entry in {
    401: LoginViewState.invalidCredentials,
    403: LoginViewState.accountUnavailable,
    429: LoginViewState.rateLimited,
    503: LoginViewState.serviceUnavailable,
    404: LoginViewState.serviceUnavailable,
    0: LoginViewState.offline,
  }.entries) {
    testWidgets(
      'login route maps HTTP ${entry.key} clearly and clears partial sessions',
      (tester) async {
        final service = PasswordSessionService(
          passwordLogin: (_, _) async =>
              throw ApiException(statusCode: entry.key, message: 'safe'),
        );
        await tester.pumpWidget(
          CivicVoiceApp(
            initialRoute: AppRoutes.login,
            passwordSessions: service,
          ),
        );
        await tester.pumpAndSettle();
        tester.widget<LoginScreen>(find.byType(LoginScreen)).onSignIn!(
          '0200000000',
          'test-password',
          false,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<LoginScreen>(find.byType(LoginScreen)).state,
          entry.value,
        );
        expect(MockAuthService().getCurrentRole(), isNull);
        expect(AppCacheService.instance.keepSignedIn, false);
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Sign In'),
        );
        expect(button.onPressed, isNotNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('rapid repeated submits create only one password request', (
    tester,
  ) async {
    final request = Completer<String>();
    var calls = 0;
    final service = PasswordSessionService(
      passwordLogin: (_, _) {
        calls++;
        return request.future;
      },
    );
    await tester.pumpWidget(
      CivicVoiceApp(initialRoute: AppRoutes.login, passwordSessions: service),
    );
    await tester.pumpAndSettle();
    final submit = tester
        .widget<LoginScreen>(find.byType(LoginScreen))
        .onSignIn!;
    submit('0200000000', 'test-password', false);
    submit('0200000000', 'test-password', false);
    expect(calls, 1);
    request.completeError(
      const ApiException(statusCode: 401, message: 'rejected'),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<LoginScreen>(find.byType(LoginScreen)).state,
      LoginViewState.invalidCredentials,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'verified first-login users remain gated by the password screen',
    (tester) async {
      final service = PasswordSessionService(
        passwordLogin: (_, _) async => 'handoff',
        exchange: (_) async =>
            const PasswordIdentity(uid: 'verified-uid', idToken: 'id'),
        sync: (_) async => account(role: 'ADMIN', mustChange: true),
      );
      await tester.pumpWidget(
        CivicVoiceApp(initialRoute: AppRoutes.login, passwordSessions: service),
      );
      await tester.pumpAndSettle();
      tester.widget<LoginScreen>(find.byType(LoginScreen)).onSignIn!(
        '0200000000',
        'test-password',
        false,
      );
      await tester.pumpAndSettle();
      expect(find.byType(SetNewPasswordScreen), findsOneWidget);
      expect(MockAuthService().mustChangePasswordOnFirstLogin(), true);
      expect(AppCacheService.instance.keepSignedIn, false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'leaving login during a handoff cannot publish the late session',
    (tester) async {
      final pending = Completer<String>();
      final service = PasswordSessionService(
        passwordLogin: (_, _) => pending.future,
        exchange: (_) async =>
            const PasswordIdentity(uid: 'verified-uid', idToken: 'id'),
        sync: (_) async => account(),
      );
      await tester.pumpWidget(
        CivicVoiceApp(initialRoute: AppRoutes.login, passwordSessions: service),
      );
      await tester.pumpAndSettle();
      tester.widget<LoginScreen>(find.byType(LoginScreen)).onSignIn!(
        '0200000000',
        'test-password',
        true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete('handoff');
      await tester.pumpAndSettle();
      expect(MockAuthService().getCurrentRole(), isNull);
      expect(AppCacheService.instance.keepSignedIn, false);
    },
  );

  testWidgets(
    'verification outages release busy state without blaming the OTP',
    (tester) async {
      tester.view.physicalSize = const Size(428, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light,
          home: OtpVerificationScreen(
            phoneNumber: '0200000000',
            purpose: OtpPurpose.registration,
            expiresAt: null,
            onVerify: (_) async => throw const ApiException(
              statusCode: 503,
              message: 'Unavailable',
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '1234');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Unable to Verify'), findsOneWidget);
      expect(find.text('Incorrect Code'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
