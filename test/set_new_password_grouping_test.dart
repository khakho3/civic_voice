import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/set_new_password_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

void main() {
  for (final purpose in SetNewPasswordPurpose.values) {
    for (final dark in [false, true]) {
      for (final width in [320.0, 390.0, 412.0, 1440.0]) {
        testWidgets(
          'password card keeps fields, failure and safe Back $purpose $width dark=$dark',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            String? submitted;
            var backs = 0;
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
                home: SetNewPasswordScreen(
                  purpose: purpose,
                  onBack: () => backs++,
                  onSaved: (value) async {
                    submitted = value;
                    return false;
                  },
                ),
              ),
            );
            await tester.pumpAndSettle();
            final firstLogin = purpose == SetNewPasswordPurpose.firstLogin;
            final title = switch (purpose) {
              SetNewPasswordPurpose.forgotPassword => 'Set New Password',
              SetNewPasswordPurpose.changePassword => 'Change Password',
              SetNewPasswordPurpose.firstLogin => 'Create Your Password',
            };
            final card = find.byType(AuthFormSurface);
            expect(
              find.descendant(of: card, matching: find.text(title)),
              findsOneWidget,
            );
            expect(
              find.descendant(of: card, matching: find.text('CivicVoice')),
              findsNothing,
            );
            if (firstLogin) {
              expect(
                find.descendant(
                  of: card,
                  matching: find.text('Temporary Password Used'),
                ),
                findsOneWidget,
              );
              expect(
                find.descendant(
                  of: card,
                  matching: find.text('This step cannot be skipped.'),
                ),
                findsOneWidget,
              );
              expect(find.byTooltip('Go back'), findsNothing);
            }
            const password = 'FixturePassword#12';
            await tester.enterText(find.byType(TextFormField).first, password);
            final show = find.byTooltip('Show password').first;
            await tester.ensureVisible(show);
            await tester.tap(show);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<EditableText>(find.byType(EditableText).first)
                  .obscureText,
              isFalse,
            );
            await tester.enterText(find.byType(TextFormField).last, password);
            final save = find.byType(FilledButton);
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            expect(tester.getRect(save).bottom, lessThanOrEqualTo(600));
            await tester.tap(save);
            await tester.pumpAndSettle();
            expect(submitted, password);
            expect(
              find.descendant(of: card, matching: find.text('Could Not Save')),
              findsOneWidget,
            );
            for (final field in tester.widgetList<TextFormField>(
              find.byType(TextFormField),
            )) {
              expect(field.controller!.text, password);
            }
            if (!firstLogin) {
              await tester.tap(find.byTooltip('Go back'));
              await tester.pumpAndSettle();
              expect(backs, 1);
            }
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
}
