import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/bio_lock_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/set_new_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/test_role_selector_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/main.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/ghana_assemblies_data.dart';
import 'package:civic_voice/models/region.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/app_cache_service.dart';
import 'package:civic_voice/services/mock_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppCacheService.instance.initialize();
    await MockAuthService().initialize();
    await MockAuthService().clearUser();
    // Widget tests must never hit the real dev backend — point at an
    // address nothing listens on so the real network calls main.dart's
    // auth routes now make fail fast and deterministically, rather than
    // depending on whether civic_voice_api happens to be running on
    // whatever machine runs this test suite (it usually is).
    ApiClient.baseUrl = 'http://127.0.0.1:1';
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

  testWidgets('cold start gates a signed-in user when app lock is enabled', (
    tester,
  ) async {
    await MockAuthService().selectRole(AppRole.citizen);
    await AppCacheService.instance.setBiometricLockEnabled(true);

    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pump();

    expect(find.byType(BioLockScreen), findsOneWidget);
    expect(find.byType(CitizenDashboardScreen), findsNothing);
  });

  testWidgets('cold start skips app lock when the preference is disabled', (
    tester,
  ) async {
    await MockAuthService().selectRole(AppRole.citizen);
    await AppCacheService.instance.setBiometricLockEnabled(false);

    await tester.pumpWidget(const CivicVoiceApp());
    await tester.pump();

    expect(find.byType(BioLockScreen), findsNothing);
    expect(find.byType(CitizenDashboardScreen), findsOneWidget);
  });

  testWidgets('Mock auth selector chooses Admin dashboard', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const CivicVoiceApp(initialRoute: AppRoutes.testRoleSelector),
    );
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

  testWidgets('Test Role Selector resets Admin Tier to Super Admin when System '
      'Administrator is freshly reselected after a different role', (
    WidgetTester tester,
  ) async {
    // Simulate a prior session that tested Admin tier for Kumasi — the
    // exact sticky-state scenario that silently hid Super-Admin-only
    // content (e.g. the health stats) the next time "Admin" was picked.
    await MockAuthService().selectRole(
      AppRole.systemAdministrator,
      adminTier: AdminTier.admin,
      region: Region.ashanti,
      assembly: assemblyNamed(Region.ashanti, 'Kumasi'),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TestRoleSelectorScreen(onRoleSelected: (_) {}, onSkip: () {}),
      ),
    );
    await tester.pump();

    // Switch away to a different role, then back to Admin — a fresh
    // reselection, not a resumed session.
    await tester.tap(find.text('Citizen'));
    await tester.pump();
    await tester.tap(find.text('Admin'));
    await tester.pump();

    final tierGroup = tester.widget<RadioGroup<AdminTier>>(
      find.byType(RadioGroup<AdminTier>),
    );
    expect(tierGroup.groupValue, AdminTier.superAdmin);
  });

  testWidgets('Welcome Login link opens real Login screen', (
    WidgetTester tester,
  ) async {
    await reachFinalSlide(tester);

    await tapVisible(tester, find.text('Already have an account? Log in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    // find.byTooltip resolves to Flutter's internal tooltip widget, not
    // IconButton itself, so casting it directly can throw a bad-cast error
    // depending on the SDK's tooltip implementation — find the IconButton
    // by its icon instead, which is stable regardless of that internal.
    final backButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(AppIcons.back),
        matching: find.byType(IconButton),
      ),
    );
    expect(backButton.onPressed, isNotNull);
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('Welcome to Registration flow', (WidgetTester tester) async {
    await reachFinalSlide(tester);

    await tapVisible(tester, find.widgetWithText(FilledButton, 'Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationScreen), findsOneWidget);
    // find.byTooltip resolves to Flutter's internal tooltip widget, not
    // IconButton itself, so casting it directly can throw a bad-cast error
    // depending on the SDK's tooltip implementation — find the IconButton
    // by its icon instead, which is stable regardless of that internal.
    final backButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(AppIcons.back),
        matching: find.byType(IconButton),
      ),
    );
    expect(backButton.onPressed, isNotNull);
    await tester.tap(find.byTooltip('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('root Login and Registration routes disable the back button', (
    tester,
  ) async {
    for (final route in [AppRoutes.login, AppRoutes.registration]) {
      await tester.pumpWidget(CivicVoiceApp(initialRoute: route));
      await tester.pump();

      // find.byTooltip resolves to Flutter's internal tooltip widget, not
      // IconButton itself, so casting it directly can throw a bad-cast error
      // depending on the SDK's tooltip implementation — find the IconButton
      // by its icon instead, which is stable regardless of that internal.
      final backButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(AppIcons.back),
          matching: find.byType(IconButton),
        ),
      );
      expect(backButton.onPressed, isNull);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Welcome guest flow attempts a real anonymous session and fails '
      'gracefully without a reachable backend/Firebase', (
    WidgetTester tester,
  ) async {
    // Continue as Guest now signs in with real Firebase Anonymous Auth
    // and syncs against the real backend (see main.dart's
    // _continueAsGuest) instead of a bare local navigation — reaching
    // the real Citizen Dashboard requires both, neither of which is
    // available in this widget test sandbox. What's verifiable here is
    // that a failure is handled cleanly (an error SnackBar, no crash,
    // no stuck loading state) rather than the flow silently breaking.
    await reachFinalSlide(tester);

    await tapVisible(
      tester,
      find.widgetWithText(TextButton, 'Continue as Guest'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CitizenDashboardScreen), findsNothing);
    expect(
      find.text(
        'Could not continue as guest. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('completed onboarding opens directly on the action slide', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: WelcomeScreen(
          initialPage: 2,
          onGetStarted: () {},
          onContinueAsGuest: () {},
          onLogin: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Resolve.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Get Started'), findsOneWidget);
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

  testWidgets('Login submits the keep-signed-in selection', (tester) async {
    String? submittedPhone;
    String? submittedPassword;
    bool? submittedKeepSignedIn;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(
          onSignIn: (phone, password, keepSignedIn) {
            submittedPhone = phone;
            submittedPassword = password;
            submittedKeepSignedIn = keepSignedIn;
          },
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0551234567');
    await tester.enterText(fields.at(1), 'secret-password');
    await tester.tap(find.byType(Checkbox));
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Sign In'));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));

    expect(submittedPhone, '0551234567');
    expect(submittedPassword, 'secret-password');
    expect(submittedKeepSignedIn, isTrue);
    expect(find.byTooltip('Paste password'), findsNothing);
  });

  testWidgets('Login Sign In submits to the real auth flow and recovers from a '
      'failed request', (WidgetTester tester) async {
    // Sign-in now calls the real backend + Firebase Auth (see
    // main.dart's _LoginRouteState) instead of the old MockAuthService
    // shortcut, so a widget test can no longer assert it lands on the
    // real Citizen Dashboard without a live backend and Firebase — that
    // path is covered by manual device testing instead. What's still
    // verifiable here, against the deliberately-unreachable baseUrl set
    // in setUp(): a failed request is handled cleanly — no crash, no
    // hang, no accidental navigation — rather than the flow silently
    // breaking. (Not asserting on the loading spinner mid-flight: the
    // flutter_test HTTP fake resolves fast enough that it can come and
    // go within a single pump, making that assertion racy.)
    await tester.pumpWidget(const CivicVoiceApp(initialRoute: AppRoutes.login));
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '0245550198');
    await tester.enterText(fields.at(1), 'password');

    final signIn = find.widgetWithText(FilledButton, 'Sign In');
    await tester.ensureVisible(signIn);
    await tester.tap(signIn);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Registration Create Account submits to the real auth flow and '
      'recovers from a failed request', (WidgetTester tester) async {
    // Same reasoning as the Login test above — account creation now
    // requires a real SMS OTP round trip through the backend before the
    // OTP screen even appears (see main.dart's _RegistrationRouteState),
    // so the full flow through to the Citizen Dashboard is covered by
    // manual device testing, not this widget test suite. Not asserting
    // on the loading spinner mid-flight for the same racy-timing reason
    // as the Login test above.
    await tester.pumpWidget(
      const CivicVoiceApp(initialRoute: AppRoutes.registration),
    );
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Amina Mensah');
    await tester.enterText(fields.at(1), '0245550100');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');

    final policy = find.byType(Checkbox);
    await tester.ensureVisible(policy);
    await tester.tap(policy);
    await tester.pump();

    final createAccount = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(RegistrationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
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
        finalAction: find.widgetWithText(FilledButton, 'Send Code'),
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
    await tester.pump();
    final scrollView = find.byType(SingleChildScrollView);
    final fullHeight = tester.getSize(scrollView).height;
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.resizeToAvoidBottomInset, isFalse);
    expect(tester.getSize(scrollView).height, fullHeight);
    final keyboardPadding = tester
        .widget<SingleChildScrollView>(scrollView)
        .padding!
        .resolve(TextDirection.ltr);
    expect(keyboardPadding.bottom, AppSpacing.lg + 340);

    await tester.tap(find.byType(TextFormField).last);
    await tester.pump();
    final createAccount = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createAccount);
    await tester.pump();
    expect(createAccount, findsOneWidget);

    FocusManager.instance.primaryFocus?.unfocus();
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    final closedPadding = tester
        .widget<SingleChildScrollView>(scrollView)
        .padding!
        .resolve(TextDirection.ltr);
    expect(closedPadding.bottom, AppSpacing.lg);
    expect(tester.getSize(scrollView).height, fullHeight);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP code expiry disables verify action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpVerificationScreen(
          phoneNumber: '+233 24 555 0100',
          purpose: OtpPurpose.registration,
          codeExpiryDuration: const Duration(seconds: 1),
          resendCooldownDuration: const Duration(seconds: 3),
          onVerify: (_) async => true,
        ),
      ),
    );

    expect(find.text('Paste Code'), findsNothing);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Verify Code'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Code Expired'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Verify Code'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('Change Password asks for a phone before sending an OTP', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChangePasswordScreen(onSaved: () async {}),
      ),
    );

    expect(
      find.text(
        'Enter your account phone number and we will send a verification code.',
      ),
      findsOneWidget,
    );
    expect(find.text('Send Code'), findsOneWidget);
    expect(find.byType(OtpVerificationScreen), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Send Code'));
    await tester.pump();
    expect(find.text('Please enter your phone number.'), findsOneWidget);
  });

  testWidgets('OTP resend cooldown elapses independently', (
    WidgetTester tester,
  ) async {
    var resendCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpVerificationScreen(
          phoneNumber: '+233 24 555 0100',
          purpose: OtpPurpose.forgotPassword,
          codeExpiryDuration: const Duration(seconds: 10),
          resendCooldownDuration: const Duration(seconds: 1),
          onVerify: (_) async => true,
          onResend: () async {
            resendCount++;
          },
        ),
      ),
    );

    expect(find.textContaining('Resend code in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.widgetWithText(TextButton, 'Resend Code'));
    await tester.pump();
    expect(resendCount, 1);
    expect(find.text('Code Resent'), findsOneWidget);
  });

  testWidgets('invalid OTP remains on verification and shows an error', (
    WidgetTester tester,
  ) async {
    var verificationAttempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: OtpVerificationScreen(
          phoneNumber: '+233 24 555 0100',
          purpose: OtpPurpose.forgotPassword,
          onVerify: (_) async {
            verificationAttempts++;
            return false;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '0000');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Verify Code'));
    await tester.pump();

    expect(verificationAttempts, 1);
    expect(find.byType(OtpVerificationScreen), findsOneWidget);
    expect(find.text('Incorrect Code'), findsOneWidget);
    expect(
      find.text('That code is wrong or has expired. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('Set new password validates both fields', (
    WidgetTester tester,
  ) async {
    var saved = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: SetNewPasswordScreen(
          purpose: SetNewPasswordPurpose.forgotPassword,
          onSaved: (_) async {
            saved = true;
            return true;
          },
        ),
      ),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Save New Password'));
    await tester.pump();
    expect(find.text('Please enter a new password.'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'password123');
    await tester.enterText(fields.at(1), 'password456');
    await tester.tap(find.widgetWithText(FilledButton, 'Save New Password'));
    await tester.pump();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Save New Password'));
    await tester.pump(const Duration(seconds: 1));
    expect(saved, isTrue);
  });
}
