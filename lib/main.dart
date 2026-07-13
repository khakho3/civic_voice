import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/maintenance/screens/dashboard_screen.dart';

void main() {
  runApp(const CivicVoiceApp());
}

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
      home: const DashboardScreen(),
    );
  }
}