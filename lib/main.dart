import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/municipal/screens/municipal_active_reports_screen.dart';
import 'features/municipal/screens/municipal_assign_team_screen.dart';
import 'features/municipal/screens/municipal_dashboard_screen.dart';
import 'features/municipal/screens/municipal_inbox_screen.dart';
import 'features/municipal/screens/municipal_profile_screen.dart';
import 'features/municipal/screens/municipal_report_progress_screen.dart';
import 'features/municipal/screens/municipal_report_review_screen.dart';
import 'features/municipal/screens/municipal_resolution_details_screen.dart';
import 'features/municipal/screens/municipal_resolved_reports_screen.dart';
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
enum _MunicipalScreen { dashboard, inbox, active, resolved }

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

  /// Report Review → Verification → Assign Team — the pre-triage
  /// Verify/Reject decision flow, only reachable from Inbox.
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

  /// Active Reports only ever lists reports already past triage (Assigned/
  /// In Progress/Resolved), so tapping one opens Report Progress (tracking
  /// + resolution) rather than Report Review (the pre-triage Verify/Reject
  /// decision, only reachable from Inbox).
  Route<void> _reportProgressRoute(String referenceId, ReportStatus status) {
    return MaterialPageRoute(
      builder: (context) => MunicipalReportProgressScreen(
        referenceId: referenceId,
        status: status,
        onBack: () => Navigator.of(context).pop(),
        // No share integration is specified yet (Issue 03 §7) — placeholder
        // pending spec, matching Dashboard's other unwired quick actions.
        onShareSummary: () {},
      ),
    );
  }

  /// Profile is a personal-account screen reachable from every tab (the
  /// header's profile avatar), not a report drill-down, so unlike the
  /// routes above it doesn't need a referenceId/status carried in from a
  /// list item.
  Route<void> _profileRoute() {
    return MaterialPageRoute(
      builder: (context) => MunicipalProfileScreen(
        onBack: () => Navigator.of(context).pop(),
        // Settings isn't in this module's scope, or specified anywhere in
        // the project yet — placeholder pending a future spec.
        onSettingsTap: () {},
        // No account/session workflow is specified yet (Issue 03 §7) —
        // placeholder pending spec, matching this screen's other unwired
        // actions.
        onLogOut: () {},
      ),
    );
  }

  Route<void> _resolutionDetailsRoute(String referenceId) {
    return MaterialPageRoute(
      builder: (context) => MunicipalResolutionDetailsScreen(
        referenceId: referenceId,
        onBack: () => Navigator.of(context).pop(),
        // No share/archive workflow is specified yet (Issue 03 §7) —
        // placeholder pending spec, matching Report Progress's Share
        // Summary and Dashboard's other unwired quick actions.
        onShareSummary: () {},
        onArchive: () {},
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
        onNavigateToResolvedReports: () =>
            setState(() => _current = _MunicipalScreen.resolved),
        onProfileTap: () => Navigator.of(context).push(_profileRoute()),
      ),
      _MunicipalScreen.inbox => MunicipalInboxScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MunicipalScreen.dashboard),
        onNavigateToActiveReports: () =>
            setState(() => _current = _MunicipalScreen.active),
        onNavigateToResolvedReports: () =>
            setState(() => _current = _MunicipalScreen.resolved),
        onProfileTap: () => Navigator.of(context).push(_profileRoute()),
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
        onNavigateToResolvedReports: () =>
            setState(() => _current = _MunicipalScreen.resolved),
        onProfileTap: () => Navigator.of(context).push(_profileRoute()),
        onReportTap: (report) => Navigator.of(
          context,
        ).push(_reportProgressRoute(report.referenceId, report.status)),
      ),
      _MunicipalScreen.resolved => MunicipalResolvedReportsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _MunicipalScreen.dashboard),
        onNavigateToInbox: () =>
            setState(() => _current = _MunicipalScreen.inbox),
        onNavigateToActiveReports: () =>
            setState(() => _current = _MunicipalScreen.active),
        onProfileTap: () => Navigator.of(context).push(_profileRoute()),
        onReportTap: (report) => Navigator.of(
          context,
        ).push(_resolutionDetailsRoute(report.referenceId)),
      ),
    };
  }
}
