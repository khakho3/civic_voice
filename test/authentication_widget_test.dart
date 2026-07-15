import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:civic_voice/main.dart';

void main() {
  Future<void> openWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  }

  testWidgets('Welcome to Login flow', (WidgetTester tester) async {
    await openWelcomeScreen(tester);

    final loginButton = find.widgetWithText(FilledButton, 'Login');

    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Welcome to Registration flow', (WidgetTester tester) async {
    // This starts a new copy of the app, like restarting it.
    await openWelcomeScreen(tester);

    final registerButton = find.widgetWithText(OutlinedButton, 'Register');

    await tester.ensureVisible(registerButton);
    await tester.tap(registerButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RegistrationScreen), findsOneWidget);
  });

  testWidgets('Login to Forgot Password flow', (WidgetTester tester) async {
    await openWelcomeScreen(tester);

    final loginButton = find.widgetWithText(FilledButton, 'Login');

    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(LoginScreen), findsOneWidget);

    final forgotPasswordButton = find.widgetWithText(
      TextButton,
      'Forgot Password?',
    );

    await tester.ensureVisible(forgotPasswordButton);
    await tester.tap(forgotPasswordButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
  });
}
