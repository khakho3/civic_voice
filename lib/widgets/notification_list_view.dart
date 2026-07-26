import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/ghana_refresh_indicator.dart';
import '../models/notification_item.dart';
import '../services/notification_directory.dart';
import '../features/citizen/services/notification_permission_service.dart';
import 'app_state_message.dart';
import 'glass_card.dart';

/// Shared notification list content for every module's notification
/// screen (Admin, Municipal, Maintenance, Ministry, and Citizen Alerts).
/// Tapping a card marks it read and, if [onTap] is given, navigates to
/// whatever it's about.
class NotificationListView extends StatefulWidget {
  const NotificationListView({
    super.key,
    required this.notifications,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onTap,
    this.padding,
    this.onClearAll,
    this.onRefresh,
    this.topOffset = 0.0,
  });

  final List<NotificationItem> notifications;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<NotificationItem>? onTap;
  final EdgeInsets? padding;

  /// When given, a right-aligned "Clear all" button appears above the list
  /// whenever it's non-empty — dismisses every currently-visible
  /// notification (see `NotificationDirectory.clearAll`'s own doc comment
  /// for why this can't be a real delete). Null hides the button entirely.
  final VoidCallback? onClearAll;

  /// When given, wraps the list in [GhanaRefreshIndicator] — one wiring
  /// point here covers pull-to-refresh for every module's notification
  /// screen at once, each passing whatever directory actually backs its
  /// own notifications (see each screen's own call site). Null (e.g. a
  /// caller with nothing meaningful to re-sync) leaves plain scrolling.
  final Future<void> Function()? onRefresh;

  /// [GhanaRefreshIndicator.topOffset] — each caller's own fixed header
  /// paints on top of this list, so this needs the *raw* header inset
  /// (e.g. `DetailHeader.topInset(context)`), not [padding]'s top value.
  /// [padding] deliberately adds extra breathing room on top of that same
  /// inset for the list content itself; reusing it here previously pushed
  /// the star/bar down by that same extra amount, past where the header
  /// actually ends, unlike every other screen's pull-to-refresh.
  final double topOffset;

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
    // A permission problem is its own exclusive state — same rule as every
    // other Permission-state screen in the app (e.g. Municipal Report
    // Review's "Access Restricted"), never stacked with Empty/loaded
    // content underneath it.
    final permissionBlocked =
        _permissionStatus != null && !_permissionStatus!.isGranted;
    final list = ListView(
      // Stays draggable even when a short list fits the viewport — same
      // fix already applied to every other list screen in this app.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (permissionBlocked)
          _PermissionBanner(
            settingsRequired: _permissionStatus!.isPermanentlyDenied,
            onPressed: _enableNotifications,
          )
        else ...[
          if (widget.onClearAll != null && notifications.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onClearAll,
                child: const Text('Clear all'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (notifications.isEmpty)
            _EmptyState(title: widget.emptyTitle, message: widget.emptyMessage)
          else
            for (var index = 0; index < notifications.length; index++) ...[
              Dismissible(
                key: ValueKey(notifications[index].id),
                direction: DismissDirection.endToStart,
                background: const _DismissBackground(),
                // Same dismissal ledger "Clear all" uses — a single-id
                // clearAll, not a second delete mechanism. If the underlying
                // report/task/account later changes status, a fresh id is
                // minted and the notification can reappear, same as Clear all.
                onDismissed: (_) {
                  NotificationDirectory.instance.clearAll([
                    notifications[index].id,
                  ]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification deleted')),
                  );
                },
                child: _NotificationCard(
                  notification: notifications[index],
                  onTap: () {
                    final notification = notifications[index];
                    NotificationDirectory.instance.markRead(notification.id);
                    widget.onTap?.call(notification);
                  },
                ),
              ),
              if (index != notifications.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ],
    );
    final onRefresh = widget.onRefresh;
    if (onRefresh == null) return list;
    return GhanaRefreshIndicator(
      onRefresh: onRefresh,
      // Every caller's own header paints on top of this list (a later
      // sibling in that screen's own Stack), so without this the pull
      // indicator would grow in from behind it.
      topOffset: widget.topOffset,
      child: list,
    );
  }
}

/// Same icon-badge/title/message/action shape as [AppStateMessage]'s other
/// uses across the app (e.g. Municipal Report Review's "Access Restricted"
/// state) — this screen's OS-notifications-off state is a permission state
/// too, so it gets the same visual mood instead of its own bespoke banner.
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.settingsRequired,
    required this.onPressed,
  });

  final bool settingsRequired;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppStateMessage(
      icon: AppIcons.notificationsOff,
      badgeColor: AppColors.warning,
      title: 'Notifications Are Off',
      message: 'Turn them on to get updates when CivicVoice is closed.',
      primaryActionLabel: settingsRequired ? 'Settings' : 'Enable',
      onPrimaryAction: onPressed,
      bordered: true,
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

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: AppComponentRadius.card,
      ),
      child: Icon(
        AppIcons.delete,
        color: AppColors.error,
        size: AppIconSize.standard,
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
