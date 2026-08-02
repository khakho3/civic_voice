import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';
import '../widgets/maintenance_scaffold.dart';

/// MNT-002 — Maintenance Team Assigned Tasks.
class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToProfile,
    this.onNotificationsTap,
    this.onOpenTaskDetails,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToProfile;

  /// Opens Maintenance Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens Task Details for the tapped task, by [MaintenanceTask.id].
  final ValueChanged<String>? onOpenTaskDetails;

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  AppScreenState _state = AppScreenState.success;
  String _query = '';
  MaintenanceTaskStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    return MaintenanceScaffold(
      selectedTab: MaintenanceTab.tasks,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == MaintenanceTab.dashboard) {
          widget.onNavigateToDashboard?.call();
        }
        if (tab == MaintenanceTab.profile) widget.onNavigateToProfile?.call();
      },
      body: GhanaRefreshIndicator(
        onRefresh: MaintenanceTaskDirectory.instance.refresh,
        // The header paints on top of this body (a later sibling in
        // MaintenanceScaffold's own Stack), so without this the pull
        // indicator would grow in from behind it.
        topOffset: MaintenanceScaffold.contentPadding(context).top,
        child: ValueListenableBuilder<List<MaintenanceTask>>(
          valueListenable: MaintenanceTaskDirectory.instance.tasks,
          builder: (context, tasks, _) => _buildBody(context, tasks),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<MaintenanceTask> tasks) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(
          onRetry: () => setState(() => _state = AppScreenState.success),
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
        return _PermissionView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.disabled:
      case AppScreenState.success:
        // Open/active work only — completed and failed tasks have their own
        // read-only record (Task Completed / the task's own status on
        // Dashboard) rather than cluttering the working queue.
        final openTasks = tasks
            .where(
              (task) =>
                  task.status != MaintenanceTaskStatus.completed &&
                  task.status != MaintenanceTaskStatus.failed,
            )
            .toList(growable: false);
        return _AssignedTasksContent(
          tasks: openTasks,
          query: _query,
          statusFilter: _statusFilter,
          disabled: _state == AppScreenState.disabled,
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onOpenTaskDetails: widget.onOpenTaskDetails,
        );
    }
  }
}

class _AssignedTasksContent extends StatelessWidget {
  const _AssignedTasksContent({
    required this.tasks,
    required this.query,
    required this.statusFilter,
    required this.disabled,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onOpenTaskDetails,
  });

  final List<MaintenanceTask> tasks;
  final String query;
  final MaintenanceTaskStatus? statusFilter;
  final bool disabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<MaintenanceTaskStatus?> onStatusChanged;
  final ValueChanged<String>? onOpenTaskDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final chromeInset = MaintenanceScaffold.contentPadding(context);
    final filteredTasks = tasks
        .where((task) {
          final queryMatch = query.trim().isEmpty || task.matches(query);
          final statusMatch =
              statusFilter == null || task.status == statusFilter;
          return queryMatch && statusMatch;
        })
        .toList(growable: false);

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          // Stays draggable even when a short/filtered task list fits the
          // viewport — otherwise pull-to-refresh silently wouldn't trigger.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            chromeInset.top + AppSpacing.md,
            AppSpacing.md,
            chromeInset.bottom + AppSpacing.xl,
          ),
          children: [
            TextField(
              onChanged: onQueryChanged,
              // Glass — see MunicipalSearchField's doc comment.
              decoration: InputDecoration(
                filled: true,
                fillColor: semantic.glassSurface,
                hintText: 'Search assigned tasks...',
                prefixIcon: const Icon(AppIcons.search),
                border: OutlineInputBorder(
                  borderRadius: AppComponentRadius.inputField,
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _QueueOverview(tasks: tasks),
            const SizedBox(height: AppSpacing.md),
            _FilterRail(
              statusFilter: statusFilter,
              onStatusChanged: onStatusChanged,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Text('Queue', style: textTheme.titleMedium),
                const SizedBox(width: AppSpacing.sm),
                _CountPill(count: filteredTasks.length),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...filteredTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TaskCard(
                  task: task,
                  onOpenDetails: onOpenTaskDetails == null
                      ? null
                      : () => onOpenTaskDetails!(task.id),
                ),
              ),
            ),
            if (filteredTasks.isEmpty) const _NoMatchesCard(),
          ],
        ),
      ),
    );
  }
}

class _QueueOverview extends StatelessWidget {
  const _QueueOverview({required this.tasks});

  final List<MaintenanceTask> tasks;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final activeCount = tasks
        .where((task) => task.status == MaintenanceTaskStatus.inProgress)
        .length;
    final newCount = tasks
        .where((task) => task.status == MaintenanceTaskStatus.assigned)
        .length;

    return GlassCard(
      child: Row(
        children: [
          Expanded(
            child: _QueueMetric(
              icon: AppIcons.task,
              value: '${tasks.length}',
              label: 'Open',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: _QueueMetric(
              icon: AppIcons.activityPulse,
              value: '$activeCount',
              label: 'Active',
              color: semantic.statusInProgress,
            ),
          ),
          Expanded(
            child: _QueueMetric(
              icon: AppIcons.statusAssigned,
              value: '$newCount',
              label: 'New',
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueMetric extends StatelessWidget {
  const _QueueMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.allSm,
          ),
          child: Icon(icon, size: AppIconSize.md, color: color),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: textTheme.titleLarge),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.statusFilter,
    required this.onStatusChanged,
  });

  final MaintenanceTaskStatus? statusFilter;
  final ValueChanged<MaintenanceTaskStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusOptions = const [
      (null, 'All', AppIcons.filter),
      (MaintenanceTaskStatus.assigned, 'New', AppIcons.statusAssigned),
      (MaintenanceTaskStatus.inProgress, 'Active', AppIcons.activityPulse),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.inputField,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final option in statusOptions)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _CuteFilterPill(
                  icon: option.$3,
                  label: option.$2,
                  selected: statusFilter == option.$1,
                  onTap: () => onStatusChanged(option.$1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CuteFilterPill extends StatelessWidget {
  const _CuteFilterPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colorScheme.primary : colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppIconSize.sm,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(
        '$count',
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colorScheme.primary),
      ),
    );
  }
}

class _NoMatchesCard extends StatelessWidget {
  const _NoMatchesCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      child: Column(
        children: [
          Icon(
            AppIcons.noFilterMatch,
            size: AppIconSize.lg,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No matching tasks',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

/// Matches Municipal Officer's own `_ActiveReportCard` shape (title/status
/// row, location row, team+action row) instead of the boxed, multi-chip
/// "web card" layout this replaced — a left color stripe plus a status
/// badge plus a priority badge plus three more meta chips, none of them
/// matching how any other module's report/task cards actually look.
class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onOpenDetails});

  final MaintenanceTask task;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final team = MaintenanceTaskDirectory.instance.teamForTask(task);

    return GlassCard(
      onTap: onOpenDetails,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
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
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                AppIcons.location,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.locationLabel,
                  style: textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            task.eta,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.surfaceContainer,
                child: Icon(
                  AppIcons.team,
                  size: AppIconSize.sm,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.teamName ?? team?.name ?? 'Unassigned team',
                      style: textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      task.teamNote,
                      style: textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onOpenDetails,
                child: const Text('View'),
              ),
            ],
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
  const _EmptyView({required this.onRetry});
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
              AppIcons.task,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No assigned tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned maintenance tasks will appear here.',
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
              'Unable to load tasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again. No workflow has been changed.',
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
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: semantic.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reconnect to view and update assigned tasks.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
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
              'Maintenance team access is required for this screen.',
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
