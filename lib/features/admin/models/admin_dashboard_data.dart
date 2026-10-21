import '../services/admin_session.dart';
import '../services/admin_system_activity_directory.dart';
import '../services/admin_user_directory.dart';
import 'admin_system_activity_data.dart';
import 'admin_user_management_data.dart';

/// Dashboard values are nullable when their authorized source has not yet
/// supplied a genuine snapshot. A null value is unavailable, never zero.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.activeRoles,
    required this.adminActions,
    required this.alertEvents,
  });

  final int? totalUsers;
  final int? activeRoles;
  final int? adminActions;
  final int? alertEvents;
}

/// A read-only dashboard preview row derived from authorized audit records.
class AdminActivityItem {
  const AdminActivityItem({required this.title, required this.caption});

  final String title;
  final String caption;
}

/// Data backing ADM-001 Admin Dashboard's loaded state.
class AdminDashboardData {
  const AdminDashboardData({
    required this.stats,
    required this.activity,
    required this.activityAvailable,
  });

  final AdminDashboardStats stats;
  final List<AdminActivityItem> activity;
  final bool activityAvailable;

  /// Builds only from independently authorized, live snapshots. Dashboard
  /// preview/mock directory contents are deliberately ignored.
  static AdminDashboardData current() {
    final userDirectory = AdminUserDirectory.instance;
    final activityDirectory = AdminSystemActivityDirectory.instance;
    final usersAvailable = userDirectory.hasLiveSnapshot;
    final activityAvailable = activityDirectory.hasLiveSnapshot;
    final visibleUsers = usersAvailable
        ? AdminSession.instance.visibleUsers(userDirectory.users.value)
        : const <AdminUserItem>[];
    final visibleActivity = activityAvailable
        ? AdminSession.instance.visibleActivity(activityDirectory.items.value)
        : const <ActivityItem>[];
    final recentActivity = visibleActivity
        .where(
          (item) =>
              DateTime.now().difference(item.timestamp) <=
              const Duration(hours: 24),
        )
        .toList();

    return AdminDashboardData(
      stats: AdminDashboardStats(
        totalUsers: usersAvailable ? visibleUsers.length : null,
        activeRoles: usersAvailable
            ? visibleUsers
                  .where((user) => user.status == AdminUserStatus.active)
                  .map((user) => user.role)
                  .toSet()
                  .length
            : null,
        adminActions: activityAvailable ? recentActivity.length : null,
        alertEvents: activityAvailable
            ? visibleActivity
                  .where(
                    (item) =>
                        item.severity == ActivitySeverity.alert ||
                        item.severity == ActivitySeverity.critical,
                  )
                  .length
            : null,
      ),
      activityAvailable: activityAvailable,
      activity: [
        for (final item in visibleActivity.take(3))
          AdminActivityItem(
            title: item.title,
            caption: '${item.tag} · ${item.severity.label}',
          ),
      ],
    );
  }
}
