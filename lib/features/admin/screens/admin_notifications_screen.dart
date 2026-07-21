import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/notification_list_view.dart';
import '../services/admin_user_directory.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key, this.onBack, this.onOpenUser});

  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenUser;

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationDirectory.instance.markAllRead(
      NotificationDirectory.instance.forAdmin().map((item) => item.id),
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
                AdminUserDirectory.instance.users,
                NotificationDirectory.instance.readIds,
                NotificationDirectory.instance.dismissedIds,
              ]),
              builder: (context, _) => NotificationListView(
                notifications: NotificationDirectory.instance.forAdmin(),
                emptyTitle: 'No admin notifications',
                emptyMessage: 'New and deactivated accounts will appear here.',
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  DetailHeader.topInset(context) + AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                onTap: (notification) {
                  final id = notification.referenceId;
                  if (id != null) widget.onOpenUser?.call(id);
                },
                onClearAll: () => NotificationDirectory.instance.clearAll(
                  NotificationDirectory.instance.forAdmin().map((n) => n.id),
                ),
                onRefresh: AdminUserDirectory.instance.refresh,
                topOffset: DetailHeader.topInset(context),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Admin Notifications',
              onBack: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}
