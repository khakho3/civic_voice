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

    MunicipalReportDirectory.instance.clearSession();
    MunicipalSession.instance.clearSession();

    MaintenanceTaskDirectory.instance.clearSession();
    MaintenanceSession.instance.clearSession();
    MaintenanceTeamDirectory.instance.invalidateAndClear();

    MinistryDataDirectory.instance.clearSession();
    MinistrySession.instance.clearSession();

    AdminUserDirectory.instance.invalidateAndClear();
    AdminSystemActivityDirectory.instance.invalidateAndClear();
    AdminSystemSettingsDirectory.instance.invalidateAndClear();

    NotificationDirectory.instance.clearSession();
    AppCacheService.instance.clearSession();
  }
}
