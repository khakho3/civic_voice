import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

void main() {
  for (final forgot in [false, true]) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0, 412.0, 1440.0]) {
        testWidgets(
          'grouped password task retains accessible brand/back/keyboard forgot=$forgot width=$width dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            var backs = 0;
            String? submittedPhone;
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
                home: forgot
                    ? ForgotPasswordScreen(
                        onBack: () => backs++,
                        onBackToLogin: () => backs++,
                        onSendCode: (phone) => submittedPhone = phone,
                      )
                    : ChangePasswordScreen(
                        onSaved: () async {},
                        onBack: () => backs++,
                      ),
              ),
            );
            await tester.pumpAndSettle();
            final card = forgot
                ? find.byType(RecoveryAuthFormSurface)
                : find.byType(AuthFormSurface);
            expect(
              find.descendant(
                of: card,
                matching: find.text(
                  forgot ? 'Forgot Password' : 'Change Password',
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: card,
                matching: find.text(
                  forgot
                      ? 'Enter your phone number and we will send a verification code.'
                      : 'Enter your account phone number and we will send a verification code.',
                ),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(of: card, matching: find.text('Send Code')),
              findsOneWidget,
            );
            expect(
              find.descendant(of: card, matching: find.text('CivicVoice')),
              findsNothing,
            );
            final field = find.byType(TextFormField);
            await tester.enterText(field, '0200000000');
            await tester.pumpAndSettle();
            await tester.ensureVisible(find.text('Send Code'));
            await tester.pumpAndSettle();
            expect(
              tester.getRect(find.text('Send Code')).bottom,
              lessThanOrEqualTo(600),
            );
            if (forgot) {
              await tester.tap(find.text('Send Code'));
              await tester.pumpAndSettle();
              expect(submittedPhone, '0200000000');
              expect(
                find.descendant(of: card, matching: find.text('Back to Login')),
                findsOneWidget,
              );
            }
            await tester.tap(find.byTooltip('Go back'));
            await tester.pump();
            expect(backs, 1);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
