import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-001 — Maintenance Team Dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onNavigateToTasks,
    this.onNavigateToProfile,
    this.onOpenTaskDetails,
  });

  final VoidCallback? onNavigateToTasks;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onOpenTaskDetails;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppScreenState _state = AppScreenState.success;

  final List<_TaskPreview> _tasks = const [
    _TaskPreview(
      title: 'Broken Street Light at Main Ave',
      location: '242 Main Avenue, Central District',
      status: _MaintenanceTaskStatus.inProgress,
      evidenceRequired: true,
      completedWeekday: null,
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Pothole Repair Request',
      location: 'Elm Street & 4th Cross',
      status: _MaintenanceTaskStatus.assigned,
      evidenceRequired: false,
      completedWeekday: null,
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Oak St Pothole',
      location: '1242 Oak Street, Downtown',
      status: _MaintenanceTaskStatus.assigned,
      evidenceRequired: false,
      completedWeekday: null,
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Hydrant Maintenance',
      location: 'West Park Perimeter',
      status: _MaintenanceTaskStatus.completed,
      evidenceRequired: false,
      completedWeekday: 4,
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Street Light Follow-up',
      location: 'Maple Ave & 5th Crossing',
      status: _MaintenanceTaskStatus.completed,
      evidenceRequired: false,
      completedWeekday: 2,
      icon: AppIcons.location,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivicVoice'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.notifications),
            tooltip: 'Notifications',
            onPressed: widget.onNavigateToTasks,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 1) {
            widget.onNavigateToTasks?.call();
          } else if (index == 2) {
            widget.onNavigateToProfile?.call();
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
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
        final dashboardData = _MaintenanceDashboardData.fromTasks(_tasks);
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
  final VoidCallback? onOpenTaskDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
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
                      'Good Morning, Marcus',
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
              const SizedBox(height: AppSpacing.lg),
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
                    tag: 'Open',
                  ),
                  _StatCard(
                    icon: AppIcons.statusInProgress,
                    label: 'Active Work',
                    value: '${data.activeCount}',
                    accentColor: semantic.statusInProgress,
                    tag: 'In Progress',
                  ),
                  _StatCard(
                    icon: AppIcons.statusResolved,
                    label: 'Completed',
                    value: '${data.completedCount}',
                    accentColor: semantic.success,
                    tag: 'Resolved',
                  ),
                  _StatCard(
                    icon: AppIcons.camera,
                    label: 'Evidence Queue',
                    value: '${data.evidenceQueueCount}',
                    accentColor: semantic.warning,
                    tag: 'Pending',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _WeeklyCompletionCard(data: data),
              const SizedBox(height: AppSpacing.lg),
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
                  child: _TaskListTile(task: task, onTap: onOpenTaskDetails),
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
    this.tag,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.allXs,
                  ),
                  child: Icon(icon, size: AppIconSize.sm, color: accentColor),
                ),
                if (tag != null)
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.xxxxl + AppSpacing.xl,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.allXs,
                    ),
                    child: Text(
                      tag!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelSmall?.copyWith(color: accentColor),
                    ),
                  ),
              ],
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

  final _TaskPreview task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(task.icon, color: colorScheme.primary),
        ),
        title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${task.location} - ${task.status.label}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: SizedBox(
          width: 104,
          child: Align(
            alignment: Alignment.centerRight,
            child: _StatusBadge(
              label: task.status.label,
              color: task.status.color,
              icon: task.status.icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: color),
            ),
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

enum _MaintenanceTaskStatus {
  assigned,
  inProgress,
  completed;

  String get label {
    switch (this) {
      case _MaintenanceTaskStatus.assigned:
        return 'Assigned';
      case _MaintenanceTaskStatus.inProgress:
        return 'In Progress';
      case _MaintenanceTaskStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case _MaintenanceTaskStatus.assigned:
        return AppColors.statusAssigned;
      case _MaintenanceTaskStatus.inProgress:
        return AppColors.statusInProgress;
      case _MaintenanceTaskStatus.completed:
        return AppColors.statusResolved;
    }
  }

  IconData get icon {
    switch (this) {
      case _MaintenanceTaskStatus.assigned:
        return AppIcons.statusAssigned;
      case _MaintenanceTaskStatus.inProgress:
        return AppIcons.statusInProgress;
      case _MaintenanceTaskStatus.completed:
        return AppIcons.statusResolved;
    }
  }
}

class _MaintenanceDashboardData {
  const _MaintenanceDashboardData({
    required this.assignedCount,
    required this.activeCount,
    required this.completedCount,
    required this.evidenceQueueCount,
    required this.weeklyCompletionCounts,
    required this.scheduledTasks,
  });

  final int assignedCount;
  final int activeCount;
  final int completedCount;
  final int evidenceQueueCount;
  final List<int> weeklyCompletionCounts;
  final List<_TaskPreview> scheduledTasks;

  int get weeklyCompletedTotal =>
      weeklyCompletionCounts.fold<int>(0, (total, count) => total + count);

  factory _MaintenanceDashboardData.fromTasks(List<_TaskPreview> tasks) {
    final weeklyCounts = List<int>.filled(7, 0);
    for (final task in tasks) {
      final weekday = task.completedWeekday;
      if (task.status == _MaintenanceTaskStatus.completed &&
          weekday != null &&
          weekday >= 0 &&
          weekday < weeklyCounts.length) {
        weeklyCounts[weekday] += 1;
      }
    }

    final scheduledTasks = tasks
        .where((task) => task.status != _MaintenanceTaskStatus.completed)
        .take(3)
        .toList(growable: false);

    return _MaintenanceDashboardData(
      assignedCount: tasks
          .where((task) => task.status != _MaintenanceTaskStatus.completed)
          .length,
      activeCount: tasks
          .where((task) => task.status == _MaintenanceTaskStatus.inProgress)
          .length,
      completedCount: tasks
          .where((task) => task.status == _MaintenanceTaskStatus.completed)
          .length,
      evidenceQueueCount: tasks
          .where(
            (task) =>
                task.evidenceRequired &&
                task.status != _MaintenanceTaskStatus.completed,
          )
          .length,
      weeklyCompletionCounts: List<int>.unmodifiable(weeklyCounts),
      scheduledTasks: scheduledTasks,
    );
  }
}

class _TaskPreview {
  const _TaskPreview({
    required this.title,
    required this.location,
    required this.status,
    required this.evidenceRequired,
    required this.completedWeekday,
    required this.icon,
  });
  final String title;
  final String location;
  final _MaintenanceTaskStatus status;
  final bool evidenceRequired;
  final int? completedWeekday;
  final IconData icon;
}
