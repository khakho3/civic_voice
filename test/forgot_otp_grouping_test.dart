import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

void main() {
  for (final width in [320.0, 390.0, 412.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'forgot OTP default keeps message, retry and Back in reach $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var backs = 0, resends = 0;
          String? code;
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.5),
                  disableAnimations: true,
                  viewInsets: const EdgeInsets.only(bottom: 300),
                ),
                child: child!,
              ),
              home: OtpVerificationScreen(
                phoneNumber: '0200000000',
                purpose: OtpPurpose.forgotPassword,
                expiresAt: DateTime.now().add(const Duration(minutes: 5)),
                resendCooldownDuration: Duration.zero,
                onBack: () => backs++,
                onVerify: (value) async {
                  code = value;
                  return false;
                },
                onResend: () async {
                  resends++;
                  return DateTime.now().add(const Duration(minutes: 5));
                },
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = find.byType(RecoveryAuthFormSurface);
          expect(
            find.descendant(of: card, matching: find.text('Verify Reset Code')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: card,
              matching: find.text('We sent a code to 0200000000.'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(of: card, matching: find.text('CivicVoice')),
            findsNothing,
          );
          await tester.enterText(find.byType(TextField), '1234');
          final verify = find.text('Verify Code');
          await tester.ensureVisible(verify);
          await tester.pumpAndSettle();
          expect(tester.getRect(verify).bottom, lessThanOrEqualTo(600));
          await tester.tap(verify);
          await tester.pumpAndSettle();
          expect(code, '1234');
          expect(
            find.descendant(of: card, matching: find.text('Incorrect Code')),
            findsOneWidget,
          );
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            '1234',
          );
          final resend = find.text('Resend Code');
          await tester.ensureVisible(resend);
          await tester.pumpAndSettle();
          await tester.tap(resend);
          await tester.pumpAndSettle();
          expect(resends, 1);
          expect(find.text('Code Resent'), findsOneWidget);
          await tester.tap(find.byTooltip('Go back'));
          await tester.pumpAndSettle();
          expect(backs, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
