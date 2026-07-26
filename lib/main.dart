import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'core/navigation/tab_route.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/admin/models/admin_user_management_data.dart';
import 'features/admin/models/admin_role_management_data.dart';
import 'features/admin/models/admin_profile_data.dart';
import 'features/admin/models/admin_maintenance_team_data.dart';
import 'features/admin/screens/admin_create_user_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/admin_maintenance_teams_screen.dart';
import 'features/admin/screens/admin_profile_screen.dart' as admin;
import 'features/admin/screens/admin_role_management_screen.dart';
import 'features/admin/screens/admin_system_activity_screen.dart';
import 'features/admin/screens/admin_notifications_screen.dart';
import 'features/admin/screens/admin_system_settings_screen.dart';
import 'features/admin/screens/admin_user_details_screen.dart';
import 'features/admin/screens/admin_user_management_screen.dart';
import 'features/admin/services/admin_maintenance_team_directory.dart';
import 'features/admin/services/admin_session.dart';
import 'features/admin/services/admin_user_directory.dart';
import 'features/admin/services/admin_system_activity_directory.dart';
import 'features/admin/services/admin_system_settings_directory.dart';
import 'features/authentication/screens/about_screen.dart';
import 'features/authentication/screens/change_password_screen.dart';
import 'features/authentication/screens/bio_lock_screen.dart';
import 'features/authentication/screens/forgot_password_screen.dart';
import 'features/authentication/screens/login_screen.dart';
import 'features/authentication/screens/otp_verification_screen.dart';
import 'features/authentication/screens/registration_screen.dart';
import 'features/authentication/screens/set_new_password_screen.dart';
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
import 'features/citizen/services/report_crud_service.dart';
import 'features/citizen/services/profile_crud_service.dart';
import 'features/citizen/services/notification_permission_service.dart';
import 'features/ministry/models/municipal_performance_data.dart';
import 'features/ministry/screens/ministry_analytics_screen.dart';
import 'features/ministry/screens/ministry_dashboard_screen.dart';
import 'features/ministry/screens/ministry_municipal_performance_screen.dart';
import 'features/ministry/screens/ministry_municipality_detail_screen.dart';
import 'features/ministry/screens/ministry_profile_screen.dart' as ministry;
import 'features/ministry/screens/ministry_notifications_screen.dart';
import 'features/ministry/screens/ministry_report_insights_screen.dart';
import 'features/ministry/screens/ministry_reports_screen.dart';
import 'features/ministry/services/ministry_data_directory.dart';
import 'features/ministry/services/ministry_session.dart';
import 'features/maintenance/models/maintenance_task.dart';
import 'features/maintenance/screens/assigned_tasks_screen.dart'
    as maintenance_tasks;
import 'features/maintenance/screens/dashboard_screen.dart'
    as maintenance_dashboard;
import 'features/maintenance/screens/maintenance_notifications_screen.dart';
import 'features/maintenance/screens/profile_screen.dart'
    as maintenance_profile;
import 'features/maintenance/screens/task_completed_screen.dart'
    as maintenance_completed;
import 'features/maintenance/screens/task_details_screen.dart'
    as maintenance_details;
import 'features/maintenance/screens/update_progress_screen.dart'
    as maintenance_progress;
import 'features/maintenance/services/maintenance_task_directory.dart';
import 'features/maintenance/services/maintenance_session.dart';
import 'features/municipal/models/incoming_report.dart';
import 'features/municipal/models/resolved_report.dart';
import 'features/municipal/services/municipal_report_directory.dart';
import 'features/municipal/services/municipal_session.dart';
import 'features/municipal/screens/municipal_active_reports_screen.dart';
import 'features/municipal/screens/municipal_assign_team_screen.dart';
import 'features/municipal/screens/municipal_dashboard_screen.dart';
import 'features/municipal/screens/municipal_inbox_screen.dart';
import 'features/municipal/screens/municipal_profile_screen.dart' as municipal;
import 'features/municipal/screens/municipal_report_progress_screen.dart';
import 'features/municipal/screens/municipal_report_review_screen.dart';
import 'features/municipal/screens/municipal_resolution_details_screen.dart';
import 'features/municipal/screens/municipal_notifications_screen.dart';
import 'features/municipal/screens/municipal_resolved_reports_screen.dart';
import 'features/municipal/screens/municipal_verification_screen.dart';
import 'firebase_options.dart';
import 'models/app_role.dart';
import 'models/report_status.dart';
import 'models/assembly.dart';
import 'models/ghana_assemblies_data.dart';
import 'models/region.dart';
import 'services/api_client.dart';
import 'services/app_cache_service.dart';
import 'services/idle_session_timer.dart';
import 'services/mock_auth_service.dart';
import 'services/session_actions.dart';
import 'services/notification_directory.dart';
import 'widgets/glass_dialog_backdrop.dart';
import 'widgets/in_app_notification_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await ThemeController.loadSavedTheme();
  await AppCacheService.instance.initialize();
  await MockAuthService().initialize();
  await NotificationDirectory.instance.initialize();
  await _restorePersistedSession();
  if (MockAuthService().getCurrentRole() != null &&
      !AppCacheService.instance.onboardingComplete) {
    await AppCacheService.instance.markOnboardingComplete();
  }
  await _configurePushNotifications();
  runApp(const CivicVoiceApp());
}

bool _pushListenersConfigured = false;

/// Global by design, not scoped to [_CivicVoiceAppState] — there is only
/// ever one [CivicVoiceApp] in the whole process, and top-level code that
/// lives outside any screen's widget tree (the `onMessage` push handler
/// below, which can fire while any screen is on top) needs a [BuildContext]
/// of its own to show an in-app banner or navigate.
final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> _configurePushNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  try {
    final messaging = FirebaseMessaging.instance;
    final token = await messaging.getToken();
    final idToken = await user.getIdToken();
    if (token != null && idToken != null) {
      await ApiClient.instance.registerPushToken(
        idToken: idToken,
        token: token,
        platform: 'android',
      );
    }
    if (_pushListenersConfigured) return;
    _pushListenersConfigured = true;
    FirebaseMessaging.onMessage.listen((message) async {
      try {
        switch (message.data['type']) {
          case 'report-status':
            await ReportCrudService.instance.refresh();
          case 'municipal-report':
          case 'municipal-report-status':
          case 'ministry-resolution':
            await MunicipalReportDirectory.instance.refresh();
          case 'maintenance-task':
          case 'maintenance-task-status':
            await MaintenanceTaskDirectory.instance.refresh();
        }
      } catch (_) {}
      _showInAppBannerFor(message);
    });
    messaging.onTokenRefresh.listen((token) async {
      final refreshedIdToken = await FirebaseAuth.instance.currentUser
          ?.getIdToken();
      if (refreshedIdToken != null) {
        await ApiClient.instance.registerPushToken(
          idToken: refreshedIdToken,
          token: token,
          platform: 'android',
        );
      }
    });
  } catch (_) {
    // Notifications never block sign-in or application startup.
  }
}

/// The in-app counterpart to a push notification arriving while the app is
/// already open — `FirebaseMessaging.onMessage` only fires in that case (a
/// backgrounded/closed app shows the OS's own notification instead), and
/// without this the refreshed data above was the only visible effect: the
/// screen would quietly update with nothing telling the user why.
void _showInAppBannerFor(RemoteMessage message) {
  final overlay = _navigatorKey.currentState?.overlay;
  if (overlay == null) return;
  final title = message.notification?.title;
  final body = message.notification?.body ?? '';
  if (title == null) return;
  final type = message.data['type'];
  InAppNotificationBanner.show(
    overlay,
    title: title,
    message: body,
    icon: _iconForPushType(type),
    color: _colorForPushType(type),
    onTap: () {
      final route = _notificationsRouteForRole(
        MockAuthService().getCurrentRole(),
      );
      if (route != null) _navigatorKey.currentState?.pushNamed(route);
    },
  );
}

IconData _iconForPushType(String? type) => switch (type) {
  'report-status' => AppIcons.statusInProgress,
  'municipal-report' => AppIcons.inbox,
  'municipal-report-status' => AppIcons.statusInProgress,
  'ministry-resolution' => AppIcons.statusResolved,
  'maintenance-task' || 'maintenance-task-status' => AppIcons.statusAssigned,
  'maintenance-team-membership' => AppIcons.profile,
  _ => AppIcons.notifications,
};

Color _colorForPushType(String? type) => switch (type) {
  'ministry-resolution' => ReportStatus.resolved.color,
  'municipal-report' => AppColors.primary,
  _ => AppColors.primary,
};

String? _notificationsRouteForRole(AppRole? role) => switch (role) {
  AppRole.citizen => AppRoutes.citizenAlerts,
  AppRole.municipalOfficer => AppRoutes.municipalNotifications,
  AppRole.maintenanceTeam => AppRoutes.maintenanceNotifications,
  AppRole.ministrySupervisor => AppRoutes.ministryNotifications,
  AppRole.systemAdministrator => AppRoutes.adminNotifications,
  null => null,
};

Future<void> _offerNotificationPermissionAfterLogin(
  BuildContext context,
) async {
  final service = const NotificationPermissionService();
  try {
    if (await service.hasAskedBefore()) return;
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final allow = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => GlassDialogBackdrop(
      child: AlertDialog(
        icon: const Icon(AppIcons.notifications, color: AppColors.primary),
        title: const Text('Stay Updated'),
        content: const Text(
          'Allow notifications so CivicVoice can alert you about new tasks, '
          'report decisions, and status changes even when the app is closed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ),
  );
  if (allow == true) {
    try {
      await service.requestOnce();
    } catch (_) {
      // Permission plugins must never turn a valid sign-in into an error.
    }
  } else {
    await service.markAsked();
  }
}

Future<void> _restorePersistedSession() async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  final auth = MockAuthService();
  if (firebaseUser == null) {
    if (auth.getCurrentRole() != null) await auth.clearUser();
    return;
  }

  try {
    final token = await firebaseUser.getIdToken();
    if (token == null) return;
    final syncedUser = await ApiClient.instance.syncUser(idToken: token);
    final role = _appRoleForBackendRole(syncedUser.role);
    if (role == null) return;
    await _selectSyncedRole(auth, role, syncedUser);
    if (role == AppRole.citizen) {
      ProfileCrudService.instance.loadSignedInUser(syncedUser);
      await ReportCrudService.instance.refresh();
    } else if (role == AppRole.municipalOfficer) {
      await MunicipalReportDirectory.instance.refresh();
      await MaintenanceTeamDirectory.instance.refreshForMunicipal();
    } else if (role == AppRole.maintenanceTeam) {
      await MaintenanceTaskDirectory.instance.refresh();
    } else if (role == AppRole.ministrySupervisor) {
      await MinistryDataDirectory.instance.refresh();
    } else if (role == AppRole.systemAdministrator) {
      AdminUserDirectory.instance.currentApiUserId = syncedUser.id;
      await AdminUserDirectory.instance.refresh();
      await MaintenanceTeamDirectory.instance.refreshForAdmin();
      await AdminSystemActivityDirectory.instance.refresh();
      await AdminSystemSettingsDirectory.instance.refresh();
    }
  } catch (_) {
    // Firebase keeps the credential. Preserve the last known role so a
    // temporary backend outage does not silently log the user out.
  }
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
  static const biometricLock = '/biometric-lock';
  static const about = '/about';

  /// Shared across every already-authenticated role's Profile screen —
  /// see [ChangePasswordScreen]'s own doc comment for why this is a
  /// single cross-module destination rather than one per module.
  static const changePassword = '/change-password';
  static const forcePasswordReset = '/force-password-reset';
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
  static const adminMaintenanceTeams = '/admin/maintenance-teams';
  static const adminMaintenanceTeamDetails = '/admin/maintenance-team-details';
  static const adminMaintenanceTeamForm = '/admin/maintenance-team-form';
  static const adminRoleManagement = '/admin/role-management';
  static const adminSystemActivity = '/admin/system-activity';
  static const adminNotifications = '/admin/notifications';
  static const adminSystemSettings = '/admin/system-settings';
  static const adminProfile = '/admin/profile';

  // Ministry.
  static const ministryDashboard = '/ministry/dashboard';
  static const ministryReports = '/ministry/reports';
  static const ministryReportInsights = '/ministry/report-insights';
  static const ministryAnalytics = '/ministry/analytics';
  static const ministryMunicipalPerformance = '/ministry/municipal-performance';
  static const ministryMunicipalityDetail = '/ministry/municipality-detail';
  static const ministryProfile = '/ministry/profile';
  static const ministryNotifications = '/ministry/notifications';

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
  static const municipalNotifications = '/municipal/notifications';

  // Maintenance.
  static const maintenanceDashboard = '/maintenance/dashboard';
  static const maintenanceAssignedTasks = '/maintenance/assigned-tasks';
  static const maintenanceTaskDetails = '/maintenance/task-details';
  static const maintenanceUpdateProgress = '/maintenance/update-progress';
  static const maintenanceTaskCompleted = '/maintenance/task-completed';
  static const maintenanceProfile = '/maintenance/profile';
  static const maintenanceNotifications = '/maintenance/notifications';
}

class CivicVoiceApp extends StatefulWidget {
  const CivicVoiceApp({super.key, this.initialRoute});

  final String? initialRoute;

  @override
  State<CivicVoiceApp> createState() => _CivicVoiceAppState();
}

class _CivicVoiceAppState extends State<CivicVoiceApp>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;
  bool _biometricLockShowing = false;
  static const _reLockThreshold = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    IdleSessionTimer.instance.onExpire = _handleIdleTimeout;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForNotificationPermission();
    });
  }

  Future<void> _promptForNotificationPermission() async {
    // Citizen's dashboard may be presenting the required location flow on
    // its first frame. New sign-ins are prompted before routing, and the
    // Alerts page always exposes the OS state, so avoid stacked dialogs on
    // a restored citizen session.
    if (MockAuthService().getCurrentRole() == AppRole.citizen) return;
    final service = const NotificationPermissionService();
    try {
      if (FirebaseAuth.instance.currentUser == null ||
          await service.hasAskedBefore()) {
        return;
      }
      final status = await service.currentStatus();
      if (status.isGranted) {
        await service.markAsked();
        await _configurePushNotifications();
        return;
      }
    } catch (_) {
      return;
    }
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final allow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GlassDialogBackdrop(
        child: AlertDialog(
          icon: const Icon(AppIcons.notifications, color: AppColors.primary),
          title: const Text('Stay Updated'),
          content: const Text(
            'Allow notifications so CivicVoice can alert you about new tasks, '
            'report decisions, and status changes even when the app is closed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not Now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      ),
    );
    if (allow == true) {
      try {
        await service.requestOnce();
        await _configurePushNotifications();
      } catch (_) {
        // Permission/plugins are optional; the notification page exposes a
        // retry/settings action without blocking the signed-in session.
      }
    } else {
      await service.markAsked();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    IdleSessionTimer.instance.onExpire = null;
    IdleSessionTimer.instance.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (backgroundedAt == null) return;
    if (DateTime.now().difference(backgroundedAt) < _reLockThreshold) return;
    _presentBiometricLockIfDue();
  }

  void _presentBiometricLockIfDue() {
    if (_biometricLockShowing) return;
    if (MockAuthService().getCurrentRole() == null) return;
    if (!AppCacheService.instance.biometricLockEnabled) return;
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return;
    _biometricLockShowing = true;
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.biometricLock),
        builder: (context) => BioLockScreen(
          onAuthenticated: () {
            _biometricLockShowing = false;
            Navigator.of(context).pop();
          },
          onLogOut: () {
            _biometricLockShowing = false;
            signOut(context);
          },
        ),
      ),
    );
  }

  /// Fires when [IdleSessionTimer] expires with no activity — real
  /// app-wide session timeout, driven by ADM-007's Session Timeout
  /// setting. A no-op if nobody's actually signed in (Welcome/onboarding,
  /// or already signed out) — there's no session to time out of.
  void _handleIdleTimeout() {
    if (MockAuthService().getCurrentRole() == null) return;
    FirebaseAuth.instance.signOut();
    MockAuthService().clearUser();
    // Straight to Login, not the onboarding carousel — this device has
    // been used before, so re-showing onboarding (and letting them scroll
    // back through slides they've already seen) is exactly the confusing
    // dead end this used to be.
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        // A cold start with no active role isn't necessarily a fresh
        // device — it's just as often someone reopening the app after an
        // earlier sign-out/timeout. onboardingComplete is what actually
        // distinguishes "never seen this app before" (show the full
        // onboarding carousel) from "has an account, just needs to sign
        // back in" (go straight to Login).
        final signedInRoute = _routeForRole(MockAuthService().getCurrentRole());
        final effectiveInitialRoute =
            widget.initialRoute ??
            (signedInRoute != null &&
                    AppCacheService.instance.biometricLockEnabled
                ? AppRoutes.biometricLock
                : signedInRoute) ??
            (AppCacheService.instance.onboardingComplete
                ? AppRoutes.login
                : AppRoutes.welcome);

        return Listener(
          onPointerDown: (_) => IdleSessionTimer.instance.registerActivity(),
          child: MaterialApp(
            navigatorKey: _navigatorKey,
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
              // Only ever reached when onboardingComplete is still false
              // (see effectiveInitialRoute above, and _signOut/
              // _handleIdleTimeout below) — a device that's already
              // finished onboarding once never lands here again, so this
              // always starts at the first slide now.
              AppRoutes.welcome: (context) => WelcomeScreen(
                onOnboardingCompleted: () => unawaited(
                  AppCacheService.instance.markOnboardingComplete(),
                ),
                onGetStarted: () =>
                    Navigator.of(context).pushNamed(AppRoutes.registration),
                onContinueAsGuest: () => _continueAsGuest(context),
                onLogin: () => Navigator.of(context).pushNamed(AppRoutes.login),
              ),
              AppRoutes.testRoleSelector: (context) => TestRoleSelectorScreen(
                // MockAuthService().selectRole(...) already ran by the time
                // this fires (TestRoleSelectorScreen._continue awaits it
                // first) — reusing _completeSignIn's routing means the
                // "Simulate first login" checkbox actually gets honored here
                // too, not just on the real LoginScreen's onSignIn.
                onRoleSelected: (role) => _completeSignIn(context),
                onSkip: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.welcome, (_) => false),
              ),
              AppRoutes.login: (context) => const _LoginRoute(),
              AppRoutes.registration: (context) => const _RegistrationRoute(),
              AppRoutes.forgotPassword: (context) =>
                  const _ForgotPasswordRoute(),
              AppRoutes.biometricLock: _biometricLock,
              AppRoutes.changePassword: (context) => ChangePasswordScreen(
                onBack: Navigator.canPop(context)
                    ? () => Navigator.of(context).maybePop()
                    : null,
                onSaved: () => _finishChangePassword(context),
              ),
              AppRoutes.about: (context) => AboutScreen(
                onBack: Navigator.canPop(context)
                    ? () => Navigator.of(context).maybePop()
                    : null,
              ),
              AppRoutes.forcePasswordReset: _forcedPasswordReset,
              AppRoutes.citizenDashboard: (context) =>
                  const CitizenDashboardScreen(),
              AppRoutes.citizenAlerts: (_) => const CitizenAlertsScreen(),
              AppRoutes.citizenProfile: (context) => CitizenProfileScreen(
                onAbout: () => Navigator.of(context).pushNamed(AppRoutes.about),
                onRegister: () =>
                    Navigator.of(context).pushNamed(AppRoutes.registration),
                onLogOut: () => signOut(context),
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
              AppRoutes.adminNotifications: _adminNotifications,
              AppRoutes.adminSystemSettings: _adminSystemSettings,
              AppRoutes.adminProfile: _adminProfile,
              AppRoutes.adminUserDetails: (context) => _adminUserDetails(
                context,
                _adminUserFromSettings(ModalRoute.of(context)?.settings),
              ),
              AppRoutes.adminCreateUser: _adminCreateUser,
              AppRoutes.adminMaintenanceTeams: _adminMaintenanceTeams,
              AppRoutes.adminMaintenanceTeamForm: (context) =>
                  _adminMaintenanceTeamForm(
                    context,
                    _maintenanceTeamFromSettings(
                      ModalRoute.of(context)?.settings,
                      optional: true,
                    ),
                  ),
              AppRoutes.adminMaintenanceTeamDetails: (context) =>
                  _adminMaintenanceTeamDetails(
                    context,
                    _maintenanceTeamFromSettings(
                      ModalRoute.of(context)?.settings,
                    )!,
                  ),
              AppRoutes.ministryDashboard: _ministryDashboard,
              AppRoutes.ministryReports: _ministryReports,
              AppRoutes.ministryReportInsights: _ministryReportInsights,
              AppRoutes.ministryAnalytics: _ministryAnalytics,
              AppRoutes.ministryMunicipalPerformance:
                  _ministryMunicipalPerformance,
              AppRoutes.ministryMunicipalityDetail: (context) =>
                  _ministryMunicipalityDetail(
                    context,
                    _regionalLeaderFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.ministryProfile: _ministryProfile,
              AppRoutes.ministryNotifications: _ministryNotifications,
              AppRoutes.municipalDashboard: _municipalDashboard,
              AppRoutes.municipalInbox: _municipalInbox,
              AppRoutes.municipalActiveReports: _municipalActiveReports,
              AppRoutes.municipalReportReview: (context) =>
                  _municipalReportReview(
                    context,
                    _incomingReportFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.municipalAssignTeam: (context) => _municipalAssignTeam(
                context,
                _incomingReportFromSettings(ModalRoute.of(context)?.settings),
              ),
              AppRoutes.municipalReportProgress: (context) =>
                  _municipalReportProgress(
                    context,
                    _activeReportFromSettings(ModalRoute.of(context)?.settings),
                  ),
              AppRoutes.municipalVerification: (context) =>
                  _municipalVerification(
                    context,
                    _incomingReportFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.municipalResolvedReports: _municipalResolvedReports,
              AppRoutes.municipalResolutionDetails: (context) =>
                  _municipalResolutionDetails(
                    context,
                    _resolvedReportFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.municipalProfile: _municipalProfile,
              AppRoutes.municipalNotifications: _municipalNotifications,
              AppRoutes.maintenanceDashboard: _maintenanceDashboard,
              AppRoutes.maintenanceAssignedTasks: _maintenanceAssignedTasks,
              AppRoutes.maintenanceTaskDetails: (context) =>
                  _maintenanceTaskDetails(
                    context,
                    _maintenanceTaskFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.maintenanceUpdateProgress: (context) =>
                  _maintenanceUpdateProgress(
                    context,
                    _maintenanceTaskFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.maintenanceTaskCompleted: (context) =>
                  _maintenanceTaskCompleted(
                    context,
                    _maintenanceTaskFromSettings(
                      ModalRoute.of(context)?.settings,
                    ),
                  ),
              AppRoutes.maintenanceProfile: _maintenanceProfile,
              AppRoutes.maintenanceNotifications: _maintenanceNotifications,
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
              if (uri?.path == AppRoutes.adminMaintenanceTeamForm) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _adminMaintenanceTeamForm(
                    context,
                    _maintenanceTeamFromSettings(settings, optional: true),
                  ),
                );
              }
              if (uri?.path == AppRoutes.adminMaintenanceTeamDetails) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _adminMaintenanceTeamDetails(
                    context,
                    _maintenanceTeamFromSettings(settings)!,
                  ),
                );
              }
              if (uri?.path == AppRoutes.ministryMunicipalityDetail) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _ministryMunicipalityDetail(
                    context,
                    _regionalLeaderFromSettings(settings),
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
              if (uri?.path == AppRoutes.municipalAssignTeam) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _municipalAssignTeam(
                    context,
                    _incomingReportFromSettings(settings),
                  ),
                );
              }
              if (uri?.path == AppRoutes.maintenanceTaskDetails) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _maintenanceTaskDetails(
                    context,
                    _maintenanceTaskFromSettings(settings),
                  ),
                );
              }
              if (uri?.path == AppRoutes.maintenanceUpdateProgress) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _maintenanceUpdateProgress(
                    context,
                    _maintenanceTaskFromSettings(settings),
                  ),
                );
              }
              if (uri?.path == AppRoutes.maintenanceTaskCompleted) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (context) => _maintenanceTaskCompleted(
                    context,
                    _maintenanceTaskFromSettings(settings),
                  ),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }
}

/// The bottom-nav tab destinations reachable via [_replaceWith] — kept as
/// its own small map (reusing the exact same builder functions the main
/// `routes:` table uses) rather than threading [tabRoute] through that
/// whole 60+ entry table, since only these 14 are ever reached by a tab
/// switch rather than a drill-down push.
final Map<String, WidgetBuilder> _tabRouteBuilders = {
  AppRoutes.adminDashboard: _adminDashboard,
  AppRoutes.adminSystemActivity: _adminSystemActivity,
  AppRoutes.adminSystemSettings: _adminSystemSettings,
  AppRoutes.adminUserManagement: _adminUserManagement,
  AppRoutes.maintenanceAssignedTasks: _maintenanceAssignedTasks,
  AppRoutes.maintenanceDashboard: _maintenanceDashboard,
  AppRoutes.ministryAnalytics: _ministryAnalytics,
  AppRoutes.ministryDashboard: _ministryDashboard,
  AppRoutes.ministryMunicipalPerformance: _ministryMunicipalPerformance,
  AppRoutes.ministryReports: _ministryReports,
  AppRoutes.municipalActiveReports: _municipalActiveReports,
  AppRoutes.municipalDashboard: _municipalDashboard,
  AppRoutes.municipalInbox: _municipalInbox,
  AppRoutes.municipalResolvedReports: _municipalResolvedReports,
};

void _replaceWith(BuildContext context, String routeName) {
  if (ModalRoute.of(context)?.settings.name == routeName) return;
  final builder = _tabRouteBuilders[routeName];
  if (builder == null) {
    // Not one of the known tab destinations — fall back to the app-wide
    // default transition rather than silently doing nothing.
    Navigator.of(context).pushReplacementNamed(routeName);
    return;
  }
  Navigator.of(
    context,
  ).pushReplacement(tabRoute(context, builder, routeName: routeName));
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

/// Maps civic_voice_api's Postgres `UserRole` string onto the Flutter
/// side's [AppRole] — the one place a real signed-in session's role gets
/// translated into the mock-era routing/session cache every other module
/// still reads via [MockAuthService].
AppRole? _appRoleForBackendRole(String role) {
  return switch (role) {
    'CITIZEN' => AppRole.citizen,
    'MUNICIPAL' => AppRole.municipalOfficer,
    'MAINTENANCE' => AppRole.maintenanceTeam,
    'MINISTRY' => AppRole.ministrySupervisor,
    'ADMIN' => AppRole.systemAdministrator,
    _ => null,
  };
}

Future<void> _selectSyncedRole(
  MockAuthService auth,
  AppRole role,
  SyncedUser user,
) async {
  final region = user.region == null
      ? null
      : Region.values.cast<Region?>().firstWhere(
          (item) => item?.name == user.region,
          orElse: () => null,
        );
  final assembly = region == null || user.assembly == null
      ? null
      : ghanaAssemblies[region]?.cast<Assembly?>().firstWhere(
          (item) => item?.name == user.assembly,
          orElse: () => null,
        );
  final tier = role == AppRole.systemAdministrator
      ? user.adminTier == 'admin'
            ? AdminTier.admin
            : AdminTier.superAdmin
      : null;
  if (role == AppRole.municipalOfficer) {
    MunicipalSession.instance.setAuthenticatedUser(
      publicId: user.publicId,
      fullName: user.fullName,
      phone: user.phone ?? 'Phone unavailable',
      region: region?.label ?? user.region ?? 'Region not assigned',
      assembly: assembly?.fullName ?? user.assembly ?? 'Assembly not assigned',
    );
  }
  if (role == AppRole.maintenanceTeam) {
    MaintenanceSession.instance.setAuthenticatedUser(
      publicId: user.publicId,
      fullName: user.fullName,
      phone: user.phone ?? 'Phone unavailable',
      region: region?.label ?? user.region ?? 'Region not assigned',
      assembly: assembly?.fullName ?? user.assembly ?? 'Assembly not assigned',
      teamId: user.maintenanceTeamId,
      teamName: user.maintenanceTeamName,
      teamLeadUserId: user.maintenanceTeamLeadUserId,
    );
  }
  if (role == AppRole.ministrySupervisor) {
    MinistrySession.instance.setAuthenticatedUser(
      publicId: user.publicId,
      fullName: user.fullName,
      phone: user.phone ?? 'Phone unavailable',
    );
  }
  await auth.selectRole(
    role,
    adminTier: tier,
    region: region,
    assembly: assembly,
    mustChangePasswordOnFirstLogin: user.mustChangePassword,
  );
}

/// Real Firebase + civic_voice_api sign-in, landing in the same
/// [MockAuthService] session cache every other module already reads —
/// see the NOTE above the `routes` map. Kept as a private route widget
/// (not inline in the route table) because it needs to hold its own
/// [LoginViewState] across the async round trip.
class _LoginRoute extends StatefulWidget {
  const _LoginRoute();

  @override
  State<_LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<_LoginRoute> {
  LoginViewState _state = LoginViewState.ready;

  Future<void> _handleSignIn(
    BuildContext context,
    String phone,
    String password,
    bool keepSignedIn,
  ) async {
    setState(() => _state = LoginViewState.loading);
    try {
      final email = await ApiClient.instance.resolveLoginEmail(phone);
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) throw Exception('No ID token after sign-in');
      final syncedUser = await ApiClient.instance.syncUser(idToken: idToken);
      final appRole = _appRoleForBackendRole(syncedUser.role);
      if (appRole == null) throw Exception('Unknown role: ${syncedUser.role}');
      await _selectSyncedRole(MockAuthService(), appRole, syncedUser);
      if (context.mounted) {
        await _offerNotificationPermissionAfterLogin(context);
      }
      await _configurePushNotifications();
      if (appRole == AppRole.citizen) {
        ProfileCrudService.instance.loadSignedInUser(syncedUser);
        await ReportCrudService.instance.refresh();
      } else if (appRole == AppRole.municipalOfficer) {
        await MunicipalReportDirectory.instance.refresh();
        await MaintenanceTeamDirectory.instance.refreshForMunicipal();
      } else if (appRole == AppRole.maintenanceTeam) {
        await MaintenanceTaskDirectory.instance.refresh();
      } else if (appRole == AppRole.ministrySupervisor) {
        await MinistryDataDirectory.instance.refresh();
      } else if (appRole == AppRole.systemAdministrator) {
        AdminUserDirectory.instance.currentApiUserId = syncedUser.id;
        await AdminUserDirectory.instance.refresh();
        await MaintenanceTeamDirectory.instance.refreshForAdmin();
        await AdminSystemActivityDirectory.instance.refresh();
      }
      if (!context.mounted) return;
      await AppCacheService.instance.setKeepSignedIn(keepSignedIn);
      if (!context.mounted) return;
      _completeSignIn(context);
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() => _state = LoginViewState.invalidCredentials);
    } on ApiException {
      if (!mounted) return;
      setState(() => _state = LoginViewState.invalidCredentials);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = LoginViewState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      state: _state,
      onBack: Navigator.canPop(context)
          ? () => Navigator.of(context).maybePop()
          : null,
      onSignIn: (phone, password, keepSignedIn) =>
          _handleSignIn(context, phone, password, keepSignedIn),
      onForgotPassword: () =>
          Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
      onRegister: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.registration),
    );
  }
}

/// Real Firebase + civic_voice_api Citizen self-registration. Form submit
/// only sends a real SMS verification code — the account itself isn't
/// created until that code is confirmed on [_RegistrationOtpRoute], so a
/// phone number never gets an account made against it without proving
/// ownership first.
class _RegistrationRoute extends StatefulWidget {
  const _RegistrationRoute();

  @override
  State<_RegistrationRoute> createState() => _RegistrationRouteState();
}

class _RegistrationRouteState extends State<_RegistrationRoute> {
  RegistrationViewState _state = RegistrationViewState.ready;
  String? _errorMessage;

  Future<void> _handleCreateAccount(
    BuildContext context,
    String fullName,
    String phone,
    String password,
  ) async {
    setState(() {
      _state = RegistrationViewState.loading;
      _errorMessage = null;
    });
    try {
      final expiresAt = await ApiClient.instance.sendRegistrationOtp(phone);
      if (!context.mounted) return;
      setState(() => _state = RegistrationViewState.ready);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _RegistrationOtpRoute(
            fullName: fullName,
            phone: phone,
            password: password,
            expiresAt: expiresAt,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = error.statusCode == 409
            ? RegistrationViewState.phoneAlreadyRegistered
            : RegistrationViewState.error;
        _errorMessage = error.statusCode == 409 ? null : error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = RegistrationViewState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationScreen(
      state: _state,
      errorMessage: _errorMessage,
      onBack: Navigator.canPop(context)
          ? () => Navigator.of(context).maybePop()
          : null,
      onCreateAccount: (fullName, phone, password) =>
          _handleCreateAccount(context, fullName, phone, password),
      onLogin: () =>
          Navigator.of(context).pushReplacementNamed(AppRoutes.login),
    );
  }
}

/// Real OTP verification for Citizen registration — the account is only
/// created here, on a correct code, using the fullName/phone/password
/// collected on the previous screen.
class _RegistrationOtpRoute extends StatefulWidget {
  const _RegistrationOtpRoute({
    required this.fullName,
    required this.phone,
    required this.password,
    required this.expiresAt,
  });

  final String fullName;
  final String phone;
  final String password;
  final DateTime? expiresAt;

  @override
  State<_RegistrationOtpRoute> createState() => _RegistrationOtpRouteState();
}

class _RegistrationOtpRouteState extends State<_RegistrationOtpRoute> {
  Future<bool> _handleVerify(BuildContext context, String code) async {
    try {
      // If they got here via "Continue as Guest" and are still on that
      // same Anonymous Auth session, pass its token along so the backend
      // upgrades that account in place — same UID, so any reports they
      // filed as a guest carry over automatically instead of needing a
      // separate claim step.
      final currentUser = FirebaseAuth.instance.currentUser;
      final guestIdToken = (currentUser != null && currentUser.isAnonymous)
          ? await currentUser.getIdToken()
          : null;
      final email = await ApiClient.instance.registerCitizen(
        fullName: widget.fullName,
        phone: widget.phone,
        password: widget.password,
        otp: code,
        guestIdToken: guestIdToken,
      );
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: widget.password,
      );
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) throw Exception('No ID token after registration');
      final syncedUser = await ApiClient.instance.syncUser(idToken: idToken);
      ProfileCrudService.instance.loadSignedInUser(syncedUser);
      await MockAuthService().selectRole(AppRole.citizen);
      await _configurePushNotifications();
      await ReportCrudService.instance.refresh();
      if (!context.mounted) return true;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.citizenDashboard, (_) => false);
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 409) {
        // The OTP itself was correct — this phone number already has an
        // account (e.g. it was provisioned as staff, or registered
        // earlier). No amount of retrying the code can ever succeed here,
        // so send the user back to fix the phone number instead of
        // leaving them stuck on a misleading "Incorrect Code" retry loop.
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
        return true;
      }
      // A real wrong/expired code — the screen's own inline error covers it.
      return false;
    }
  }

  Future<DateTime?> _handleResend() {
    return ApiClient.instance.sendRegistrationOtp(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    return OtpVerificationScreen(
      phoneNumber: widget.phone,
      purpose: OtpPurpose.registration,
      expiresAt: widget.expiresAt,
      onBack: () => Navigator.of(context).maybePop(),
      onVerify: (code) => _handleVerify(context, code),
      onResend: _handleResend,
    );
  }
}

void _completeSignIn(BuildContext context) {
  final auth = MockAuthService();
  final routeName = _routeForRole(auth.getCurrentRole());
  if (routeName == null) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.testRoleSelector, (_) => false);
    return;
  }
  if (auth.mustChangePasswordOnFirstLogin()) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.forcePasswordReset, (_) => false);
    return;
  }
  Navigator.of(context).pushNamedAndRemoveUntil(routeName, (_) => false);
}

void _startForgotPasswordOtp(
  BuildContext context,
  String phoneNumber,
  DateTime? expiresAt,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => OtpVerificationScreen(
        phoneNumber: phoneNumber,
        purpose: OtpPurpose.forgotPassword,
        expiresAt: expiresAt,
        onBack: () => Navigator.of(context).maybePop(),
        onResend: () => ApiClient.instance.sendForgotPasswordOtp(phoneNumber),
        onVerify: (code) async {
          late final String resetToken;
          try {
            resetToken = await ApiClient.instance.verifyPasswordResetOtp(
              phone: phoneNumber,
              otp: code,
            );
          } on ApiException {
            return false;
          }
          if (!context.mounted) return false;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (passwordContext) => SetNewPasswordScreen(
                purpose: SetNewPasswordPurpose.forgotPassword,
                onBack: () => Navigator.of(passwordContext).maybePop(),
                onSaved: (newPassword) async {
                  final navigator = Navigator.of(passwordContext);
                  try {
                    await ApiClient.instance.resetPassword(
                      phone: phoneNumber,
                      resetToken: resetToken,
                      newPassword: newPassword,
                    );
                  } on ApiException {
                    return false;
                  }
                  navigator.pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (_) => false,
                  );
                  return true;
                },
              ),
            ),
          );
          return true;
        },
      ),
    ),
  );
}

class _ForgotPasswordRoute extends StatefulWidget {
  const _ForgotPasswordRoute();

  @override
  State<_ForgotPasswordRoute> createState() => _ForgotPasswordRouteState();
}

class _ForgotPasswordRouteState extends State<_ForgotPasswordRoute> {
  ForgotPasswordViewState _state = ForgotPasswordViewState.ready;
  String? _errorMessage;

  Future<void> _send(String phone) async {
    setState(() {
      _state = ForgotPasswordViewState.loading;
      _errorMessage = null;
    });
    try {
      final expiresAt = await ApiClient.instance.sendForgotPasswordOtp(phone);
      if (!mounted) return;
      _startForgotPasswordOtp(context, phone, expiresAt);
      setState(() => _state = ForgotPasswordViewState.ready);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _state = error.statusCode == 404
            ? ForgotPasswordViewState.phoneNotFound
            : ForgotPasswordViewState.recoveryError;
        _errorMessage = error.statusCode == 404 ? null : error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ForgotPasswordScreen(
    state: _state,
    errorMessage: _errorMessage,
    onBack: () => Navigator.of(context).maybePop(),
    onSendCode: _send,
    onBackToLogin: () => Navigator.of(context).maybePop(),
  );
}

Widget _forcedPasswordReset(BuildContext context) {
  return SetNewPasswordScreen(
    purpose: SetNewPasswordPurpose.firstLogin,
    onSaved: (newPassword) async {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return false;
      try {
        await ApiClient.instance.changePassword(
          idToken: idToken,
          newPassword: newPassword,
        );
      } on ApiException {
        return false;
      }
      final auth = MockAuthService();
      await auth.clearMustChangePasswordOnFirstLogin();
      if (!context.mounted) return true;
      Navigator.of(context).pushNamedAndRemoveUntil(
        _routeForRole(auth.getCurrentRole()) ?? AppRoutes.testRoleSelector,
        (_) => false,
      );
      return true;
    },
  );
}

Widget _biometricLock(BuildContext context) {
  return BioLockScreen(
    onAuthenticated: () => Navigator.of(context).pushNamedAndRemoveUntil(
      _routeForRole(MockAuthService().getCurrentRole()) ?? AppRoutes.login,
      (_) => false,
    ),
    onLogOut: () => signOut(context),
  );
}

/// Real Firebase Anonymous Auth session (not just "push the dashboard
/// with no session at all") — this is what lets a guest actually submit
/// and track reports via the same authenticated API every real citizen
/// uses, and what makes /citizen-register's guest-upgrade path (same
/// UID, same rows, reports carry over) possible later if they register.
Future<void> _continueAsGuest(BuildContext context) async {
  try {
    final credential = await FirebaseAuth.instance.signInAnonymously();
    final idToken = await credential.user?.getIdToken();
    if (idToken == null) throw Exception('No ID token after guest sign-in');
    final syncedUser = await ApiClient.instance.syncUser(idToken: idToken);
    ProfileCrudService.instance.loadSignedInUser(syncedUser);
    await MockAuthService().selectRole(AppRole.citizen);
    if (!context.mounted) return;
    Navigator.of(context).pushNamed(AppRoutes.citizenDashboard);
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not continue as guest. Check your connection and try again.',
        ),
      ),
    );
  }
}

Future<void> _finishChangePassword(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  await MockAuthService().clearUser();
  if (!context.mounted) return;
  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}

/// Kept as a layout seam for the role dashboard builders and widget tests;
/// the former development-only floating role switch is intentionally gone.
Widget _withSwitchRoleButton(BuildContext context, Widget child) => child;

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

  final users = AdminUserDirectory.instance.users.value;
  final uri = Uri.tryParse(settings?.name ?? '');
  final userId = uri?.queryParameters['userId'];
  if (userId != null) {
    for (final user in users) {
      if (user.userId == userId) return user;
    }
  }
  return users.first;
}

void _pushMinistryMunicipalityDetail(
  BuildContext context,
  RegionalLeaderItem municipality,
) {
  final route = Uri(
    path: AppRoutes.ministryMunicipalityDetail,
    queryParameters: {'name': municipality.name},
  ).toString();
  Navigator.of(context).pushNamed(route, arguments: municipality);
}

RegionalLeaderItem _regionalLeaderFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is RegionalLeaderItem) return argument;

  final leaders = MunicipalPerformanceData.mock().regionalLeaders;
  final uri = Uri.tryParse(settings?.name ?? '');
  final name = uri?.queryParameters['name'];
  if (name != null) {
    for (final leader in leaders) {
      if (leader.name == name) return leader;
    }
  }
  return leaders.first;
}

void _pushAdminMaintenanceTeamDetails(
  BuildContext context,
  MaintenanceTeam team,
) {
  final route = Uri(
    path: AppRoutes.adminMaintenanceTeamDetails,
    queryParameters: {'teamId': team.teamId},
  ).toString();
  Navigator.of(context).pushNamed(route, arguments: team);
}

void _pushAdminMaintenanceTeamForm(
  BuildContext context, [
  MaintenanceTeam? team,
]) {
  final route = team == null
      ? AppRoutes.adminMaintenanceTeamForm
      : Uri(
          path: AppRoutes.adminMaintenanceTeamForm,
          queryParameters: {'teamId': team.teamId},
        ).toString();
  Navigator.of(context).pushNamed(route, arguments: team);
}

MaintenanceTeam? _maintenanceTeamFromSettings(
  RouteSettings? settings, {
  bool optional = false,
}) {
  final argument = settings?.arguments;
  if (argument is MaintenanceTeam) return argument;

  final uri = Uri.tryParse(settings?.name ?? '');
  final teamId = uri?.queryParameters['teamId'];
  if (teamId != null) {
    final team = MaintenanceTeamDirectory.instance.teamById(teamId);
    if (team != null) return team;
  }
  if (optional) return null;
  return MaintenanceTeamDirectory.instance.teams.value.first;
}

Widget _adminDashboard(BuildContext context) {
  return ValueListenableBuilder(
    valueListenable: AdminSystemActivityDirectory.instance.health,
    builder: (context, health, _) => _withSwitchRoleButton(
      context,
      AdminDashboardScreen(
        healthStats: health,
        onRefreshHealth: AdminSystemActivityDirectory.instance.refreshHealth,
        onNavigateToUsers: () =>
            _replaceWith(context, AppRoutes.adminUserManagement),
        onNavigateToRoles: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
        onNavigateToSettings: () =>
            _replaceWith(context, AppRoutes.adminSystemSettings),
        onNavigateToActivity: () =>
            _replaceWith(context, AppRoutes.adminSystemActivity),
        onNavigateToMaintenanceTeams: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
        onOpenProfile: () =>
            Navigator.of(context).pushNamed(AppRoutes.adminProfile),
        onNotificationsTap: () => _openAdminNotifications(context),
      ),
    ),
  );
}

Widget _adminUserManagement(BuildContext context) {
  return AdminUserManagementScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onOpenUserDetails: (user) => _pushAdminUserDetails(context, user),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onCreateUser: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminCreateUser),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminCreateUser(BuildContext context) {
  return AdminCreateUserScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onNotificationsTap: () => _openAdminNotifications(context),
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
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminMaintenanceTeams(BuildContext context) {
  return AdminMaintenanceTeamsScreen(
    initialState: AdminSession.instance.canManageTeams
        ? AdminMaintenanceTeamsViewState.loaded
        : AdminMaintenanceTeamsViewState.unauthorized,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onCreateTeam: () => _pushAdminMaintenanceTeamForm(context),
    onOpenTeamDetails: (team) =>
        _pushAdminMaintenanceTeamDetails(context, team),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminMaintenanceTeamForm(BuildContext context, MaintenanceTeam? team) {
  return AdminMaintenanceTeamFormScreen(
    team: team,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onClose: () => _popOrReplaceWith(context, AppRoutes.adminMaintenanceTeams),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminMaintenanceTeamDetails(
  BuildContext context,
  MaintenanceTeam team,
) {
  return AdminMaintenanceTeamDetailsScreen(
    team: team,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onBackToTeams: () =>
        _popOrReplaceWith(context, AppRoutes.adminMaintenanceTeams),
    onEditTeam: (team) => _pushAdminMaintenanceTeamForm(context, team),
    onOpenUserDetails: (user) => _pushAdminUserDetails(context, user),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminRoleManagement(BuildContext context) {
  return AdminRoleManagementScreen(
    // An assembly Admin has no tiers to review — Role Management is a
    // Super Admin-only screen. The drawer already hides its entry point
    // for them; this is the fallback if the route is still reached
    // directly (e.g. a stale deep link).
    initialState: AdminSession.instance.isSuperAdmin
        ? AdminRoleManagementViewState.loaded
        : AdminRoleManagementViewState.unauthorized,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminSystemActivity(BuildContext context) {
  return AnimatedBuilder(
    animation: Listenable.merge([
      AdminSystemActivityDirectory.instance.items,
      AdminSystemActivityDirectory.instance.health,
    ]),
    builder: (context, _) => AdminSystemActivityScreen(
      items: AdminSystemActivityDirectory.instance.hasLiveSnapshot
          ? AdminSystemActivityDirectory.instance.items.value
          : null,
      healthStats: AdminSystemActivityDirectory.instance.health.value,
      onRefresh: AdminSystemActivityDirectory.instance.refresh,
      // Both tiers reach a real loaded feed — an assembly Admin's own is
      // scoped down to their jurisdiction and drops the health stats, both
      // handled inside the screen itself via AdminSession. See
      // AdminSystemActivityScreen's own doc comment.
      onNavigateToDashboard: () =>
          _replaceWith(context, AppRoutes.adminDashboard),
      onNavigateToUsers: () =>
          _replaceWith(context, AppRoutes.adminUserManagement),
      onNavigateToRoles: () =>
          Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
      onNavigateToSettings: () =>
          _replaceWith(context, AppRoutes.adminSystemSettings),
      onNavigateToMaintenanceTeams: () =>
          Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
      onOpenProfile: () =>
          Navigator.of(context).pushNamed(AppRoutes.adminProfile),
      onNotificationsTap: () => _openAdminNotifications(context),
    ),
  );
}

void _openAdminNotifications(BuildContext context) {
  Navigator.of(context).pushNamed(AppRoutes.adminNotifications);
}

Widget _adminNotifications(BuildContext context) {
  return AdminNotificationsScreen(
    onBack: () => Navigator.of(context).maybePop(),
    onOpenUser: (publicId) {
      final user = AdminUserDirectory.instance.userById(publicId);
      if (user != null) _pushAdminUserDetails(context, user);
    },
  );
}

Widget _adminSystemSettings(BuildContext context) {
  return AdminSystemSettingsScreen(
    // An assembly Admin doesn't configure the platform — System Settings
    // is Super Admin-only. The bottom nav already drops this tab for
    // them; this is the fallback if the route is still reached directly.
    initialState: AdminSession.instance.isSuperAdmin
        ? AdminSystemSettingsViewState.loaded
        : AdminSystemSettingsViewState.unauthorized,
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onOpenProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminProfile),
    onNotificationsTap: () => _openAdminNotifications(context),
  );
}

Widget _adminProfile(BuildContext context) {
  final currentUser = AdminUserDirectory.instance.currentUser;
  return admin.AdminProfileScreen(
    initialData: currentUser == null ? null : adminProfileFromUser(currentUser),
    onSaveProfile: (fullName) async {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token == null) return false;
        await ApiClient.instance.updateProfile(
          idToken: token,
          fullName: fullName,
        );
        await AdminUserDirectory.instance.refresh();
        return true;
      } catch (_) {
        return false;
      }
    },
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.adminDashboard),
    onNavigateToUsers: () =>
        _replaceWith(context, AppRoutes.adminUserManagement),
    onNavigateToRoles: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminRoleManagement),
    onNavigateToSettings: () =>
        _replaceWith(context, AppRoutes.adminSystemSettings),
    onNavigateToActivity: () =>
        _replaceWith(context, AppRoutes.adminSystemActivity),
    onChangePassword: () =>
        Navigator.of(context).pushNamed(AppRoutes.changePassword),
    onAbout: () => Navigator.of(context).pushNamed(AppRoutes.about),
    onNavigateToMaintenanceTeams: () =>
        Navigator.of(context).pushNamed(AppRoutes.adminMaintenanceTeams),
    onNotificationsTap: () => _openAdminNotifications(context),
    onSignOut: () => signOut(context),
  );
}

Widget _ministryDashboard(BuildContext context) {
  return ValueListenableBuilder<List<IncomingReportItem>>(
    valueListenable: MunicipalReportDirectory.instance.reports,
    builder: (context, _, _) => _withSwitchRoleButton(
      context,
      MinistryDashboardScreen(
        data: Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
            ? null
            : MinistryDataDirectory.instance.dashboard,
        onRefresh:
            Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
            ? null
            : MinistryDataDirectory.instance.refresh,
        onNavigateToAnalytics: () =>
            _replaceWith(context, AppRoutes.ministryAnalytics),
        onNavigateToMunicipalities: () =>
            _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
        onNavigateToReports: () =>
            _replaceWith(context, AppRoutes.ministryReports),
        onProfileTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
        onNotificationsTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.ministryNotifications),
        onOpenMunicipality: (municipality) =>
            _pushMinistryMunicipalityDetail(context, municipality),
      ),
    ),
  );
}

Widget _ministryAnalytics(BuildContext context) {
  return ValueListenableBuilder<List<IncomingReportItem>>(
    valueListenable: MunicipalReportDirectory.instance.reports,
    builder: (context, _, _) => MinistryAnalyticsScreen(
      data: Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.analytics,
      dataForRange:
          Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.analyticsFor,
      onNavigateToDashboard: () =>
          _replaceWith(context, AppRoutes.ministryDashboard),
      onNavigateToMunicipalities: () =>
          _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
      onNavigateToReports: () =>
          _replaceWith(context, AppRoutes.ministryReports),
      onProfileTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryNotifications),
      onViewReportInsights: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryReportInsights),
    ),
  );
}

Widget _ministryMunicipalPerformance(BuildContext context) {
  return ValueListenableBuilder<List<IncomingReportItem>>(
    valueListenable: MunicipalReportDirectory.instance.reports,
    builder: (context, _, _) => MinistryMunicipalPerformanceScreen(
      data: Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.performance,
      onNavigateToDashboard: () =>
          _replaceWith(context, AppRoutes.ministryDashboard),
      onNavigateToAnalytics: () =>
          _replaceWith(context, AppRoutes.ministryAnalytics),
      onNavigateToReports: () =>
          _replaceWith(context, AppRoutes.ministryReports),
      onProfileTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryNotifications),
      onOpenMunicipality: (municipality) =>
          _pushMinistryMunicipalityDetail(context, municipality),
    ),
  );
}

Widget _ministryMunicipalityDetail(
  BuildContext context,
  RegionalLeaderItem municipality,
) {
  return MinistryMunicipalityDetailScreen(
    municipality: municipality,
    onBack: () => Navigator.of(context).maybePop(),
  );
}

Widget _ministryReports(BuildContext context) {
  return ValueListenableBuilder<List<IncomingReportItem>>(
    valueListenable: MunicipalReportDirectory.instance.reports,
    builder: (context, _, _) => MinistryReportsScreen(
      data: Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.reportOverview,
      onRefresh:
          Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.refresh,
      onNavigateToDashboard: () =>
          _replaceWith(context, AppRoutes.ministryDashboard),
      onNavigateToAnalytics: () =>
          _replaceWith(context, AppRoutes.ministryAnalytics),
      onNavigateToMunicipalities: () =>
          _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
      onProfileTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryProfile),
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryNotifications),
      onViewReportInsights: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryReportInsights),
    ),
  );
}

Widget _ministryReportInsights(BuildContext context) {
  return ValueListenableBuilder<List<IncomingReportItem>>(
    valueListenable: MunicipalReportDirectory.instance.reports,
    builder: (context, _, _) => MinistryReportInsightsScreen(
      data: Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : MinistryDataDirectory.instance.insights,
      dataForFilters:
          Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null
          ? null
          : (dateRange, category, status) =>
                MinistryDataDirectory.instance.insightsFor(
                  dateRange: dateRange,
                  category: category,
                  status: status,
                ),
      onBack: () => _popOrReplaceWith(context, AppRoutes.ministryDashboard),
      onViewFocusSummary: () =>
          _replaceWith(context, AppRoutes.ministryMunicipalPerformance),
    ),
  );
}

Widget _ministryProfile(BuildContext context) {
  return ValueListenableBuilder(
    valueListenable: MinistrySession.instance.profile,
    builder: (context, profile, _) => ministry.MinistryProfileScreen(
      profile: profile,
      onBack: () => _popOrReplaceWith(context, AppRoutes.ministryDashboard),
      onChangePassword: () =>
          Navigator.of(context).pushNamed(AppRoutes.changePassword),
      onAbout: () => Navigator.of(context).pushNamed(AppRoutes.about),
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.ministryNotifications),
      onLogOut: () => signOut(context),
      onSaveProfile: (fullName) async {
        try {
          final token = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (token == null) return false;
          final json = await ApiClient.instance.updateProfile(
            idToken: token,
            fullName: fullName,
          );
          MinistrySession.instance.updateProfile(
            fullName: json['fullName'] as String? ?? fullName,
          );
          return true;
        } catch (_) {
          return false;
        }
      },
    ),
  );
}

Widget _ministryNotifications(BuildContext context) {
  return MinistryNotificationsScreen(
    onBack: () => Navigator.of(context).maybePop(),
    onNotificationTap: (_) => _replaceWith(context, AppRoutes.ministryReports),
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
  IncomingReportItem report,
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

  final directoryReports = MunicipalReportDirectory.instance.reports.value;
  final reports = directoryReports.isNotEmpty
      ? directoryReports
      : IncomingReportItem.mock();
  final uri = Uri.tryParse(settings?.name ?? '');
  final reportId = uri?.queryParameters['reportId'];
  if (reportId != null) {
    for (final report in reports) {
      if (report.referenceId == reportId) return report;
    }
  }
  return reports.first;
}

IncomingReportItem _activeReportFromSettings(RouteSettings? settings) {
  final argument = settings?.arguments;
  if (argument is IncomingReportItem) return argument;

  final reports = MunicipalReportDirectory.instance.reports.value;
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

  final liveReports = MunicipalReportDirectory.instance.reports.value
      .where((report) => report.status == ReportStatus.resolved)
      .map(ResolvedReportItem.fromReport)
      .toList();
  final reports = liveReports.isNotEmpty
      ? liveReports
      : ResolvedReportItem.mock();
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
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.municipalNotifications),
      onReportTap: (report) => _pushMunicipalReportReview(context, report),
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
    onNotificationsTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalNotifications),
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
    onNotificationsTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalNotifications),
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
    onNotificationsTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.municipalNotifications),
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

Widget _municipalAssignTeam(BuildContext context, IncomingReportItem report) {
  return MunicipalAssignTeamScreen(
    referenceId: report.referenceId,
    status: report.status,
    initialState: MaintenanceTeamDirectory.instance.teams.value.isEmpty
        ? MunicipalAssignTeamViewState.empty
        : MunicipalAssignTeamViewState.loaded,
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalVerification),
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.municipalDashboard),
  );
}

Widget _municipalReportProgress(
  BuildContext context,
  IncomingReportItem report,
) {
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
    data: report,
    onBack: () =>
        _popOrReplaceWith(context, AppRoutes.municipalResolvedReports),
  );
}

Widget _municipalProfile(BuildContext context) {
  return municipal.MunicipalProfileScreen(
    initialProfile: MunicipalSession.instance.profile.value,
    onBack: () => _popOrReplaceWith(context, AppRoutes.municipalDashboard),
    onChangePassword: () =>
        Navigator.of(context).pushNamed(AppRoutes.changePassword),
    onAbout: () => Navigator.of(context).pushNamed(AppRoutes.about),
    onLogOut: () => signOut(context),
    onSaveProfile: (fullName) async {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token == null) return false;
        await ApiClient.instance.updateProfile(
          idToken: token,
          fullName: fullName,
        );
        MunicipalSession.instance.updateName(fullName);
        return true;
      } catch (_) {
        return false;
      }
    },
  );
}

Widget _municipalNotifications(BuildContext context) {
  return MunicipalNotificationsScreen(
    onBack: () => Navigator.of(context).maybePop(),
    onOpenReport: (referenceId) {
      final report = MunicipalReportDirectory.instance.byReferenceId(
        referenceId,
      );
      if (report == null) return;
      switch (report.status) {
        case ReportStatus.resolved || ReportStatus.rejected:
          _pushMunicipalResolutionDetails(
            context,
            ResolvedReportItem.fromReport(report),
          );
        case ReportStatus.assigned || ReportStatus.inProgress:
          _pushMunicipalReportProgress(context, report);
        case ReportStatus.submitted || ReportStatus.underReview:
          _pushMunicipalReportReview(context, report);
      }
    },
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
      onNotificationsTap: () =>
          Navigator.of(context).pushNamed(AppRoutes.maintenanceNotifications),
      onOpenTaskDetails: (taskId) =>
          _pushMaintenanceTaskDetails(context, taskId),
    ),
  );
}

Widget _maintenanceAssignedTasks(BuildContext context) {
  return maintenance_tasks.AssignedTasksScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToProfile: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceProfile),
    onNotificationsTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceNotifications),
    onOpenTaskDetails: (taskId) => _pushMaintenanceTaskDetails(context, taskId),
  );
}

Widget _maintenanceTaskDetails(BuildContext context, MaintenanceTask task) {
  return maintenance_details.TaskDetailsScreen(
    task: task,
    onBack: () => Navigator.of(context).maybePop(),
    onUpdateProgress: () => _pushMaintenanceUpdateProgress(context, task.id),
  );
}

Widget _maintenanceUpdateProgress(BuildContext context, MaintenanceTask task) {
  return maintenance_progress.UpdateProgressScreen(
    task: task,
    onBack: () => Navigator.of(context).maybePop(),
    onTaskCompleted: (taskId) => _pushMaintenanceTaskCompleted(context, taskId),
  );
}

Widget _maintenanceTaskCompleted(BuildContext context, MaintenanceTask task) {
  return maintenance_completed.TaskCompletedScreen(
    task: task,
    onNavigateToDashboard: () => Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.maintenanceDashboard, (_) => false),
  );
}

Widget _maintenanceProfile(BuildContext context) {
  return maintenance_profile.ProfileScreen(
    onNavigateToDashboard: () =>
        _replaceWith(context, AppRoutes.maintenanceDashboard),
    onNavigateToTasks: () =>
        _replaceWith(context, AppRoutes.maintenanceAssignedTasks),
    onNotificationsTap: () =>
        Navigator.of(context).pushNamed(AppRoutes.maintenanceNotifications),
    onChangePassword: () =>
        Navigator.of(context).pushNamed(AppRoutes.changePassword),
    onAbout: () => Navigator.of(context).pushNamed(AppRoutes.about),
    onLogOut: () => signOut(context),
    onSaveProfile: (fullName) async {
      try {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        if (token == null) return false;
        final json = await ApiClient.instance.updateProfile(
          idToken: token,
          fullName: fullName,
        );
        MaintenanceSession.instance.updateProfile(
          fullName: json['fullName'] as String? ?? fullName,
        );
        return true;
      } catch (_) {
        return false;
      }
    },
  );
}

Widget _maintenanceNotifications(BuildContext context) {
  return MaintenanceNotificationsScreen(
    onBack: () => Navigator.of(context).maybePop(),
    onOpenTask: (taskId) => _pushMaintenanceTaskDetails(context, taskId),
  );
}

void _pushMaintenanceTaskDetails(BuildContext context, String taskId) {
  final route = Uri(
    path: AppRoutes.maintenanceTaskDetails,
    queryParameters: {'taskId': taskId},
  ).toString();
  Navigator.of(context).pushNamed(route);
}

void _pushMaintenanceUpdateProgress(BuildContext context, String taskId) {
  final route = Uri(
    path: AppRoutes.maintenanceUpdateProgress,
    queryParameters: {'taskId': taskId},
  ).toString();
  Navigator.of(context).pushNamed(route);
}

void _pushMaintenanceTaskCompleted(BuildContext context, String taskId) {
  final route = Uri(
    path: AppRoutes.maintenanceTaskCompleted,
    queryParameters: {'taskId': taskId},
  ).toString();
  Navigator.of(context).pushReplacementNamed(route);
}

MaintenanceTask _maintenanceTaskFromSettings(RouteSettings? settings) {
  final tasks = MaintenanceTaskDirectory.instance.tasks.value;
  final uri = Uri.tryParse(settings?.name ?? '');
  final taskId = uri?.queryParameters['taskId'];
  if (taskId != null) {
    for (final task in tasks) {
      if (task.id == taskId) return task;
    }
  }
  return tasks.first;
}
