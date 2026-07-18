import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';
import '../widgets/maintenance_scaffold.dart';

/// MNT-001 — Maintenance Team Dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToTasks,
    this.onNavigateToProfile,
    this.onNotificationsTap,
    this.onOpenTaskDetails,
  });

  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToProfile;

  /// Opens Maintenance Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens Task Details for the tapped task, by [MaintenanceTask.id] — each
  /// row now opens the specific task it represents, rather than every row
  /// (and "View All") landing on the same static Task Details content
  /// regardless of which task was tapped.
  final ValueChanged<String>? onOpenTaskDetails;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppScreenState _state = AppScreenState.success;

  @override
  Widget build(BuildContext context) {
    return MaintenanceScaffold(
      selectedTab: MaintenanceTab.dashboard,
      onNotificationsTap: widget.onNotificationsTap,
      onProfileTap: widget.onNavigateToProfile,
      onTabSelected: (tab) {
        if (tab == MaintenanceTab.tasks) widget.onNavigateToTasks?.call();
        if (tab == MaintenanceTab.profile) widget.onNavigateToProfile?.call();
      },
      body: ValueListenableBuilder<List<MaintenanceTask>>(
        valueListenable: MaintenanceTaskDirectory.instance.tasks,
        builder: (context, tasks, _) => _buildBody(context, tasks),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<MaintenanceTask> tasks) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(
          onRefresh: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.error:
        return _ErrorView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.offline:
        return _OfflineView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.permission:
        return const _PermissionView();
      case AppScreenState.disabled:
      case AppScreenState.success:
        final dashboardData = _MaintenanceDashboardData.fromTasks(tasks);
        return _DashboardContent(
          data: dashboardData,
          disabled: _state == AppScreenState.disabled,
          onViewAllTasks: widget.onNavigateToTasks,
          onOpenTaskDetails: widget.onOpenTaskDetails,
        );
    }
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.data,
    required this.disabled,
    required this.onViewAllTasks,
    required this.onOpenTaskDetails,
  });

  final _MaintenanceDashboardData data;
  final bool disabled;
  final VoidCallback? onViewAllTasks;
  final ValueChanged<String>? onOpenTaskDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final chromeInset = MaintenanceScaffold.contentPadding(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: IgnorePointer(
          ignoring: disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good Morning, Yaw',
                      style: textTheme.headlineSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filledTonal(
                    onPressed: onViewAllTasks,
                    icon: const Icon(AppIcons.calendar),
                    tooltip: 'Open task schedule',
                  ),
                ],
              ),
              Text(
                'Today\'s maintenance pulse is ready.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  mainAxisExtent: 132,
                ),
                children: [
                  _StatCard(
                    icon: AppIcons.task,
                    label: 'Assigned Tasks',
                    value: '${data.assignedCount}',
                    accentColor: colorScheme.primary,
                  ),
                  _StatCard(
                    icon: AppIcons.activityPulse,
                    label: 'Active Work',
                    value: '${data.activeCount}',
                    accentColor: semantic.statusInProgress,
                  ),
                  _StatCard(
                    icon: AppIcons.statusResolved,
                    label: 'Completed',
                    value: '${data.completedCount}',
                    accentColor: semantic.success,
                  ),
                  _StatCard(
                    icon: AppIcons.statusRejected,
                    label: 'Needs Rework',
                    value: '${data.failedCount}',
                    accentColor: semantic.error,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _WeeklyCompletionCard(data: data),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Scheduled Work',
                      style: textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: onViewAllTasks,
                    child: const Text('View All'),
                  ),
                ],
              ),
              ...data.scheduledTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskListTile(
                    task: task,
                    onTap: onOpenTaskDetails == null
                        ? null
                        : () => onOpenTaskDetails!(task.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.lg,
            height: AppIconSize.lg,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.allSm,
            ),
            child: Icon(icon, size: AppIconSize.sm + 2, color: accentColor),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineSmall,
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyCompletionCard extends StatelessWidget {
  const _WeeklyCompletionCard({required this.data});

  final _MaintenanceDashboardData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final onPrimary = colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, semantic.statusAssigned],
        ),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weekly Completion',
                  style: textTheme.titleMedium?.copyWith(color: onPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.16),
                  borderRadius: AppRadius.allXs,
                ),
                child: Icon(
                  AppIcons.analytics,
                  size: AppIconSize.sm,
                  color: onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${data.weeklyCompletedTotal} tasks completed this week',
            style: textTheme.bodySmall?.copyWith(
              color: onPrimary.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _DiscoveryBars(
            counts: data.weeklyCompletionCounts,
            height: MediaQuery.sizeOf(context).width < 360
                ? AppSpacing.xxxxl + AppSpacing.lg
                : AppSpacing.xxxxl + AppSpacing.xxl,
          ),
        ],
      ),
    );
  }
}

class _DiscoveryBars extends StatelessWidget {
  const _DiscoveryBars({required this.counts, required this.height});

  final List<int> counts;
  final double height;

  static const List<String> _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final barColors = [
      semantic.success,
      colorScheme.primaryContainer,
      semantic.warning,
      colorScheme.onPrimary,
      semantic.statusInProgress,
      semantic.success,
      colorScheme.primaryContainer,
    ];

    final maxBarHeight = height - AppSpacing.xxl;
    final maxCount = counts.fold<int>(
      1,
      (largest, count) => count > largest ? count : largest,
    );

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_labels.length, (index) {
          final count = index < counts.length ? counts[index] : 0;
          final normalized = count / maxCount;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: AppSpacing.sm,
                  height: AppSpacing.xs + (normalized * maxBarHeight),
                  decoration: BoxDecoration(
                    color: barColors[index],
                    borderRadius: AppRadius.allXs,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _labels[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({required this.task, required this.onTap});

  final MaintenanceTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(AppIcons.location, color: colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                Text(
                  task.locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TintedBadge(
            label: task.status.label,
            color: task.status.color,
            textColor: task.status.badgeTextColor(brightness),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.empty,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No assigned work yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned tasks will appear here after dispatch updates your queue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRefresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again without changing your maintenance assignments.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.error),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned tasks will sync once you reconnect.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.permissionDenied,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in with your maintenance credentials to view assigned work.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MaintenanceDashboardData {
  const _MaintenanceDashboardData({
    required this.assignedCount,
    required this.activeCount,
    required this.completedCount,
    required this.failedCount,
    required this.weeklyCompletionCounts,
    required this.scheduledTasks,
  });

  final int assignedCount;
  final int activeCount;
  final int completedCount;
  final int failedCount;
  final List<int> weeklyCompletionCounts;
  final List<MaintenanceTask> scheduledTasks;

  int get weeklyCompletedTotal =>
      weeklyCompletionCounts.fold<int>(0, (total, count) => total + count);

  factory _MaintenanceDashboardData.fromTasks(List<MaintenanceTask> tasks) {
    final weeklyCounts = List<int>.filled(7, 0);
    for (final task in tasks) {
      final weekday = task.completedWeekday;
      if (task.status == MaintenanceTaskStatus.completed &&
          weekday != null &&
          weekday >= 0 &&
          weekday < weeklyCounts.length) {
        weeklyCounts[weekday] += 1;
      }
    }

    final scheduledTasks = tasks
        .where(
          (task) =>
              task.status != MaintenanceTaskStatus.completed &&
              task.status != MaintenanceTaskStatus.failed,
        )
        .take(3)
        .toList(growable: false);

    return _MaintenanceDashboardData(
      assignedCount: tasks
          .where(
            (task) =>
                task.status != MaintenanceTaskStatus.completed &&
                task.status != MaintenanceTaskStatus.failed,
          )
          .length,
      activeCount: tasks
          .where((task) => task.status == MaintenanceTaskStatus.inProgress)
          .length,
      completedCount: tasks
          .where((task) => task.status == MaintenanceTaskStatus.completed)
          .length,
      failedCount: tasks
          .where((task) => task.status == MaintenanceTaskStatus.failed)
          .length,
      weeklyCompletionCounts: List<int>.unmodifiable(weeklyCounts),
      scheduledTasks: scheduledTasks,
    );
  }
}
