import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/admin/models/admin_user_management_data.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_role_management_screen.dart';
import 'features/admin/screens/admin_system_activity_screen.dart';
import 'features/admin/screens/admin_system_settings_screen.dart';
import 'features/admin/screens/admin_user_details_screen.dart';
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
enum _AdminScreen {
  dashboard,
  users,
  roles,
  userDetails,
  systemActivity,
  settings,
}

class _AdminRoot extends StatefulWidget {
  const _AdminRoot();

  @override
  State<_AdminRoot> createState() => _AdminRootState();
}

class _AdminRootState extends State<_AdminRoot> {
  _AdminScreen _current = _AdminScreen.dashboard;

  /// Set by [AdminUserManagementScreen.onOpenUserDetails] right before
  /// switching to [_AdminScreen.userDetails] — this temporary root shell
  /// has no real navigator/route args, so the drill-down target rides
  /// along in state instead.
  AdminUserItem? _selectedUser;

  @override
  Widget build(BuildContext context) {
    return switch (_current) {
      _AdminScreen.dashboard => AdminDashboardScreen(
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        onNavigateToRoles: () => setState(() => _current = _AdminScreen.roles),
        onNavigateToSettings: () =>
            setState(() => _current = _AdminScreen.settings),
        onViewSystemActivity: () =>
            setState(() => _current = _AdminScreen.systemActivity),
        // Profile isn't built yet (ADM-008) — wire it up once it lands,
        // matching how the other modules' roots grew incrementally.
      ),
      _AdminScreen.users => AdminUserManagementScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        onNavigateToRoles: () => setState(() => _current = _AdminScreen.roles),
        onOpenUserDetails: (user) => setState(() {
          _selectedUser = user;
          _current = _AdminScreen.userDetails;
        }),
        onOpenSystemActivity: () =>
            setState(() => _current = _AdminScreen.systemActivity),
        onNavigateToSettings: () =>
            setState(() => _current = _AdminScreen.settings),
        // onOpenProfile isn't built yet (ADM-008).
      ),
      _AdminScreen.roles => AdminRoleManagementScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        onOpenSystemActivity: () =>
            setState(() => _current = _AdminScreen.systemActivity),
        onNavigateToSettings: () =>
            setState(() => _current = _AdminScreen.settings),
        // onOpenProfile isn't built yet (ADM-008).
      ),
      _AdminScreen.userDetails => AdminUserDetailsScreen(
        user: _selectedUser!,
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        onNavigateToRoles: () => setState(() => _current = _AdminScreen.roles),
        onOpenSystemActivity: () =>
            setState(() => _current = _AdminScreen.systemActivity),
        onNavigateToSettings: () =>
            setState(() => _current = _AdminScreen.settings),
        // onOpenProfile isn't built yet (ADM-008).
      ),
      _AdminScreen.systemActivity => AdminSystemActivityScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        onNavigateToRoles: () => setState(() => _current = _AdminScreen.roles),
        onNavigateToSettings: () =>
            setState(() => _current = _AdminScreen.settings),
        // onOpenProfile isn't built yet (ADM-008).
      ),
      _AdminScreen.settings => AdminSystemSettingsScreen(
        onNavigateToDashboard: () =>
            setState(() => _current = _AdminScreen.dashboard),
        onNavigateToUsers: () => setState(() => _current = _AdminScreen.users),
        onNavigateToRoles: () => setState(() => _current = _AdminScreen.roles),
        onOpenSystemActivity: () =>
            setState(() => _current = _AdminScreen.systemActivity),
        // onOpenProfile isn't built yet (ADM-008).
      ),
    };
  }
}
