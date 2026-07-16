import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/main.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Future<void> openWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  }

  Future<void> reachFinalSlide(WidgetTester tester) async {
    await openWelcomeScreen(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Resolve.'), findsOneWidget);
  }

  testWidgets('Welcome to Login flow', (WidgetTester tester) async {
    await reachFinalSlide(tester);

    await tapVisible(tester, find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Welcome to Registration flow', (WidgetTester tester) async {
    await reachFinalSlide(tester);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('Welcome guest flow opens Citizen Dashboard', (
    WidgetTester tester,
  ) async {
    await reachFinalSlide(tester);

    await tapVisible(
      tester,
      find.widgetWithText(TextButton, 'Continue as Guest'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CitizenDashboardScreen), findsOneWidget);
  });

  testWidgets('Login to Forgot Password flow', (WidgetTester tester) async {
    await reachFinalSlide(tester);
    await tapVisible(tester, find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);

    final forgotPasswordButton = find.widgetWithText(
      TextButton,
      'Forgot Password?',
    );

    await tester.ensureVisible(forgotPasswordButton);
    await tester.tap(forgotPasswordButton);
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });

  testWidgets('Onboarding pages do not overflow on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openWelcomeScreen(tester);
    expect(tester.takeException(), isNull);

    final firstNextButton = find.widgetWithText(FilledButton, 'Next');
    final anchoredCtaY = tester.getTopLeft(firstNextButton).dy;

    await tapVisible(tester, firstNextButton);
    await tester.pumpAndSettle();
    expect(find.text('Track.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, 'Next')).dy,
      anchoredCtaY,
    );
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(find.text('Resolve.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(FilledButton, 'Get Started')).dy,
      anchoredCtaY,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Onboarding illustrations integrate in dark mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: WelcomeScreen(
          onGetStarted: () {},
          onContinueAsGuest: () {},
          onLogin: () {},
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
