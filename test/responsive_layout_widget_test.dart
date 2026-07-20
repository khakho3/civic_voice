import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/admin/screens/admin_dashboard_screen.dart';
import 'package:civic_voice/features/admin/screens/admin_profile_screen.dart';
import 'package:civic_voice/features/authentication/screens/change_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/forgot_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/login_screen.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/screens/registration_screen.dart';
import 'package:civic_voice/features/authentication/screens/set_new_password_screen.dart';
import 'package:civic_voice/features/authentication/screens/welcome_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_alerts_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_dashboard_screen.dart';
import 'package:civic_voice/features/citizen/screens/citizen_profile_screen.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart'
    as maintenance;
import 'package:civic_voice/features/maintenance/screens/profile_screen.dart'
    as maintenance;
import 'package:civic_voice/features/ministry/screens/ministry_dashboard_screen.dart';
import 'package:civic_voice/features/ministry/screens/ministry_profile_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_dashboard_screen.dart';
import 'package:civic_voice/features/municipal/screens/municipal_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every screen the app-wide visual redesign pass touched, checked for
/// layout exceptions (RenderFlex overflow etc.) across a spread of real
/// device widths — not just whatever device happens to be on hand.
/// Verifying on one physical phone is not the same as verifying across the
/// actual range of screens the app runs on; this is the automated stand-in
/// for that. `tester.takeException()` catches any overflow Flutter would
/// otherwise only report as a debug-mode banner.
void main() {
  void noop() {}
  Future<void> asyncNoop() async {}
  Future<bool> asyncVerify(String _) async => true;

  final surfaces = <String, Widget>{
    // Dashboards
    'citizen dashboard': const CitizenDashboardScreen(),
    'admin dashboard': const AdminDashboardScreen(),
    'ministry dashboard': const MinistryDashboardScreen(),
    'municipal dashboard': const MunicipalDashboardScreen(),
    'maintenance dashboard': const maintenance.DashboardScreen(),
    // Profiles — the five screens re-platformed onto the shared widget
    // library in this pass, most likely to regress on an unfamiliar width.
    'admin profile': const AdminProfileScreen(),
    'municipal profile': const MunicipalProfileScreen(),
    'ministry profile': const MinistryProfileScreen(),
    'maintenance profile': const maintenance.ProfileScreen(),
    'citizen profile': const CitizenProfileScreen(),
    // Citizen alerts — the deepest box-in-box nesting flattened this pass.
    'citizen alerts': const CitizenAlertsScreen(),
    // Auth — reskinned this pass; keyboard-specific pixel math is already
    // covered elsewhere (authentication_widget_test.dart), this just
    // checks plain layout at rest across widths.
    'welcome': WelcomeScreen(
      onGetStarted: noop,
      onContinueAsGuest: noop,
      onLogin: noop,
    ),
    'login': const LoginScreen(),
    'registration': const RegistrationScreen(),
    'forgot password': const ForgotPasswordScreen(),
    'otp verification': OtpVerificationScreen(
      phoneNumber: '+233241234567',
      purpose: OtpPurpose.registration,
      onVerify: asyncVerify,
    ),
    'set new password': SetNewPasswordScreen(
      purpose: SetNewPasswordPurpose.forgotPassword,
      onSaved: asyncVerify,
    ),
    'change password': ChangePasswordScreen(onSaved: asyncNoop),
  };

  // Real device widths spanning the actual spread this app runs on, not
  // just the one phone a preview happened to look fine on: the smallest
  // still-sold Android/iOS widths up through large phones and tablets.
  const sizes = <String, Size>{
    'very small phone (320w)': Size(320, 568), // iPhone SE 1st-gen class
    'small phone (360w)': Size(360, 640), // most common budget Android
    'compact phone (375w)': Size(375, 667), // iPhone SE 2/3
    'standard phone (393w)': Size(393, 852), // Pixel 6/7/8 class
    'large phone (430w)': Size(430, 932), // Pixel 9 Pro XL / iPhone Pro Max
    'tablet (768w)': Size(768, 1024), // iPad mini / small Android tablet
    'large tablet (1024w)': Size(1024, 1366), // iPad Pro class
  };

  for (final surface in surfaces.entries) {
    for (final viewport in sizes.entries) {
      testWidgets(
        '${surface.key} has no layout exception on ${viewport.key}',
        (tester) async {
          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            MaterialApp(theme: AppTheme.light, home: surface.value),
          );
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
