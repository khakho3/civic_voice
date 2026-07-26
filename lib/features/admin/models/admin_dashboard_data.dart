import '../services/admin_user_directory.dart';
import '../services/admin_system_activity_directory.dart';
import 'admin_system_activity_data.dart';
import 'admin_user_management_data.dart';

/// The four Platform Overview stat cards.
class AdminDashboardStats {
  const AdminDashboardStats({
    required this.totalUsers,
    required this.totalUsersChangePercent,
    required this.activeRoles,
    required this.activeRolesChangePercent,
    required this.adminActionsLabel,
    required this.openAlerts,
  });

  final int totalUsers;
  final num totalUsersChangePercent;
  final int activeRoles;
  final num activeRolesChangePercent;

  /// e.g. "1.8k" — Admin Actions has no percent delta in the approved
  /// frame, just a "24h" window label, so this is pre-formatted text rather
  /// than a number + separate delta pair like the other three cards.
  final String adminActionsLabel;
  final int openAlerts;
}

/// One row in the "Activity Monitoring" audit log.
class AdminActivityItem {
  const AdminActivityItem({required this.title, required this.caption});

  final String title;

  /// e.g. "Audit log · read-only".
  final String caption;
}

/// Data backing ADM-001 Admin Dashboard's loaded state.
class AdminDashboardData {
  const AdminDashboardData({required this.stats, required this.activity});

  final AdminDashboardStats stats;
  final List<AdminActivityItem> activity;

  /// Placeholder content matching the approved ADM-001 design, used until
  /// the Cloud Firestore-backed aggregation service (Issue 05 dependency)
  /// is wired up.
  static AdminDashboardData mock() {
    return const AdminDashboardData(
      stats: AdminDashboardStats(
        totalUsers: 12400,
        totalUsersChangePercent: 4.2,
        activeRoles: 48,
        activeRolesChangePercent: 2.1,
        adminActionsLabel: '1.8k',
        openAlerts: 12,
      ),
      activity: [
        AdminActivityItem(
          title: 'Role permission updated',
          caption: 'Audit log · read-only',
        ),
        AdminActivityItem(
          title: 'New admin account approved',
          caption: 'Audit log · read-only',
        ),
        AdminActivityItem(
          title: 'System policy reviewed',
          caption: 'Audit log · read-only',
        ),
      ],
    );
  }

  static AdminDashboardData current() {
    final users = AdminUserDirectory.instance.users.value;
    final activeUsers = users
        .where((user) => user.status == AdminUserStatus.active)
        .toList();
    final auditItems = AdminSystemActivityDirectory.instance.items.value;
    final recentAuditItems = auditItems
        .where(
          (item) =>
              DateTime.now().difference(item.timestamp) <=
              const Duration(hours: 24),
        )
        .toList();
    return AdminDashboardData(
      stats: AdminDashboardStats(
        totalUsers: users.length,
        totalUsersChangePercent: 0,
        activeRoles: activeUsers.map((user) => user.role).toSet().length,
        activeRolesChangePercent: 0,
        adminActionsLabel: '${recentAuditItems.length}',
        openAlerts: auditItems
            .where(
              (item) =>
                  item.severity == ActivitySeverity.alert ||
                  item.severity == ActivitySeverity.critical,
            )
            .length,
      ),
      activity: [
        for (final item in auditItems.take(3))
          AdminActivityItem(
            title: item.title,
            caption: '${item.tag} · ${item.severity.label}',
          ),
      ],
    );
  }
}
