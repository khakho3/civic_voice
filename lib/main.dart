import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/ministry/screens/ministry_analytics_screen.dart';
import 'features/ministry/screens/ministry_dashboard_screen.dart';
import 'features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'features/ministry/screens/ministry_profile_screen.dart';
import 'features/ministry/screens/ministry_report_insights_screen.dart';
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

/// Root shell wiring all six Ministry Supervisor screens — a placeholder
/// until a proper named-route/navigator setup is worth introducing, matching
/// how the Municipal Officer module's own root started.
///
/// [_MinistryScreen.reportInsights] and [_MinistryScreen.profile] aren't
/// bottom-nav tabs (see their own screens' doc comments) — both are
/// drill-downs whose back arrow always returns to Dashboard, the spec's
/// exit point for each.
enum _MinistryScreen {
  dashboard,
  analytics,
  municipalities,
  reports,
  reportInsights,
  profile,
}

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
        onProfileTap: () => setState(() => _current = _MinistryScreen.profile),
      ),
      _MinistryScreen.analytics => MinistryAnalyticsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToMunicipalities: () =>
            setState(() => _current = _MinistryScreen.municipalities),
        onNavigateToReports: () =>
            setState(() => _current = _MinistryScreen.reports),
        onViewReportInsights: () =>
            setState(() => _current = _MinistryScreen.reportInsights),
        onProfileTap: () => setState(() => _current = _MinistryScreen.profile),
      ),
      _MinistryScreen.municipalities => MinistryMunicipalPerformanceScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToAnalytics: () =>
            setState(() => _current = _MinistryScreen.analytics),
        onNavigateToReports: () =>
            setState(() => _current = _MinistryScreen.reports),
        onProfileTap: () => setState(() => _current = _MinistryScreen.profile),
      ),
      _MinistryScreen.reports => MinistryReportsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MinistryScreen.dashboard),
        onNavigateToAnalytics: () =>
            setState(() => _current = _MinistryScreen.analytics),
        onNavigateToMunicipalities: () =>
            setState(() => _current = _MinistryScreen.municipalities),
        onViewReportInsights: () =>
            setState(() => _current = _MinistryScreen.reportInsights),
        onProfileTap: () => setState(() => _current = _MinistryScreen.profile),
      ),
      _MinistryScreen.reportInsights => MinistryReportInsightsScreen(
        onBack: () => setState(() => _current = _MinistryScreen.dashboard),
        // onViewFocusSummary isn't built yet — no dedicated screen is
        // specified for it.
      ),
      _MinistryScreen.profile => MinistryProfileScreen(
        onBack: () => setState(() => _current = _MinistryScreen.dashboard),
        // onLogOut isn't wired to a real auth/session flow yet — no such
        // system exists in this mock-data-only app.
      ),
    };
  }
}