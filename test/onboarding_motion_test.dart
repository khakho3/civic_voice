import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _welcome({bool reduceMotion = false}) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: WelcomeScreen(
          onGetStarted: () {},
          onContinueAsGuest: () {},
          onLogin: () {},
        ),
      ),
    ),
  );
}

Finder _next() => find.widgetWithText(FilledButton, 'Next');

void main() {
  testWidgets('rapid Next taps advance one page each and never overshoot', (
    tester,
  ) async {
    await tester.pumpWidget(_welcome());
    await tester.pumpAndSettle();

    await tester.tap(_next());
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(_next(), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(_next(), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Resolve.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Next then Previous returns to Report; Previous only on Track', (
    tester,
  ) async {
    await tester.pumpWidget(_welcome());
    await tester.pumpAndSettle();
    expect(find.text('Previous'), findsNothing);

    await tester.tap(_next());
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextButton, 'Previous'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Previous'));
    await tester.pumpAndSettle();
    expect(find.text('Report.'), findsOneWidget);
    expect(find.text('Previous'), findsNothing);
  });

  testWidgets('artwork does not jump when Previous appears', (tester) async {
    await tester.pumpWidget(_welcome());
    await tester.pumpAndSettle();
    final reportArt = tester.getRect(find.byType(Image).first);

    await tester.tap(_next());
    await tester.pumpAndSettle();
    final trackArt = tester.getRect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Track.'),
          matching: find.byType(SingleChildScrollView),
        ),
        matching: find.byType(Image),
      ),
    );

    expect(trackArt.top, reportArt.top);
    expect(trackArt.height, reportArt.height);
  });

  testWidgets('Skip travels to the final slide with its actions', (
    tester,
  ) async {
    await tester.pumpWidget(_welcome());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Resolve.'), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, 'Continue as Guest'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion jumps between slides without animating', (
    tester,
  ) async {
    await tester.pumpWidget(_welcome(reduceMotion: true));
    await tester.pumpAndSettle();

    await tester.tap(_next());
    await tester.pump();
    // No page animation runs: one frame later Track is already centred.
    final screenCentre = tester.getSize(find.byType(Scaffold)).width / 2;
    expect(
      tester.getCenter(find.text('Track.')).dx,
      moreOrLessEquals(screenCentre, epsilon: 1),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Resolve.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
