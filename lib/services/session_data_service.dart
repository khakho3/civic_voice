import '../features/admin/models/admin_system_settings_data.dart';
import '../features/admin/services/admin_maintenance_team_directory.dart';
import '../features/admin/services/admin_system_activity_directory.dart';
import '../features/admin/services/admin_system_settings_directory.dart';
import '../features/admin/services/admin_user_directory.dart';
import '../features/citizen/services/dashboard_state_service.dart';
import '../features/citizen/services/profile_crud_service.dart';
import '../features/citizen/services/report_crud_service.dart';
import '../features/maintenance/services/maintenance_session.dart';
import '../features/maintenance/services/maintenance_task_directory.dart';
import '../features/ministry/services/ministry_data_directory.dart';
import '../features/ministry/services/ministry_session.dart';
import '../features/municipal/services/municipal_report_directory.dart';
import '../features/municipal/services/municipal_session.dart';
import 'app_cache_service.dart';
import 'notification_directory.dart';

abstract final class SessionDataService {
  static void clear() {
    ReportCrudService.instance.clearSession();
    ProfileCrudService.instance.clearSession();
    DashboardStateService.instance.reset();

    MunicipalReportDirectory.instance.reports.value = const [];
    MunicipalReportDirectory.instance.loading.value = false;
    MunicipalReportDirectory.instance.error.value = null;
    MunicipalReportDirectory.instance.hasLiveSnapshot = false;
    MunicipalSession.instance.clearSession();

    MaintenanceTaskDirectory.instance.tasks.value = const [];
    MaintenanceTaskDirectory.instance.loading.value = false;
    MaintenanceTaskDirectory.instance.error.value = null;
    MaintenanceTaskDirectory.instance.hasLiveSnapshot = false;
    MaintenanceSession.instance.clearSession();
    MaintenanceTeamDirectory.instance.teams.value = const [];

    MinistryDataDirectory.instance.clearSession();
    MinistrySession.instance.clearSession();

    AdminUserDirectory.instance.users.value = const [];
    AdminUserDirectory.instance.loading.value = false;
    AdminUserDirectory.instance.error.value = null;
    AdminUserDirectory.instance.hasLiveSnapshot = false;
    AdminUserDirectory.instance.currentApiUserId = null;
    AdminSystemActivityDirectory.instance.items.value = const [];
    AdminSystemActivityDirectory.instance.health.value = null;
    AdminSystemActivityDirectory.instance.loading.value = false;
    AdminSystemActivityDirectory.instance.error.value = null;
    AdminSystemActivityDirectory.instance.hasLiveSnapshot = false;
    AdminSystemSettingsDirectory.instance.settings.value =
        const SystemSettingsData(
          maintenanceMode: false,
          sessionTimeout: '30 minutes',
          auditLogging: true,
          publicStatusPage: false,
          allowNewAccountCreation: false,
        );
    AdminSystemSettingsDirectory.instance.loading.value = false;
    AdminSystemSettingsDirectory.instance.error.value = null;
    AdminSystemSettingsDirectory.instance.hasLiveSnapshot = false;

    NotificationDirectory.instance.clearSession();
    AppCacheService.instance.clearSession();
  }
}
