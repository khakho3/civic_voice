import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/municipal/screens/municipal_dashboard_screen.dart';
import 'features/municipal/screens/municipal_inbox_screen.dart';
import 'features/municipal/screens/municipal_report_review_screen.dart';

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
      home: const _MunicipalRoot(),
    );
  }
}

/// Temporary root shell wiring the Municipal Officer screens built so far —
/// a placeholder until a proper named-route/navigator setup is worth
/// introducing (once more of the module's 9 screens exist).
enum _MunicipalScreen { dashboard, inbox }

class _MunicipalRoot extends StatefulWidget {
  const _MunicipalRoot();

  @override
  State<_MunicipalRoot> createState() => _MunicipalRootState();
}

class _MunicipalRootState extends State<_MunicipalRoot> {
  _MunicipalScreen _current = _MunicipalScreen.dashboard;

  @override
  Widget build(BuildContext context) {
    return switch (_current) {
      _MunicipalScreen.dashboard => MunicipalDashboardScreen(
        onNavigateToInbox: () =>
            setState(() => _current = _MunicipalScreen.inbox),
      ),
      _MunicipalScreen.inbox => MunicipalInboxScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MunicipalScreen.dashboard),
        // Report Review is a drill-down detail screen, not a tab
        // destination, so it's pushed as a real route rather than switching
        // _current.
        onReportTap: (report) => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MunicipalReportReviewScreen(
              referenceId: report.referenceId,
              status: report.status,
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
    };
  }
}
