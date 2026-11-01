import 'dart:async';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/auth_transitions.dart';
import 'package:civic_voice/services/password_change_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Session extends PasswordChangeSession {
  _Session()
    : super(owner: AuthSessionFence.capture(currentUid: () => 'fixture'));
  final saved = Completer<bool>();
  bool current = true;
  Object? verificationError;
  @override
  bool get isCurrent => current;
  @override
  Future<DateTime?> sendCode(String phone) async => DateTime.utc(2030);
  @override
  Future<String> verifyCode(String code) async {
    if (verificationError != null) throw verificationError!;
    return 'synthetic-grant';
  }

  @override
  Future<bool> savePassword({
    required String phone,
    required String resetToken,
    required String newPassword,
  }) => saved.future;
}

void main() {
  Future<void> openOtp(
    WidgetTester tester,
    _Session session,
    Future<void> Function() onSaved,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangePasswordScreen(session: session, onSaved: onSaved),
      ),
    );
    await tester.enterText(find.byType(TextFormField), '0200000000');
    await tester.tap(find.widgetWithText(FilledButton, 'Send Code'));
    await tester.pumpAndSettle();
    expect(find.byType(OtpVerificationScreen), findsOneWidget);
  }

  for (final ownsCompletion in [true, false]) {
    testWidgets(
      'password save only signs out the opening session (owner=$ownsCompletion)',
      (tester) async {
        final session = _Session();
        var signOuts = 0;
        await openOtp(tester, session, () async {
          signOuts++;
        });
        await tester
            .widget<OtpVerificationScreen>(find.byType(OtpVerificationScreen))
            .onVerify('1234');
        await tester.pump();
        final saving = tester
            .widget<SetNewPasswordForm>(find.byType(SetNewPasswordForm))
            .onSaved('fixture-new-password');
        session.current = ownsCompletion;
        session.saved.complete(ownsCompletion);
        // The server acknowledged the password save in either case. A changed
        // session suppresses the old logout callback rather than reporting failure.
        expect(await saving, isTrue);
        expect(signOuts, ownsCompletion ? 1 : 0);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets('changed-session OTP failure is not labelled Incorrect Code', (
    tester,
  ) async {
    final session = _Session()
      ..verificationError = const ApiException(
        statusCode: 401,
        message: 'session changed',
      );
    await openOtp(tester, session, () async {});
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Verify Code'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect Code'), findsNothing);
    expect(
      find.text(
        'This request could not be authorized. Sign in again or request a new code.',
      ),
      findsOneWidget,
    );
    expect(find.byType(SetNewPasswordForm), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
