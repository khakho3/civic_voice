import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../models/notification_item.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/notification_list_view.dart';
import '../../municipal/services/municipal_report_directory.dart';

/// Ministry Supervisor's Notifications — reached via the bell icon on every
/// Ministry screen. Nationally-resolved reports are the only notification
/// type this module currently generates (see
/// `NotificationDirectory.forMinistry`) — opening this screen marks them
/// all read.
class MinistryNotificationsScreen extends StatefulWidget {
  const MinistryNotificationsScreen({
    super.key,
    this.onBack,
    this.onNotificationTap,
  });

  final VoidCallback? onBack;
  final ValueChanged<NotificationItem>? onNotificationTap;

  @override
  State<MinistryNotificationsScreen> createState() =>
      _MinistryNotificationsScreenState();
}

class _MinistryNotificationsScreenState
    extends State<MinistryNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationDirectory.instance.markAllRead(
      NotificationDirectory.instance.forMinistry().map((n) => n.id),
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
                MunicipalReportDirectory.instance.reports,
                NotificationDirectory.instance.readIds,
              ]),
              builder: (context, _) {
                final notifications = NotificationDirectory.instance
                    .forMinistry();
                return NotificationListView(
                  notifications: notifications,
                  emptyTitle: 'No notifications yet',
                  emptyMessage:
                      'Nationally resolved reports will appear '
                      'here.',
                  onTap: widget.onNotificationTap,
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    DetailHeader.topInset(context) + AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
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
