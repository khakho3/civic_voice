import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/notification_item.dart';
import '../services/notification_directory.dart';
import 'glass_card.dart';

/// Shared notification list content for Municipal, Maintenance, and
/// Ministry's own notification screens — Citizen keeps its own richer,
/// design-system-specific card (a deliberate split, not an oversight; see
/// `citizen_alerts_screen.dart`). Tapping a card marks it read and, if
/// [onTap] is given, navigates to whatever it's about.
class NotificationListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return _EmptyState(title: emptyTitle, message: emptyMessage);
    }
    return ListView.separated(
      // Stays draggable even when a short list fits the viewport — same
      // fix already applied to every other list screen in this app.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      itemCount: notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            NotificationDirectory.instance.markRead(notification.id);
            onTap?.call(notification);
          },
        );
      },
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
