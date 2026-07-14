import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_user_management_screen.dart';

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
      home: const _AdminRoot(),
    );
  }
}

/// Temporary root shell wiring the System Administrator screens built so
/// far — a placeholder until a proper named-route/navigator setup is worth
/// introducing (once more of the module's eight screens exist), matching
/// how the Municipal Officer and Ministry Supervisor modules' own roots
/// started.
enum _AdminScreen { dashboard, users }

class _AdminRoot extends StatefulWidget {
  const _AdminRoot();

  @override
  State<_AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<_AdminRoot> {
  _AdminScreen _current = _AdminScreen.dashboard;

  @override
  Widget build(BuildContext context) {
    return switch (_current) {
      _AdminScreen.dashboard => AdminDashboardScreen(
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        // Roles/Settings/System Activity/Profile aren't built yet (ADM-004,
        // ADM-007, ADM-006, ADM-008) — wire these up as each screen lands,
        // matching how the other modules' roots grew incrementally.
      ),
      _AdminScreen.users => AdminUserManagementScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        // onNavigateToRoles/onNavigateToSettings/onOpenUserDetails/
        // onOpenSystemActivity/onOpenProfile aren't built yet (ADM-004,
        // ADM-007, ADM-003, ADM-006, ADM-008).
      ),
    };
  }
}
