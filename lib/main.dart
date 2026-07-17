import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/models/admin_user_management_data.dart';
import 'features/admin/screens/admin_create_user_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_profile_screen.dart' as admin;
import 'features/admin/screens/admin_role_management_screen.dart';
import 'features/admin/screens/admin_system_activity_screen.dart';
import 'features/admin/screens/admin_system_settings_screen.dart';
import 'features/admin/screens/admin_user_details_screen.dart';
import 'features/admin/screens/admin_user_management_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/profile_screen.dart' as auth;
import 'features/authentication/screens/registration_screen.dart';
import 'features/authentication/screens/test_role_selector_screen.dart';
import 'features/authentication/screens/welcome_screen.dart';
import 'features/citizen/screens/citizen_alerts_screen.dart';
import 'features/citizen/screens/citizen_dashboard_screen.dart';
import 'features/citizen/screens/citizen_profile_screen.dart';
import 'features/citizen/screens/citizen_reports_screen.dart';
import 'features/citizen/screens/create_report_screen.dart';
import 'features/citizen/screens/location_picker_screen.dart';
import 'features/citizen/screens/photo_upload_screen.dart';
import 'features/citizen/screens/report_submitted_screen.dart';
import 'features/citizen/screens/report_tracking_screen.dart';
import 'features/citizen/screens/review_report_screen.dart';
import 'features/ministry/screens/ministry_analytics_screen.dart';
import 'features/ministry/screens/ministry_dashboard_screen.dart';
import 'features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'features/ministry/screens/ministry_profile_screen.dart' as ministry;
import 'features/ministry/screens/ministry_report_insights_screen.dart';
import 'features/ministry/screens/ministry_reports_screen.dart';
import 'features/maintenance/screens/assigned_tasks_screen.dart'
    as maintenance_tasks;
import 'features/maintenance/screens/dashboard_screen.dart'
    as maintenance_dashboard;
import 'features/maintenance/screens/profile_screen.dart'
    as maintenance_profile;
import 'features/maintenance/screens/task_completed_screen.dart'
    as maintenance_completed;
import 'features/maintenance/screens/task_details_screen.dart'
    as maintenance_details;
import 'features/maintenance/screens/update_progress_screen.dart'
    as maintenance_progress;
import 'features/maintenance/screens/upload_evidence_screen.dart'
    as maintenance_evidence;
import 'features/municipal/models/active_report.dart';
import 'features/municipal/models/incoming_report.dart';
import 'features/municipal/models/resolved_report.dart';
import 'features/municipal/screens/municipal_active_reports_screen.dart';
import 'features/municipal/screens/municipal_assign_team_screen.dart';
import 'features/municipal/screens/municipal_dashboard_screen.dart';
import 'features/municipal/screens/municipal_inbox_screen.dart';
import 'features/municipal/screens/municipal_profile_screen.dart' as municipal;
import 'features/municipal/screens/municipal_report_progress_screen.dart';
import 'features/municipal/screens/municipal_report_review_screen.dart';
import 'features/municipal/screens/municipal_resolution_details_screen.dart';
import 'features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'features/municipal/screens/municipal_verification_screen.dart';
import 'models/app_role.dart';
import 'services/mock_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.loadSavedTheme();
  await MockAuthService().initialize();
  runApp(const CivicVoiceApp());
}

/// Every route name in the app in one place — merges authentication's
/// original `AppRoutes` class with every citizen screen's own scattered
/// `static const routeName` statics, so there's a single registry instead
/// of two competing ones.
abstract final class AppRoutes {
  const AppRoutes._();

  // Authentication — the native splash hands off directly to onboarding.
  static const welcome = '/welcome';
  static const login = '/login';
  static const registration = '/registration';
  static const forgotPassword = '/forgot-password';
  static const profile = '/profile';
  static const testRoleSelector = '/test-role-selector';

  // Citizen.
  static const citizenDashboard = '/citizen/dashboard';
  static const citizenAlerts = '/citizen/alerts';
  static const citizenProfile = '/citizen/profile';
  static const citizenReports = '/citizen/reports';
  static const citizenCreateReport = '/citizen/create-report';
  static const citizenLocationPicker = '/citizen/location-picker';
  static const citizenPhotoUpload = '/citizen/photo-upload';
  static const citizenReportSubmitted = '/citizen/report-submitted';
  static const citizenReportTracking = '/citizen/report-tracking';
  static const citizenReviewReport = '/citizen/review-report';

  // Admin.
  static const adminDashboard = '/admin/dashboard';
  static const adminUserManagement = '/admin/user-management';
  static const adminUserDetails = '/admin/user-details';
  static const adminCreateUser = '/admin/create-user';
  static const adminRoleManagement = '/admin/role-management';
  static const adminSystemActivity = '/admin/system-activity';
  static const adminSystemSettings = '/admin/system-settings';
  static const adminProfile = '/admin/profile';

  // Ministry.
  static const ministryDashboard = '/ministry/dashboard';
  static const ministryReports = '/ministry/reports';
  static const ministryReportInsights = '/ministry/report-insights';
  static const ministryAnalytics = '/ministry/analytics';
  static const ministryMunicipalPerformance = '/ministry/municipal-performance';
  static const ministryProfile = '/ministry/profile';

  // Municipal.
  static const municipalDashboard = '/municipal/dashboard';
  static const municipalInbox = '/municipal/inbox';
  static const municipalActiveReports = '/municipal/active-reports';
  static const municipalReportReview = '/municipal/report-review';
  static const municipalAssignTeam = '/municipal/assign-team';
  static const municipalReportProgress = '/municipal/report-progress';
  static const municipalVerification = '/municipal/verification';
  static const municipalResolvedReports = '/municipal/resolved-reports';
  static const municipalResolutionDetails = '/municipal/resolution-details';
  static const municipalProfile = '/municipal/profile';

  // Maintenance.
  static const maintenanceDashboard = '/maintenance/dashboard';
  static const maintenanceAssignedTasks = '/maintenance/assigned-tasks';
  static const maintenanceTaskDetails = '/maintenance/task-details';
  static const maintenanceUpdateProgress = '/maintenance/update-progress';
  static const maintenanceUploadEvidence = '/maintenance/upload-evidence';
  static const maintenanceTaskCompleted = '/maintenance/task-completed';
  static const maintenanceProfile = '/maintenance/profile';
}

class CivicVoiceApp extends StatelessWidget {
  const CivicVoiceApp({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        final effectiveInitialRoute =
            initialRoute ??
            _routeForRole(MockAuthService().getCurrentRole()) ??
            AppRoutes.testRoleSelector;

        return MaterialApp(
          title: 'CivicVoice',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          themeAnimationDuration: AppMotionDuration.emphasized,
          themeAnimationCurve: AppMotionCurve.emphasized,
          initialRoute: effectiveInitialRoute,
          // NOTE: Admin/Ministry/Municipal/Maintenance routes are wired below
          // for testing via MockAuthService. Once Firebase auth is real,
          // MockAuthService and testRoleSelector will be deleted, and
          // onSignIn() will determine the user's role. The routing constants
          // and route table stay the same.
          routes: {
            AppRoutes.welcome: (context) => WelcomeScreen(
              onGetStarted: () =>
                  Navigator.of(context).pushNamed(AppRoutes.registration),
              onContinueAsGuest: () =>
                  Navigator.of(context).pushNamed(AppRoutes.citizenDashboard),
              onLogin: () =>
                  Navigator.of(context).pushNamed(AppRoutes.testRoleSelector),
            ),
            AppRoutes.testRoleSelector: (context) => TestRoleSelectorScreen(
              onRoleSelected: (role) {
                final routeName = _routeForRole(role)!;
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(routeName, (_) => false);
              },
              onSkip: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
            ),
            AppRoutes.login: (context) => LoginScreen(
              state: LoginViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onSignIn: () => Navigator.of(context).pushNamedAndRemoveUntil(
                _routeForRole(MockAuthService().getCurrentRole()) ??
                    AppRoutes.testRoleSelector,
                (_) => false,
              ),
              onForgotPassword: () =>
                  Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
              onRegister: () => Navigator.of(
                context,
              ).pushReplacementNamed(AppRoutes.registration),
            ),
            AppRoutes.registration: (context) => RegistrationScreen(
              state: RegistrationViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onCreateAccount: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.citizenDashboard,
                    (_) => false,
                  ),
              onLogin: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.login),
            ),
            AppRoutes.forgotPassword: (context) => ForgotPasswordScreen(
              state: ForgotPasswordViewState.ready,
              onBack: () => Navigator.of(context).maybePop(),
              onSendResetLink: (emailAddress) {
                // TODO(auth): Firebase password reset will be connected
                // later.
              },
              onBackToLogin: () => Navigator.of(context).maybePop(),
            ),
            AppRoutes.profile: (context) => auth.ProfileScreen(
              onLogout: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
            ),
            AppRoutes.citizenDashboard: (context) =>
                _withSwitchRoleButton(context, const CitizenDashboardScreen()),
            AppRoutes.citizenAlerts: (_) => const CitizenAlertsScreen(),
            AppRoutes.citizenProfile: (context) => CitizenProfileScreen(
              onLogOut: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
            ),
            AppRoutes.citizenReports: (_) => const CitizenReportsScreen(),
            AppRoutes.citizenCreateReport: (_) => const CreateReportScreen(),
            AppRoutes.citizenLocationPicker: (_) =>
                const LocationPickerScreen(),
            AppRoutes.citizenPhotoUpload: (_) => const PhotoUploadScreen(),
            AppRoutes.citizenReviewReport: (_) => const ReviewReportScreen(),
            AppRoutes.citizenReportSubmitted: (_) =>
                const ReportSubmittedScreen(),
            AppRoutes.citizenReportTracking: (context) =>
                _citizenReportTracking(ModalRoute.of(context)?.settings),
            AppRoutes.adminDashboard: _adminDashboard,
            AppRoutes.adminUserManagement: _adminUserManagement,
            AppRoutes.adminRoleManagement: _adminRoleManagement,
            AppRoutes.adminSystemActivity: _adminSystemActivity,
            AppRoutes.adminSystemSettings: _adminSystemSettings,
            AppRoutes.adminProfile: _adminProfile,
            AppRoutes.adminUserDetails: (context) => _adminUserDetails(
              context,
              _adminUserFromSettings(ModalRoute.of(context)?.settings),
            ),
            AppRoutes.adminCreateUser: _adminCreateUser,
            AppRoutes.ministryDashboard: _ministryDashboard,
            AppRoutes.ministryReports: _ministryReports,
            AppRoutes.ministryReportInsights: _ministryReportInsights,
            AppRoutes.ministryAnalytics: _ministryAnalytics,
            AppRoutes.ministryMunicipalPerformance:
                _ministryMunicipalPerformance,
            AppRoutes.ministryProfile: _ministryProfile,
            AppRoutes.municipalDashboard: _municipalDashboard,
            AppRoutes.municipalInbox: _municipalInbox,
            AppRoutes.municipalActiveReports: _municipalActiveReports,
            AppRoutes.municipalReportReview: (context) =>
                _municipalReportReview(
                  context,
                  _incomingReportFromSettings(ModalRoute.of(context)?.settings),
                ),
            AppRoutes.municipalAssignTeam: _municipalAssignTeam,
            AppRoutes.municipalReportProgress: (context) =>
                _municipalReportProgress(
                  context,
                  _activeReportFromSettings(ModalRoute.of(context)?.settings),
                ),
            AppRoutes.municipalVerification: (context) =>
                _municipalVerification(
                  context,
                  _incomingReportFromSettings(ModalRoute.of(context)?.settings),
                ),
            AppRoutes.municipalResolvedReports: _municipalResolvedReports,
            AppRoutes.municipalResolutionDetails: (context) =>
                _municipalResolutionDetails(
                  context,
                  _resolvedReportFromSettings(ModalRoute.of(context)?.settings),
                ),
            AppRoutes.municipalProfile: _municipalProfile,
            AppRoutes.maintenanceDashboard: _maintenanceDashboard,
            AppRoutes.maintenanceAssignedTasks: _maintenanceAssignedTasks,
            AppRoutes.maintenanceTaskDetails: _maintenanceTaskDetails,
            AppRoutes.maintenanceUpdateProgress: _maintenanceUpdateProgress,
            AppRoutes.maintenanceUploadEvidence: _maintenanceUploadEvidence,
            AppRoutes.maintenanceTaskCompleted: _maintenanceTaskCompleted,
            AppRoutes.maintenanceProfile: _maintenanceProfile,
          },
          onGenerateRoute: (settings) {
            final uri = Uri.tryParse(settings.name ?? '');
            if (uri?.path == AppRoutes.adminUserDetails) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _adminUserDetails(
                  context,
                  _adminUserFromSettings(settings),
                ),
              );
            }
            if (uri?.path == AppRoutes.citizenReportTracking) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _citizenReportTracking(settings),
              );
            }
            if (uri?.path == AppRoutes.municipalReportReview) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _municipalReportReview(
                  context,
                  _incomingReportFromSettings(settings),
                ),
              );
            }
            if (uri?.path == AppRoutes.municipalVerification) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _municipalVerification(
                  context,
                  _incomingReportFromSettings(settings),
                ),
              );
            }
            if (uri?.path == AppRoutes.municipalReportProgress) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _municipalReportProgress(
                  context,
                  _activeReportFromSettings(settings),
                ),
              );
            }
            if (uri?.path == AppRoutes.municipalResolutionDetails) {
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (context) => _municipalResolutionDetails(
                  context,
                  _resolvedReportFromSettings(settings),
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

void _replaceWith(BuildContext context, String routeName) {
  if (ModalRoute.of(context)?.settings.name == routeName) return;
  Navigator.of(context).pushReplacementNamed(routeName);
}

void _popOrReplaceWith(BuildContext context, String routeName) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.maybePop();
    return;
  }
  _replaceWith(context, routeName);
}

String? _routeForRole(AppRole? role) {
  return switch (role) {
    AppRole.systemAdministrator => AppRoutes.adminDashboard,
    AppRole.ministrySupervisor => AppRoutes.ministryDashboard,
    AppRole.municipalOfficer => AppRoutes.municipalDashboard,
    AppRole.citizen => AppRoutes.citizenDashboard,
    AppRole.maintenanceTeam => AppRoutes.maintenanceDashboard,
    null => null,
  };
}

Widget _withSwitchRoleButton(BuildContext context, Widget child) {
  if (MockAuthService().getCurrentRole() == null) return child;

  return Stack(
    children: [
      child,
      Positioned(
        right: AppSpacing.md,
        bottom: 96,
        child: SafeArea(
          child: FloatingActionButton.extended(
            heroTag: 'switch-test-role',
            onPressed: () => _switchTestRole(context),
            icon: const Icon(AppIcons.profile),
            label: const Text('Switch Role'),
          ),
        ),
      ),
    ],
  );
}

Future<void> _switchTestRole(BuildContext context) async {
  await MockAuthService().clearUser();
  if (!context.mounted) return;
  Navigator.of(
    context,
  ).pushNamedAndRemoveUntil(AppRoutes.testRoleSelector, (_) => false);
}

Widget _citizenReportTracking(RouteSettings? settings) {
  final argument = settings?.arguments;
  final reportId = argument is String
      ? argument
      : Uri.tryParse(settings?.name ?? '')?.queryParameters['reportId'] ?? '';

  return ReportTrackingScreen(reportId: reportId);
}

void _pushAdminUserDetails(BuildContext context, AdminUserItem user) {
  final route = Uri(
    path: AppRoutes.adminUserDetails,
    queryParameters: {'userId': user.userId},
  ).toString();
  Navigator.of(context).pushNamed(route, arguments: user);
}

AdminUserItem _adminUserFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is AdminUserItem) return argument;

  final users = mockAdminUsers();
  final uri = Uri.tryParse(settings?.name ?? '');
  final userId = uri?.queryParameters['userId'];
  if (userId != null) {
    for (final user in users) {
      if (user.userId == userId) return user;
    }
  }
  return users.first;
}

Widget _adminDashboard(BuildContext context) {
  return _withSwitchRoleButton(
    context,
    AdminDashboardScreen(
      onNavigateToUsers: () =>
          _replaceWith(context, AppRoutes.adminUserManagement),
      onNavigateToRoles: () =>
          _replaceWith(context, AppRoutes.adminRoleManagement),
      onNavigateToSettings: () =>
          _replaceWith(context, AppRoutes.adminSystemSettings),
      onViewSystemActivity: () =>
          Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
      onOpenProfile: () =>
          Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    ),
  );
}

Widget _adminUserManagement(BuildContext context) {
  return AdminUserManagementScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenUserDetails: (user) => _pushAdminUserDetails(context, user),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onCreateUser: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminCreateUser),
  );
}

Widget _adminCreateUser(BuildContext context) {
  return AdminCreateUserScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
  );
}

Widget _adminUserDetails(BuildContext context, AdminUserItem user) {
  return AdminUserDetailsScreen(
    user: user,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
  );
}

Widget _adminRoleManagement(BuildContext context) {
  return AdminRoleManagementScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
  );
}

Widget _adminSystemActivity(BuildContext context) {
  return AdminSystemActivityScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
  );
}

Widget _adminSystemSettings(BuildContext context) {
  return AdminSystemSettingsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
  );
}

Widget _adminProfile(BuildContext context) {
  return admin.AdminProfileScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        _replaceWith(context, AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenSystemActivity: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminSystemActivity),
    onSignOut: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
  );
}

Widget _ministryDashboard(BuildContext context) {
  return _withSwitchRoleButton(
    context,
    MinistryDashboardScreen(
      onNavigateToAnalytics: () =>
          _replaceWith(context, AppRoutes.ministryAnalytics),
      onNavigateToMunicipalities: () =>
          _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
      onNavigateToReports: () =>
          _replaceWith(context, AppRoutes.ministryReports),
      onProfileTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
    ),
  );
}

Widget _ministryAnalytics(BuildContext context) {
  return MinistryAnalyticsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.ministryDashboard),
    onNavigateToMunicipalities: () =>
        _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
    onNavigateToReports: () => _replaceWith(context, AppRoutes.ministryReports),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
    onViewReportInsights: () =>
        Navigator.of(context).pushNamed(AppRoutes.ministryReportInsights),
  );
}

Widget _ministryMunicipalPerformance(BuildContext context) {
  return MinistryMunicipalPerformanceScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.ministryDashboard),
    onNavigateToAnalytics: () =>
        _replaceWith(context, AppRoutes.ministryAnalytics),
    onNavigateToReports: () => _replaceWith(context, AppRoutes.ministryReports),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
  );
}

Widget _ministryReports(BuildContext context) {
  return MinistryReportsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.ministryDashboard),
    onNavigateToAnalytics: () =>
        _replaceWith(context, AppRoutes.ministryAnalytics),
    onNavigateToMunicipalities: () =>
        _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
    onViewReportInsights: () =>
        Navigator.of(context).pushNamed(AppRoutes.ministryReportInsights),
  );
}

Widget _ministryReportInsights(BuildContext context) {
  return MinistryReportInsightsScreen(
    onBack: () => _popOrReplaceWith(context, AppRoutes.ministryDashboard),
  );
}

Widget _ministryProfile(BuildContext context) {
  return ministry.MinistryProfileScreen(
    onBack: () => _popOrReplaceWith(context, AppRoutes.ministryDashboard),
    onLogOut: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
  );
}

String _reportRoute(String path, String reportId) {
  return Uri(path: path, queryParameters: {'reportId': reportId}).toString();
}

void _pushMunicipalReportReview(
  BuildContext context,
  IncomingReportItem report,
) {
  Navigator.of(context).pushNamed(
    _reportRoute(AppRoutes.municipalReportReview, report.referenceId),
    arguments: report,
  );
}

void _pushMunicipalVerification(
  BuildContext context,
  IncomingReportItem report,
) {
  Navigator.of(context).pushNamed(
    _reportRoute(AppRoutes.municipalVerification, report.referenceId),
    arguments: report,
  );
}

void _pushMunicipalReportProgress(
  BuildContext context,
  ActiveReportItem report,
) {
  Navigator.of(context).pushNamed(
    _reportRoute(AppRoutes.municipalReportProgress, report.referenceId),
    arguments: report,
  );
}

void _pushMunicipalResolutionDetails(
  BuildContext context,
  ResolvedReportItem report,
) {
  Navigator.of(context).pushNamed(
    _reportRoute(AppRoutes.municipalResolutionDetails, report.referenceId),
    arguments: report,
  );
}

IncomingReportItem _incomingReportFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is IncomingReportItem) return argument;

  final reports = IncomingReportItem.mock();
  final uri = Uri.tryParse(settings?.name ?? '');
  final reportId = uri?.queryParameters['reportId'];
  if (reportId != null) {
    for (final report in reports) {
      if (report.referenceId == reportId) return report;
    }
  }
  return reports.first;
}

ActiveReportItem _activeReportFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is ActiveReportItem) return argument;

  final reports = ActiveReportItem.mock();
  final uri = Uri.tryParse(settings?.name ?? '');
  final reportId = uri?.queryParameters['reportId'];
  if (reportId != null) {
    for (final report in reports) {
      if (report.referenceId == reportId) return report;
    }
  }
  return reports.first;
}

ResolvedReportItem _resolvedReportFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is ResolvedReportItem) return argument;

  final reports = ResolvedReportItem.mock();
  final uri = Uri.tryParse(settings?.name ?? '');
  final reportId = uri?.queryParameters['reportId'];
  if (reportId != null) {
    for (final report in reports) {
      if (report.referenceId == reportId) return report;
    }
  }
  return reports.first;
}

Widget _municipalDashboard(BuildContext context) {
  return _withSwitchRoleButton(
    context,
    MunicipalDashboardScreen(
      onNavigateToInbox: () => _replaceWith(context, AppRoutes.municipalInbox),
      onNavigateToActiveReports: () =>
          _replaceWith(context, AppRoutes.municipalActiveReports),
      onNavigateToResolvedReports: () =>
          _replaceWith(context, AppRoutes.municipalResolvedReports),
      onProfileTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.municipalProfile),
    ),
  );
}

Widget _municipalInbox(BuildContext context) {
  return MunicipalInboxScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
    onNavigateToActiveReports: () =>
        _replaceWith(context, AppRoutes.municipalActiveReports),
    onNavigateToResolvedReports: () =>
        _replaceWith(context, AppRoutes.municipalResolvedReports),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalProfile),
    onReportTap: (report) => _pushMunicipalReportReview(context, report),
  );
}

Widget _municipalActiveReports(BuildContext context) {
  return MunicipalActiveReportsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
    onNavigateToInbox: () => _replaceWith(context, AppRoutes.municipalInbox),
    onNavigateToResolvedReports: () =>
        _replaceWith(context, AppRoutes.municipalResolvedReports),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalProfile),
    onReportTap: (report) => _pushMunicipalReportProgress(context, report),
  );
}

Widget _municipalResolvedReports(BuildContext context) {
  return MunicipalResolvedReportsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
    onNavigateToInbox: () => _replaceWith(context, AppRoutes.municipalInbox),
    onNavigateToActiveReports: () =>
        _replaceWith(context, AppRoutes.municipalActiveReports),
    onProfileTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalProfile),
    onReportTap: (report) => _pushMunicipalResolutionDetails(context, report),
  );
}

Widget _municipalReportReview(BuildContext context, IncomingReportItem report) {
  return MunicipalReportReviewScreen(
    referenceId: report.referenceId,
    status: report.status,
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalInbox),
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
    onOpenVerification: () => _pushMunicipalVerification(context, report),
  );
}

Widget _municipalVerification(BuildContext context, IncomingReportItem report) {
  return MunicipalVerificationScreen(
    referenceId: report.referenceId,
    status: report.status,
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalReportReview),
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
    onBackToInbox: () => _replaceWith(context, AppRoutes.municipalInbox),
    onAssignTeam: () => Navigator.of(context).pushNamed(
      _reportRoute(AppRoutes.municipalAssignTeam, report.referenceId),
      arguments: report,
    ),
  );
}

Widget _municipalAssignTeam(BuildContext context) {
  return MunicipalAssignTeamScreen(
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalVerification),
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
  );
}

Widget _municipalReportProgress(BuildContext context, ActiveReportItem report) {
  return MunicipalReportProgressScreen(
    referenceId: report.referenceId,
    status: report.status,
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalActiveReports),
  );
}

Widget _municipalResolutionDetails(
  BuildContext context,
  ResolvedReportItem report,
) {
  return MunicipalResolutionDetailsScreen(
    referenceId: report.referenceId,
    onBack: () =>
        _popOrReplaceWith(context, AppRoutes.municipalResolvedReports),
  );
}

Widget _municipalProfile(BuildContext context) {
  return municipal.MunicipalProfileScreen(
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalDashboard),
    onLogOut: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
  );
}

Widget _maintenanceDashboard(BuildContext context) {
  return _withSwitchRoleButton(
    context,
    maintenance_dashboard.DashboardScreen(
      onNavigateToTasks: () =>
          _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
      onNavigateToProfile: () =>
          Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
      onOpenTaskDetails: () =>
          Navigator.of(context).pushNamed(AppRoutes.maintenanceTaskDetails),
    ),
  );
}

Widget _maintenanceAssignedTasks(BuildContext context) {
  return maintenance_tasks.AssignedTasksScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
    onOpenTaskDetails: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceTaskDetails),
  );
}

Widget _maintenanceTaskDetails(BuildContext context) {
  return maintenance_details.TaskDetailsScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToTasks: () =>
        _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
    onUpdateProgress: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceUpdateProgress),
  );
}

Widget _maintenanceUpdateProgress(BuildContext context) {
  return maintenance_progress.UpdateProgressScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToTasks: () =>
        _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
    onOpenEvidence: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceUploadEvidence),
  );
}

Widget _maintenanceUploadEvidence(BuildContext context) {
  return maintenance_evidence.UploadEvidenceScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToTasks: () =>
        _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
    onTaskCompleted: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceTaskCompleted),
  );
}

Widget _maintenanceTaskCompleted(BuildContext context) {
  return maintenance_completed.TaskCompletedScreen(
    onNavigateToDashboard: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.maintenanceDashboard, (_) => false),
    onNavigateToTasks: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.maintenanceAssignedTasks, (_) => false),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
  );
}

Widget _maintenanceProfile(BuildContext context) {
  return maintenance_profile.ProfileScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToTasks: () =>
        _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
  );
}
