import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/notification_directory.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/notification_list_view.dart';
import '../services/municipal_report_directory.dart';

/// Municipal Officer notifications for new reports, maintenance progress,
/// resolutions, and field escalations within the officer's assembly.
class MunicipalNotificationsScreen extends StatefulWidget {
  const MunicipalNotificationsScreen({
    super.key,
    this.onBack,
    this.onOpenReport,
  });

  final VoidCallback? onBack;

  /// Opens Report Review (MUN-003) for the tapped notification's report.
  final ValueChanged<String>? onOpenReport;

  @override
  State<MunicipalNotificationsScreen> createState() =>
      _MunicipalNotificationsScreenState();
}

class _MunicipalNotificationsScreenState
    extends State<MunicipalNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    NotificationDirectory.instance.markAllRead(
      NotificationDirectory.instance.forMunicipal().map((n) => n.id),
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
                NotificationDirectory.instance.dismissedIds,
              ]),
              builder: (context, _) {
                final notifications = NotificationDirectory.instance
                    .forMunicipal();
                return NotificationListView(
                  notifications: notifications,
                  emptyTitle: 'No notifications yet',
                  emptyMessage:
                      'Report and maintenance updates will appear here.',
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    DetailHeader.topInset(context) + AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  onTap: (notification) {
                    final referenceId = notification.referenceId;
                    if (referenceId != null) {
                      widget.onOpenReport?.call(referenceId);
                    }
                  },
                  onClearAll: () => NotificationDirectory.instance.clearAll(
                    notifications.map((n) => n.id),
                  ),
                  onRefresh: MunicipalReportDirectory.instance.refresh,
                  topOffset: DetailHeader.topInset(context),
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
