import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/notification_list_view.dart';
import '../../admin/services/admin_maintenance_team_directory.dart';
import '../services/maintenance_task_directory.dart';

/// Maintenance Team's Notifications — reached via the bell icon on every
/// Maintenance screen. New task assignments to the signed-in technician's
/// own team are the only notification type this module currently generates
/// (see `NotificationDirectory.forMaintenance`) — opening this screen marks
/// them all read, which is also what clears the Tasks tab's own "new stuff"
/// dot (the same underlying signal, just filtered per surface).
class MaintenanceNotificationsScreen extends StatefulWidget {
  const MaintenanceNotificationsScreen({
    super.key,
    this.onBack,
    this.onOpenTask,
  });

  final VoidCallback? onBack;

  /// Opens Task Details for the tapped notification's task.
  final ValueChanged<String>? onOpenTask;

  @override
  State<MaintenanceNotificationsScreen> createState() =>
      _MaintenanceNotificationsScreenState();
}

class _MaintenanceNotificationsScreenState
    extends State<MaintenanceNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationDirectory.instance.markAllRead(
      NotificationDirectory.instance.forMaintenance().map((n) => n.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                MaintenanceTaskDirectory.instance.tasks,
                MaintenanceTeamDirectory.instance.teams,
                NotificationDirectory.instance.readIds,
              ]),
              builder: (context, _) {
                final notifications = NotificationDirectory.instance
                    .forMaintenance();
                return NotificationListView(
                  notifications: notifications,
                  emptyTitle: 'No notifications yet',
                  emptyMessage: 'New task assignments will appear here.',
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    DetailHeader.topInset(context) + AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  onTap: (notification) {
                    final taskId = notification.referenceId;
                    if (taskId != null) widget.onOpenTask?.call(taskId);
                  },
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(title: 'Notifications', onBack: widget.onBack),
          ),
        ],
      ),
    );
  }
}
