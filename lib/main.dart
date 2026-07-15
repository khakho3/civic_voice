import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/profile_screen.dart' as auth;
import 'features/authentication/screens/registration_screen.dart';
import 'features/authentication/screens/welcome_screen.dart';
import 'features/citizen/screens/citizen_alerts_screen.dart';
import 'features/citizen/screens/citizen_dashboard_screen.dart';
import 'features/citizen/screens/citizen_profile_screen.dart';
import 'features/citizen/screens/citizen_reports_screen.dart';
import 'features/citizen/screens/create_report_screen.dart';
import 'features/citizen/screens/photo_upload_screen.dart';
import 'features/citizen/screens/report_submitted_screen.dart';
import 'features/citizen/screens/report_tracking_screen.dart';
import 'features/citizen/screens/review_report_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadSavedTheme();
  runApp(const CivicVoiceApp());
}

/// Every route name in the app in one place — merges authentication's
/// original `AppRoutes` class with every citizen screen's own scattered
/// `static const routeName` statics, so there's a single registry instead
/// of two competing ones.
abstract final class AppRoutes {
  const AppRoutes._();

  // Authentication — the native splash hands off directly to onboarding.
  static const welcome = '/welcome';
  static const login = '/login';
  static const registration = '/registration';
  static const forgotPassword = '/forgot-password';
  static const profile = '/profile';

  // Citizen.
  static const citizenDashboard = '/citizen/dashboard';
  static const citizenAlerts = '/citizen/alerts';
  static const citizenProfile = '/citizen/profile';
  static const citizenReports = '/citizen/reports';
  static const citizenCreateReport = '/citizen/create-report';
  static const citizenPhotoUpload = '/citizen/photo-upload';
  static const citizenReportSubmitted = '/citizen/report-submitted';
  static const citizenReportTracking = '/citizen/report-tracking';
  static const citizenReviewReport = '/citizen/review-report';
}

class CivicVoiceApp extends StatelessWidget {
  const CivicVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'CivicVoice',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          themeAnimationDuration: AppMotionDuration.emphasized,
          themeAnimationCurve: AppMotionCurve.emphasized,
          initialRoute: AppRoutes.welcome,
          // Admin/Ministry/Municipal/Maintenance aren't wired in below —
          // there's no auth/RBAC yet to route a signed-in user to the
          // correct module, so reaching them for manual QA still means
          // temporarily swapping `initialRoute` for one of their own
          // screens. The real app entry point is the onboarding/login flow,
          // not a module dashboard.
          routes: {
            AppRoutes.welcome: (context) => WelcomeScreen(
              state: WelcomeViewState.loading,
              onLogin: () => Navigator.of(context).pushNamed(AppRoutes.login),
              onRegister: () =>
                  Navigator.of(context).pushNamed(AppRoutes.registration),
            ),
            AppRoutes.login: (context) => LoginScreen(
              state: LoginViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onSignIn: () {
                // TODO(auth): navigate to AppRoutes.citizenDashboard once
                // Firebase sign-in is implemented.
              },
              onForgotPassword: () =>
                  Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
              onRegister: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.registration),
            ),
            AppRoutes.registration: (context) => RegistrationScreen(
              state: RegistrationViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onCreateAccount: () {
                // TODO(auth): navigate to AppRoutes.citizenDashboard once
                // Firebase registration is implemented.
              },
              onLogin: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            ),
            AppRoutes.forgotPassword: (context) => ForgotPasswordScreen(
              state: ForgotPasswordViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onSendResetLink: (emailAddress) {
                // TODO(auth): Firebase password reset will be connected
                // later.
              },
              onBackToLogin: () => Navigator.of(context).maybePop(),
            ),
            AppRoutes.profile: (context) => auth.ProfileScreen(
              onLogout: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
            ),
            AppRoutes.citizenDashboard: (_) => const CitizenDashboardScreen(),
            AppRoutes.citizenAlerts: (_) => const CitizenAlertsScreen(),
            AppRoutes.citizenProfile: (_) => const CitizenProfileScreen(),
            AppRoutes.citizenReports: (_) => const CitizenReportsScreen(),
            AppRoutes.citizenCreateReport: (_) => const CreateReportScreen(),
            AppRoutes.citizenPhotoUpload: (_) => const PhotoUploadScreen(),
            AppRoutes.citizenReviewReport: (_) => const ReviewReportScreen(),
            AppRoutes.citizenReportSubmitted: (_) =>
                const ReportSubmittedScreen(),
            AppRoutes.citizenReportTracking: (_) =>
                const ReportTrackingScreen(reportId: ''),
          },
        );
      },
    );
  }
}
