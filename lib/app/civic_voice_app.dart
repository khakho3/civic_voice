import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/citizen/screens/citizen_alerts_screen.dart';
import '../features/citizen/screens/citizen_dashboard_screen.dart';
import '../features/citizen/screens/citizen_profile_screen.dart';
import '../features/citizen/screens/citizen_reports_screen.dart';
import '../features/citizen/screens/create_report_screen.dart';
import '../features/citizen/screens/photo_upload_screen.dart';
import '../features/citizen/screens/report_submitted_screen.dart';
import '../features/citizen/screens/report_tracking_screen.dart';
import '../features/citizen/screens/review_report_screen.dart';
import '../features/citizen/screens/splash_screen.dart';

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
          routes: {
            SplashScreen.routeName: (_) => const SplashScreen(),
            CitizenAlertsScreen.routeName: (_) => const CitizenAlertsScreen(),
            CitizenDashboardScreen.routeName: (_) =>
                const CitizenDashboardScreen(),
            CitizenProfileScreen.routeName: (_) => const CitizenProfileScreen(),
            CitizenReportsScreen.routeName: (_) => const CitizenReportsScreen(),
            CreateReportScreen.routeName: (_) => const CreateReportScreen(),
            PhotoUploadScreen.routeName: (_) => const PhotoUploadScreen(),
            ReviewReportScreen.routeName: (_) => const ReviewReportScreen(),
            ReportSubmittedScreen.routeName: (_) =>
                const ReportSubmittedScreen(),
            ReportTrackingScreen.routeName: (_) =>
                const ReportTrackingScreen(reportId: ''),
          },
          initialRoute: SplashScreen.routeName,
        );
      },
    );
  }
}
