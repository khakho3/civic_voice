import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/detail_header.dart';

/// An intentionally unavailable Admin inbox until F07 supplies a durable,
/// server-authorized notification source and safe deep-link contract.
///
/// Do not derive account events from [AdminUserDirectory] here. A user list is
/// neither an audit/event stream nor a verified notification scope, and using
/// it could disclose another assembly's users through a notification route.
class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key, this.onBack, this.onOpenUser});

  final VoidCallback? onBack;

  /// Retained for route-call compatibility while Admin notification deep links
  /// are unavailable. This screen deliberately never invokes it.
  final ValueChanged<String>? onOpenUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const AppStateMessage(
              icon: AppIcons.notificationsOff,
              title: 'Admin notifications unavailable',
              message:
                  'Notifications will appear here when the secure Admin '
                  'notification service is available.',
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Admin Notifications',
              onBack: onBack,
            ),
          ),
        ],
      ),
    );
  }
}
