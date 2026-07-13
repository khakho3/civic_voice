import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/ministry/screens/ministry_analytics_screen.dart';
import 'features/ministry/screens/ministry_dashboard_screen.dart';
import 'features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'features/ministry/screens/ministry_reports_screen.dart';

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
      home: const _MinistryRoot(),
    );
  }
}

/// Temporary root shell wiring the Ministry Supervisor screens built so
/// far — a placeholder until a proper named-route/navigator setup is worth
/// introducing (once more of the module's six screens exist), matching how
/// the Municipal Officer module's own root started.
enum _MinistryScreen { dashboard, analytics, municipalities, reports }

class _MinistryRoot extends StatefulWidget {
  const _MinistryRoot();

  @override
  State<_MinistryRoot> createState() => _MinistryRootState();
}

class _MinistryRootState extends State<_MinistryRoot> {
  _MinistryScreen _current = _MinistryScreen.dashboard;

  @override
  Widget build(BuildContext context) {
    return switch (_current) {
      _MinistryScreen.dashboard => MinistryDashboardScreen(
        onNavigateToAnalytics: () =>
            setState(() => _current = _MinistryScreen.analytics),
        onNavigateToMunicipalities: () =>
            setState(() => _current = _MinistryScreen.municipalities),
        onNavigateToReports: () =>
            setState(() => _current = _MinistryScreen.reports),
        // Profile isn't built yet (MIN-006) — wire this up once it lands,
        // matching how Municipal Officer's root grew incrementally.
      ),
      _MinistryScreen.analytics => MinistryAnalyticsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToMunicipalities: () =>
            setState(() => _current = _MinistryScreen.municipalities),
        onNavigateToReports: () =>
            setState(() => _current = _MinistryScreen.reports),
      ),
      _MinistryScreen.municipalities => MinistryMunicipalPerformanceScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToAnalytics: () =>
            setState(() => _current = _MinistryScreen.analytics),
        onNavigateToReports: () =>
            setState(() => _current = _MinistryScreen.reports),
      ),
      _MinistryScreen.reports => MinistryReportsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToAnalytics: () =>
            setState(() => _current = _MinistryScreen.analytics),
        onNavigateToMunicipalities: () =>
            setState(() => _current = _MinistryScreen.municipalities),
        // onViewReportInsights isn't built yet (MIN-005) — wire this up
        // once it lands.
      ),
    };
  }
}
