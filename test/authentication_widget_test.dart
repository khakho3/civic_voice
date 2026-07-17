import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/test_role_selector_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/main.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await MockAuthService().initialize();
    await MockAuthService().clearUser();
  });

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
  }

  Future<void> openWelcomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const CivicVoiceApp(initialRoute: AppRoutes.welcome),
    );
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  }

  Future<void> reachFinalSlide(WidgetTester tester) async {
    await openWelcomeScreen(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Resolve.'), findsOneWidget);
  }

  testWidgets('Mock auth selector chooses Admin dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pumpAndSettle();

    expect(find.byType(TestRoleSelectorScreen), findsOneWidget);

    await tester.tap(find.text('Admin'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(MockAuthService().getCurrentRole(), AppRole.systemAdministrator);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });

  testWidgets('Welcome Login link opens Test Role Selector', (
    WidgetTester tester,
  ) async {
    await reachFinalSlide(tester);

    await tapVisible(tester, find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(TestRoleSelectorScreen), findsOneWidget);
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
    await tester.pumpWidget(const CivicVoiceApp(initialRoute: AppRoutes.login));
    await tester.pump();

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

  testWidgets('Login Sign In flow opens Citizen Dashboard', (
    WidgetTester tester,
  ) async {
    await MockAuthService().selectRole(AppRole.citizen);
    await tester.pumpWidget(const CivicVoiceApp(initialRoute: AppRoutes.login));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'amina@example.com');
    await tester.enterText(fields.at(1), 'password');

    final signIn = find.widgetWithText(FilledButton, 'Sign In');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.byType(CitizenDashboardScreen), findsOneWidget);
  });

  testWidgets('Registration Create Account flow opens Citizen Dashboard', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CivicVoiceApp(initialRoute: AppRoutes.registration),
    );
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Amina Mensah');
    await tester.enterText(fields.at(1), 'amina@example.com');
    await tester.enterText(fields.at(2), '+1 555 0100');
    await tester.enterText(fields.at(3), 'password123');
    await tester.enterText(fields.at(4), 'password123');

    final policy = find.byType(Checkbox);
    await tester.ensureVisible(policy);
    await tester.tap(policy);
    await tester.pump();

    final createAccount = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.byType(CitizenDashboardScreen), findsOneWidget);
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

  testWidgets('Authentication forms are scroll-safe on a narrow phone', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cases = <({Widget screen, Finder finalAction})>[
      (
        screen: const LoginScreen(),
        finalAction: find.widgetWithText(FilledButton, 'Sign In'),
      ),
      (
        screen: const RegistrationScreen(),
        finalAction: find.widgetWithText(FilledButton, 'Create Account'),
      ),
      (
        screen: const ForgotPasswordScreen(),
        finalAction: find.widgetWithText(FilledButton, 'Send Reset Link'),
      ),
      (
        screen: const ChangePasswordScreen(),
        finalAction: find.widgetWithText(FilledButton, 'Update Password'),
      ),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: testCase.screen),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      await tester.ensureVisible(testCase.finalAction);
      await tester.pump();
      expect(testCase.finalAction, findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const RegistrationScreen()),
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byType(TextFormField).last);
    await tester.pump();
    final createAccount = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createAccount);
    await tester.pump();
    expect(createAccount, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Change Password validates required fields, a short new password, and '
    'a mismatched confirmation',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ChangePasswordScreen()),
      );
      await tester.pump();

      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Update Password'),
      );
      await tester.pump();

      expect(find.text('Please enter your current password.'), findsOneWidget);
      expect(find.text('Please enter a new password.'), findsOneWidget);
      expect(find.text('Please confirm your new password.'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPass1');
      await tester.enterText(fields.at(1), 'short');
      await tester.enterText(fields.at(2), 'short');
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Update Password'),
      );
      await tester.pump();

      expect(
        find.text('Password must contain at least 8 characters.'),
        findsOneWidget,
      );

      await tester.enterText(fields.at(1), 'newPassword1');
      await tester.enterText(fields.at(2), 'differentPassword');
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Update Password'),
      );
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    },
  );

  testWidgets(
    'Change Password with matching valid fields shows the success banner '
    'and clears the form',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(428, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const ChangePasswordScreen()),
      );
      await tester.pump();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'currentPass1');
      await tester.enterText(fields.at(1), 'newPassword1');
      await tester.enterText(fields.at(2), 'newPassword1');
      await tapVisible(
        tester,
        find.widgetWithText(FilledButton, 'Update Password'),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Password Updated'), findsOneWidget);
      for (final field in tester.widgetList<TextFormField>(fields)) {
        expect(field.controller?.text, isEmpty);
      }
    },
  );
}
