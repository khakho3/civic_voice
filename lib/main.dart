import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/municipal/screens/municipal_active_reports_screen.dart';
import 'features/municipal/screens/municipal_assign_team_screen.dart';
import 'features/municipal/screens/municipal_dashboard_screen.dart';
import 'features/municipal/screens/municipal_inbox_screen.dart';
import 'features/municipal/screens/municipal_report_review_screen.dart';
import 'features/municipal/screens/municipal_verification_screen.dart';
import 'models/report_status.dart';

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
enum _MunicipalScreen { dashboard, inbox, active }

class _MunicipalRoot extends StatefulWidget {
  const _MunicipalRoot();

  @override
  State<_MunicipalRoot> createState() => _MunicipalRootState();
}

class _MunicipalRootState extends State<_MunicipalRoot> {
  _MunicipalScreen _current = _MunicipalScreen.dashboard;

  /// Pops any pushed detail screens (Report Review, Verification, Assign
  /// Team) *and* switches to the Dashboard tab. Distinct from a plain
  /// `Navigator.pop()`: every "Return to Dashboard" / "Back to Dashboard"
  /// action needs both steps, not just the pop, or it lands back on
  /// whichever screen was one level up instead of the actual Dashboard.
  void _returnToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _current = _MunicipalScreen.dashboard);
  }

  /// Report Review → Verification → Assign Team is reachable from two
  /// places now (Inbox, for pending reports; Active Reports, for reports
  /// already past triage) — shared here rather than duplicated per caller.
  Route<void> _reportReviewRoute(String referenceId, ReportStatus status) {
    return MaterialPageRoute(
      builder: (context) => MunicipalReportReviewScreen(
        referenceId: referenceId,
        status: status,
        onBack: () => Navigator.of(context).pop(),
        onNavigateToDashboard: _returnToDashboard,
        onOpenVerification: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MunicipalVerificationScreen(
              referenceId: referenceId,
              status: status,
              onBack: () => Navigator.of(context).pop(),
              onNavigateToDashboard: _returnToDashboard,
              // Verification was pushed on top of Report Review, both on
              // top of whichever list screen (Inbox/Active Reports) started
              // this chain — popping to the first route lands back there.
              onBackToInbox: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              onAssignTeam: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MunicipalAssignTeamScreen(
                    referenceId: referenceId,
                    status: status,
                    onBack: () => Navigator.of(context).pop(),
                    onNavigateToDashboard: _returnToDashboard,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (_current) {
      _MunicipalScreen.dashboard => MunicipalDashboardScreen(
        onNavigateToInbox: () =>
            setState(() => _current = _MunicipalScreen.inbox),
        onNavigateToActiveReports: () =>
            setState(() => _current = _MunicipalScreen.active),
      ),
      _MunicipalScreen.inbox => MunicipalInboxScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MunicipalScreen.dashboard),
        onNavigateToActiveReports: () =>
            setState(() => _current = _MunicipalScreen.active),
        // Report Review is a drill-down detail screen, not a tab
        // destination, so it's pushed as a real route rather than switching
        // _current.
        onReportTap: (report) => Navigator.of(
          context,
        ).push(_reportReviewRoute(report.referenceId, report.status)),
      ),
      _MunicipalScreen.active => MunicipalActiveReportsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MunicipalScreen.dashboard),
        onNavigateToInbox: () =>
            setState(() => _current = _MunicipalScreen.inbox),
        onReportTap: (report) => Navigator.of(
          context,
        ).push(_reportReviewRoute(report.referenceId, report.status)),
      ),
    };
  }
}
