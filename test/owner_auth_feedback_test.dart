import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/auth_failure_message.dart';
import 'package:civic_voice/services/password_session_service.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';

void main() {
  test('auth service failures do not assert that the device is offline', () {
    for (final code in [0, 408, 500, 502, 503]) {
      final error = ApiException(
        statusCode: code,
        message: 'private upstream body',
      );
      expect(passwordLoginFailure(error), PasswordLoginFailure.unavailable);
      expect(authFailureMessage(error), isNot(contains('offline')));
      expect(authFailureMessage(error), isNot(contains('private')));
    }
    expect(
      passwordLoginFailure(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
      PasswordLoginFailure.unavailable,
    );
    expect(
      authFailureMessage(
        const ApiException(statusCode: 429, message: 'private'),
      ),
      contains('Too many attempts'),
    );
  });
  test(
    'a rejected account sync after password verification is not bad credentials',
    () async {
      final service = PasswordSessionService(
        passwordLogin: (_, _) async => 'handoff',
        exchange: (_) async =>
            const PasswordIdentity(uid: 'uid', idToken: 'id'),
        sync: (_) async => throw const ApiException(
          statusCode: 401,
          message: 'expired session',
        ),
      );
      try {
        await service.signIn(phone: '0200000000', password: 'fixture');
        fail('must reject');
      } catch (error) {
        expect(passwordLoginFailure(error), PasswordLoginFailure.unavailable);
      }
    },
  );
  testWidgets('OTP service outage stays distinct from an incorrect code', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpVerificationScreen(
          phoneNumber: '0200000000',
          purpose: OtpPurpose.forgotPassword,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          onVerify: (_) async =>
              throw const ApiException(statusCode: 503, message: 'private'),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Verify Code'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect Code'), findsNothing);
    expect(
      find.text('The service is unavailable. Please try again shortly.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'password save transport exception releases busy state and retains input',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SetNewPasswordForm(
                submitLabel: 'Save Password',
                onSaved: (_) async =>
                    throw const ApiException(statusCode: 0, message: 'private'),
              ),
            ),
          ),
        ),
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'fixture-password');
      await tester.enterText(fields.at(1), 'fixture-password');
      await tester.tap(find.widgetWithText(FilledButton, 'Save Password'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Could not reach CivicVoice. Check your connection or try again shortly.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<TextFormField>(fields.first).controller!.text,
        'fixture-password',
      );
    },
  );
}
