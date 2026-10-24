import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../core/widgets/ghana_refresh_indicator.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/async_action_button.dart';
import '../../../widgets/focused_search.dart';
import '../../../widgets/search_filter_list.dart';
import '../../../widgets/text_filter_chips.dart';
import '../../../widgets/status_badge.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';
import '../widgets/maintenance_scaffold.dart';

/// MNT-002 — Maintenance Team Assigned Tasks.
class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({
    super.key,
    this.refreshTasks,
    this.onNavigateToDashboard,
    this.onNavigateToProfile,
    this.onNotificationsTap,
    this.onOpenTaskDetails,
    this.initialState = AppScreenState.success,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToProfile;

  /// Opens Maintenance Notifications — wired to the header's bell icon.
  final VoidCallback? onNotificationsTap;

  /// Opens Task Details for the tapped task, by [MaintenanceTask.id].
  final ValueChanged<String>? onOpenTaskDetails;
  final AppScreenState initialState;

  /// Optional data source override for hosted previews and deterministic checks.
  final Future<void> Function()? refreshTasks;

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  late AppScreenState _state = widget.initialState;
  bool _manualRefresh = false;
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
        child: ListenableBuilder(
          listenable: Listenable.merge([
            MaintenanceTaskDirectory.instance.tasks,
            MaintenanceTaskDirectory.instance.loading,
            MaintenanceTaskDirectory.instance.error,
          ]),
          builder: (context, _) => _buildBody(
            context,
            MaintenanceTaskDirectory.instance.tasks.value,
          ),
        ),
      ),
    );
  }

  Future<void> _reload() async {
    if (_manualRefresh) return;
    setState(() {
      _manualRefresh = true;
      if (MaintenanceTaskDirectory.instance.error.value != null) {
        _state = AppScreenState.error;
      }
    });
    try {
      await (widget.refreshTasks ??
          MaintenanceTaskDirectory.instance.refresh)();
      if (mounted) setState(() => _state = AppScreenState.success);
    } catch (_) {
      if (mounted) setState(() => _state = AppScreenState.error);
    } finally {
      if (mounted) setState(() => _manualRefresh = false);
    }
  }

  Widget _buildBody(BuildContext context, List<MaintenanceTask> tasks) {
    if (MaintenanceTaskDirectory.instance.loading.value && !_manualRefresh) {
      return const GhanaLoadingIndicator();
    }
    if (MaintenanceTaskDirectory.instance.error.value != null) {
      return _ErrorView(onRetry: _reload);
    }
    switch (_state) {
      case AppScreenState.loading:
        return const GhanaLoadingIndicator();
      case AppScreenState.empty:
        return _EmptyView(onRetry: _reload);
      case AppScreenState.error:
        return _ErrorView(onRetry: _reload);
      case AppScreenState.offline:
        return _OfflineView(onRetry: _reload);
      case AppScreenState.permission:
        return _PermissionView(onRetry: _reload);
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
        if (openTasks.isEmpty) return _EmptyView(onRetry: _reload);
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
        child: Padding(
          padding: EdgeInsets.only(top: chromeInset.top),
          child: SearchFilterList(
            header: SearchFilterHeader(
              screenKey: 'maintenance-tasks',
              hintText: 'Search assigned tasks...',
              query: query,
              onQueryChanged: onQueryChanged,
              enabled: !disabled,
              results: (term) => [
                for (final task in tasks)
                  if (task.matches(term) &&
                      (statusFilter == null || task.status == statusFilter))
                    FocusedSearchResult(
                      title: task.title,
                      subtitle: task.id,
                      onSelected: onOpenTaskDetails == null
                          ? null
                          : () => onOpenTaskDetails!(task.id),
                    ),
              ],
              filters: _FilterRail(
                enabled: !disabled,
                statusFilter: statusFilter,
                onStatusChanged: onStatusChanged,
              ),
            ),
            child: ListView(
              // Stays draggable even when a short/filtered task list fits the
              // viewport — otherwise pull-to-refresh silently wouldn't trigger.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                chromeInset.bottom + AppSpacing.xl,
              ),
              children: [
                _QueueOverview(tasks: tasks),
                const SizedBox(height: AppSpacing.md),
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
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: AppSemanticColors.of(context).foregroundFor(color),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(value, style: textTheme.titleLarge),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium?.copyWith(
            color: AppSemanticColors.of(context).foregroundFor(color),
          ),
        ),
      ],
    );
  }
}

class _FilterRail extends StatelessWidget {
  const _FilterRail({
    required this.statusFilter,
    required this.enabled,
    required this.onStatusChanged,
  });
  final bool enabled;
  final MaintenanceTaskStatus? statusFilter;
  final ValueChanged<MaintenanceTaskStatus?> onStatusChanged;
  @override
  Widget build(BuildContext context) => TextFilterChips<MaintenanceTaskStatus?>(
    enabled: enabled,
    padding: EdgeInsets.zero,
    options: const [
      TextFilterOption(value: null, label: 'All'),
      TextFilterOption(
        value: MaintenanceTaskStatus.assigned,
        label: 'Assigned',
      ),
      TextFilterOption(
        value: MaintenanceTaskStatus.inProgress,
        label: 'In Progress',
      ),
      TextFilterOption(
        value: MaintenanceTaskStatus.pendingApproval,
        label: 'Awaiting Confirmation',
      ),
    ],
    selected: statusFilter,
    onSelected: onStatusChanged,
  );
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppSemanticColors.of(context).actionText,
        ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final Future<void> Function() onRetry;

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
            AsyncActionButton(onPressed: onRetry, label: 'Retry'),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final Future<void> Function() onRetry;

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
            AsyncActionButton(
              style: FilledButton.styleFrom(
                backgroundColor: semantic.error,
                foregroundColor: semantic.onError,
              ),
              onPressed: onRetry,
              label: 'Retry',
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final Future<void> Function() onRetry;

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
            AsyncActionButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              label: 'Retry',
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
  final Future<void> Function() onRetry;

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
            AsyncActionButton(onPressed: onRetry, label: 'Retry'),
          ],
        ),
      ),
    );
  }
}
