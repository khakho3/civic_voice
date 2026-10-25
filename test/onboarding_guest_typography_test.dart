import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';

void main() {
  for (final width in [320.0, 412.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'onboarding Guest keeps shared font and final-page gating $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme = dark ? AppTheme.dark : AppTheme.light;
          var guests = 0;
          for (var page = 0; page < 3; page++) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.5),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: WelcomeScreen(
                  initialPage: page,
                  onGetStarted: () {},
                  onContinueAsGuest: () => guests++,
                  onLogin: () {},
                ),
              ),
            );
            await tester.pumpAndSettle();
            final button = find.widgetWithText(TextButton, 'Continue as Guest');
            final renderedText = tester.widget<RichText>(
              find.descendant(of: button, matching: find.byType(RichText)),
            );
            expect(
              renderedText.text.style!.fontFamily,
              theme.textTheme.labelLarge!.fontFamily,
            );
            if (page < 2) {
              expect(tester.widget<TextButton>(button).onPressed, isNull);
            } else {
              await tester.ensureVisible(button);
              await tester.tap(button);
              await tester.pumpAndSettle();
              expect(guests, 1);
            }
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
