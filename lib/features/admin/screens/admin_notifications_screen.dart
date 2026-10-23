import 'package:firebase_core/firebase_core.dart';
import '../../../models/app_role.dart';
import '../../../widgets/notification_inbox_panel.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/detail_header.dart';

/// Server-authorized Admin updates. Account lists never become notifications.
class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key, this.onBack, this.onOpenUser});

  final VoidCallback? onBack;

  /// Retained for route-call compatibility. Live updates open verified Activity,
  /// rather than navigating to an arbitrary user from notification text.
  final ValueChanged<String>? onOpenUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Firebase.apps.isNotEmpty
                ? NotificationInboxPanel(
                    role: AppRole.systemAdministrator,
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      DetailHeader.topInset(context) + AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xl,
                    ),
                  )
                : const AppStateMessage(
                    icon: AppIcons.notificationsOff,
                    title: 'Admin notifications unavailable',
                    message:
                        'Notifications will appear here when the secure Admin '
                        'notification service is available.',
                  ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(title: 'Admin Notifications', onBack: onBack),
          ),
        ],
      ),
    );
  }
}
