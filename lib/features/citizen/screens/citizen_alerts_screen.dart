import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/notification_item.dart';
import '../../../services/notification_directory.dart';
import '../widgets/civic_glass_card.dart';
import '../services/report_crud_service.dart';
import '../widgets/civic_app_chrome.dart';
import 'citizen_profile_screen.dart';
import 'citizen_reports_screen.dart';
import 'create_report_screen.dart';
import 'report_tracking_screen.dart';

class CitizenAlertsScreen extends StatefulWidget {
  const CitizenAlertsScreen({super.key});

  static const String routeName = '/citizen/alerts';

  @override
  State<CitizenAlertsScreen> createState() => _CitizenAlertsScreenState();
}

class _CitizenAlertsScreenState extends State<CitizenAlertsScreen> {
  void _openDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openReports() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenReportsScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openCreateReport() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CreateReportScreen.routeName,
      (route) => route.isFirst,
    );
  }

  void _openProfile() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      CitizenProfileScreen.routeName,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = compact ? AppSpacing.sm : AppSpacing.md;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      // See create_report_screen.dart's build() for why this is false and
      // paired with the keyboardVisible-guarded nav below.
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                ReportCrudService.instance.reports,
                NotificationDirectory.instance.readIds,
              ]),
              builder: (context, _) {
                final notifications = NotificationDirectory.instance
                    .forCitizen();
                final unreadCount = notifications
                    .where((item) => !item.read)
                    .length;
                final readCount = notifications.length - unreadCount;
                final chromeInset = civicContentPadding(context);

                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    chromeInset.top + AppSpacing.lg,
                    horizontalPadding,
                    chromeInset.bottom + AppSpacing.lg,
                  ),
                  children: [
                    _NotificationSummary(
                      allCount: notifications.length,
                      unreadCount: unreadCount,
                      readCount: readCount,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Today',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (notifications.isEmpty)
                      const _NotificationEmptyState()
                    else
                      for (final notification in notifications) ...[
                        _NotificationCard(
                          notification: notification,
                          onMarkRead: () => NotificationDirectory.instance
                              .markRead(notification.id),
                          onViewReport: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReportTrackingScreen(
                                  reportId: notification.referenceId ?? '',
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                  ],
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(
              title: 'Notifications',
              showNotifications: false,
              onBack: _openDashboard,
            ),
          ),
          if (!keyboardVisible)
            Align(
              alignment: Alignment.bottomCenter,
              child: CivicBottomNav(
                selectedIndex: 3,
                onDestinationSelected: (index) {
                  if (index == 0) {
                    _openDashboard();
                  } else if (index == 1) {
                    _openReports();
                  } else if (index == 2) {
                    _openCreateReport();
                  } else if (index == 4) {
                    _openProfile();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.allCount,
    required this.unreadCount,
    required this.readCount,
  });

  final int allCount;
  final int unreadCount;
  final int readCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notification summary',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
              ),
              _UnreadBadge(count: unreadCount),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'All',
                  count: allCount,
                  selected: true,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(label: 'Unread', count: unreadCount),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryTile(label: 'Read', count: readCount),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        '$count unread',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    this.selected = false,
  });

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? Colors.white : theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : theme.colorScheme.surface,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: selected
              ? AppColors.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count.toString(),
            style: theme.textTheme.titleLarge?.copyWith(
              color: foreground,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkRead,
    required this.onViewReport,
  });

  final NotificationItem notification;
  final VoidCallback onMarkRead;
  final VoidCallback onViewReport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    return CivicGlassCard(
      borderRadius: AppRadius.allLg,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationIcon(notification: notification),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      notification.timeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const _UnreadDot(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  notification.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _NotificationTag(label: notification.category),
                    Text(
                      notification.referenceId ?? 'Reference pending',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isUnread ? onMarkRead : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: Text(isUnread ? 'Mark as Read' : 'Read'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: onViewReport,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: const Text('View Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationIcon extends StatelessWidget {
  const _NotificationIcon({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppIconSize.xl,
      height: AppIconSize.xl,
      decoration: BoxDecoration(
        color: notification.color.withValues(alpha: 0.1),
        borderRadius: AppRadius.allLg,
      ),
      child: Icon(notification.icon, color: notification.color),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationTag extends StatelessWidget {
  const _NotificationTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: AppFontWeight.bold,
        ),
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CivicGlassCard(
      borderRadius: AppRadius.allXl,
      child: Column(
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
          Text('No notifications yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Report updates will appear here after you submit a report.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
