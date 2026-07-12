import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/citizen/screens/citizen_dashboard_screen.dart';
import '../features/citizen/screens/create_report_screen.dart';
import '../features/citizen/screens/photo_upload_screen.dart';
import '../features/citizen/screens/splash_screen.dart';

class CivicVoiceApp extends StatelessWidget {
  const CivicVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CivicVoice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: AppTheme.themeMode,
      routes: {
        SplashScreen.routeName: (_) => const SplashScreen(),
        CitizenDashboardScreen.routeName: (_) => const CitizenDashboardScreen(),
        CreateReportScreen.routeName: (_) => const CreateReportScreen(),
        PhotoUploadScreen.routeName: (_) => const PhotoUploadScreen(),
      },
      initialRoute: SplashScreen.routeName,
    );
  }
}
