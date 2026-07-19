import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_theme.dart';
import '../models/notification_item.dart';
import '../services/notification_directory.dart';
import '../features/citizen/services/notification_permission_service.dart';
import 'glass_card.dart';

/// Shared notification list content for Municipal, Maintenance, and
/// Ministry's own notification screens — Citizen keeps its own richer,
/// design-system-specific card (a deliberate split, not an oversight; see
/// `citizen_alerts_screen.dart`). Tapping a card marks it read and, if
/// [onTap] is given, navigates to whatever it's about.
class NotificationListView extends StatefulWidget {
  const NotificationListView({
    super.key,
    required this.notifications,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onTap,
    this.padding,
  });

  final List<NotificationItem> notifications;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<NotificationItem>? onTap;
  final EdgeInsets? padding;

  @override
  State<NotificationListView> createState() => _NotificationListViewState();
}

class _NotificationListViewState extends State<NotificationListView>
    with WidgetsBindingObserver {
  final _permissionService = const NotificationPermissionService();
  PermissionStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    try {
      final status = await _permissionService.currentStatus();
      if (mounted) setState(() => _permissionStatus = status);
    } catch (_) {}
  }

  Future<void> _enableNotifications() async {
    final current = _permissionStatus;
    if (current?.isPermanentlyDenied == true) {
      await _permissionService.openSettings();
    } else {
      await _permissionService.requestOnce();
    }
    await _refreshPermission();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = widget.notifications;
    final padding = widget.padding ?? const EdgeInsets.all(AppSpacing.md);
    return ListView(
      // Stays draggable even when a short list fits the viewport — same
      // fix already applied to every other list screen in this app.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (_permissionStatus != null && !_permissionStatus!.isGranted) ...[
          _PermissionBanner(
            settingsRequired: _permissionStatus!.isPermanentlyDenied,
            onPressed: _enableNotifications,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (notifications.isEmpty)
          _EmptyState(title: widget.emptyTitle, message: widget.emptyMessage)
        else
          for (var index = 0; index < notifications.length; index++) ...[
            _NotificationCard(
              notification: notifications[index],
              onTap: () {
                final notification = notifications[index];
                NotificationDirectory.instance.markRead(notification.id);
                widget.onTap?.call(notification);
              },
            ),
            if (index != notifications.length - 1)
              const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.settingsRequired,
    required this.onPressed,
  });

  final bool settingsRequired;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(AppIcons.notifications, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'OS notifications are off. Enable them to receive updates '
              'when CivicVoice is closed.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: onPressed,
            child: Text(settingsRequired ? 'Settings' : 'Enable'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onTap});

  final NotificationItem notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notification.read;

    return GlassCard(
      onTap: onTap,
      border: isUnread
          ? Border.all(color: notification.color.withValues(alpha: 0.4))
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.xl,
            height: AppIconSize.xl,
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      notification.timeLabel,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: notification.color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.allXl,
                  ),
                  child: Text(
                    notification.category,
                    style: textTheme.labelSmall?.copyWith(
                      color: notification.color,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.notifications,
                color: AppColors.primary,
                size: AppIconSize.lg,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
