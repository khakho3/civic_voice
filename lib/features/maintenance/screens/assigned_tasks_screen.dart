import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-002 — Maintenance Team Assigned Tasks.
class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToProfile,
    this.onOpenTaskDetails,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onOpenTaskDetails;

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  AppScreenState _state = AppScreenState.success;
  String _query = '';
  String _statusFilter = 'All';
  String? _priorityFilter;

  final List<_TaskItem> _tasks = const [
    _TaskItem(
      title: 'Broken Street Light at Main Ave',
      location: '242 Main Avenue, Central District',
      status: 'In Progress',
      priority: 'High',
      category: 'Street Lighting',
      eta: 'On site',
      distance: '1.2 km',
      photoCount: 2,
      teamNote: 'Team active - 2 members',
    ),
    _TaskItem(
      title: 'Pothole Repair Request',
      location: 'Elm Street & 4th Cross',
      status: 'Assigned',
      priority: 'Medium',
      category: 'Road Repair',
      eta: 'Today 2:30 PM',
      distance: '3.8 km',
      photoCount: 1,
      teamNote: 'Today, 2:30 PM',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CivicVoice')),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onNavigateToDashboard?.call();
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
        return _AssignedTasksContent(
          tasks: _tasks,
          query: _query,
          statusFilter: _statusFilter,
          priorityFilter: _priorityFilter,
          disabled: _state == AppScreenState.disabled,
          onQueryChanged: (value) => setState(() => _query = value),
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onPriorityChanged: (value) => setState(() => _priorityFilter = value),
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
    required this.priorityFilter,
    required this.disabled,
    required this.onQueryChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onOpenTaskDetails,
  });

  final List<_TaskItem> tasks;
  final String query;
  final String statusFilter;
  final String? priorityFilter;
  final bool disabled;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;
  final VoidCallback? onOpenTaskDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filteredTasks = tasks
        .where((task) {
          final queryMatch = query.trim().isEmpty || task.matches(query);
          final statusMatch =
              statusFilter == 'All' || task.status == statusFilter;
          final priorityMatch =
              priorityFilter == null || task.priority == priorityFilter;
          return queryMatch && statusMatch && priorityMatch;
        })
        .toList(growable: false);

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              onChanged: onQueryChanged,
              decoration: InputDecoration(
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
              priorityFilter: priorityFilter,
              onStatusChanged: onStatusChanged,
              onPriorityChanged: onPriorityChanged,
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
                child: _TaskCard(task: task, onOpenDetails: onOpenTaskDetails),
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

  final List<_TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final activeCount = tasks
        .where((task) => task.status == 'In Progress')
        .length;
    final highPriorityCount = tasks
        .where((task) => task.priority == 'High')
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
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
                icon: AppIcons.statusInProgress,
                value: '$activeCount',
                label: 'Active',
                color: semantic.statusInProgress,
              ),
            ),
            Expanded(
              child: _QueueMetric(
                icon: AppIcons.criticalAlert,
                value: '$highPriorityCount',
                label: 'High',
                color: semantic.error,
              ),
            ),
          ],
        ),
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
    required this.priorityFilter,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  final String statusFilter;
  final String? priorityFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final statusOptions = const [
      ('All', 'All', AppIcons.filter),
      ('Assigned', 'New', AppIcons.statusAssigned),
      ('In Progress', 'Active', AppIcons.statusInProgress),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.inputField,
      ),
      child: Row(
        children: [
          Expanded(
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
          ),
          const SizedBox(width: AppSpacing.xs),
          PopupMenuButton<String>(
            tooltip: 'Priority filter',
            initialValue: priorityFilter ?? 'Any',
            onSelected: (value) =>
                onPriorityChanged(value == 'Any' ? null : value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'Any', child: Text('Any priority')),
              PopupMenuItem(value: 'High', child: Text('High')),
              PopupMenuItem(value: 'Medium', child: Text('Medium')),
              PopupMenuItem(value: 'Low', child: Text('Low')),
            ],
            child: Container(
              constraints: const BoxConstraints(maxWidth: 116),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: priorityFilter == null
                    ? colorScheme.surface
                    : colorScheme.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.criticalAlert,
                    size: AppIconSize.sm,
                    color: priorityFilter == null
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      priorityFilter ?? 'Priority',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: priorityFilter == null
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.onOpenDetails});

  final _TaskItem task;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    final Color priorityColor = switch (task.priority) {
      'High' => semantic.error,
      'Medium' => semantic.warning,
      _ => colorScheme.outline,
    };

    final (Color statusColor, IconData statusIcon) = switch (task.status) {
      'In Progress' => (AppColors.statusInProgress, AppIcons.statusInProgress),
      _ => (AppColors.statusAssigned, AppIcons.statusAssigned),
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetails,
        child: Stack(
          children: [
            Positioned.fill(
              right: null,
              child: SizedBox(
                width: AppSpacing.xs,
                child: ColoredBox(color: priorityColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md + AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: AppRadius.allSm,
                        ),
                        child: Icon(
                          AppIcons.maintenanceTeam,
                          size: AppIconSize.md,
                          color: priorityColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
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
                            const SizedBox(height: AppSpacing.xs),
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
                      _StatusBadge(
                        label: task.status,
                        color: statusColor,
                        icon: statusIcon,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _MetaChip(
                        icon: AppIcons.criticalAlert,
                        label: task.priority,
                        color: priorityColor,
                      ),
                      _MetaChip(
                        icon: AppIcons.eta,
                        label: task.eta,
                        color: colorScheme.primary,
                      ),
                      _MetaChip(
                        icon: AppIcons.camera,
                        label: '${task.photoCount}',
                        color: colorScheme.onSurfaceVariant,
                      ),
                      _MetaChip(
                        icon: AppIcons.navigate,
                        label: task.distance,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(
                        AppIcons.location,
                        size: AppIconSize.sm,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          task.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useStackedAction = constraints.maxWidth < 320;
                      final note = Text(
                        task.teamNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                      final action = FilledButton.tonalIcon(
                        onPressed: onOpenDetails,
                        icon: const Icon(AppIcons.chevronRight),
                        label: const Text('View Task Details'),
                      );

                      if (useStackedAction) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            note,
                            const SizedBox(height: AppSpacing.sm),
                            Align(
                              alignment: Alignment.centerRight,
                              child: action,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: note),
                          const SizedBox(width: AppSpacing.sm),
                          action,
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
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
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: color),
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

class _TaskItem {
  const _TaskItem({
    required this.title,
    required this.location,
    required this.status,
    required this.priority,
    required this.category,
    required this.eta,
    required this.distance,
    required this.photoCount,
    required this.teamNote,
  });

  final String title;
  final String location;
  final String status;
  final String priority;
  final String category;
  final String eta;
  final String distance;
  final int photoCount;
  final String teamNote;

  bool matches(String query) {
    final normalizedQuery = query.toLowerCase().trim();
    if (normalizedQuery.isEmpty) return true;
    return [
      title,
      location,
      status,
      priority,
      category,
      eta,
      distance,
      teamNote,
    ].any((value) => value.toLowerCase().contains(normalizedQuery));
  }
}
