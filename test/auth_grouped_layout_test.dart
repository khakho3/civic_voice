import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0, 412.0, 1440.0]) {
      testWidgets(
        'grouped password task retains accessible brand/back/keyboard width=$width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
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
              home: ChangePasswordScreen(
                onSaved: () async {},
                onBack: () => backs++,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final card = find.byType(AuthFormSurface);
          expect(
            find.descendant(of: card, matching: find.text('Change Password')),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: card,
              matching: find.textContaining('Enter your account phone number'),
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
          await tester.tap(find.byTooltip('Go back'));
          await tester.pump();
          expect(backs, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
