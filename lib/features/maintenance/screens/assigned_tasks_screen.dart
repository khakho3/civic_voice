import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-002 — Maintenance Team Assigned Tasks.
class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({super.key});

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  AppScreenState _state = AppScreenState.success;
  String _statusFilter = 'All';
  String? _priorityFilter;

  final List<_TaskItem> _tasks = const [
    _TaskItem(
      title: 'Broken Street Light at Main Ave',
      location: '242 Main Avenue, Central District',
      status: 'In Progress',
      priority: 'High',
      teamNote: 'Team active · +2',
    ),
    _TaskItem(
      title: 'Pothole Repair Request',
      location: 'Elm Street & 4th Cross',
      status: 'Assigned',
      priority: 'Medium',
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
          NavigationDestination(icon: Icon(AppIcons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (_) {},
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.error:
        return _ErrorView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.offline:
        return _OfflineView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.permission:
        return _PermissionView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.disabled:
      case AppScreenState.success:
        return _AssignedTasksContent(
          tasks: _tasks,
          statusFilter: _statusFilter,
          priorityFilter: _priorityFilter,
          disabled: _state == AppScreenState.disabled,
          onStatusChanged: (value) => setState(() => _statusFilter = value),
          onPriorityChanged: (value) => setState(() => _priorityFilter = value),
        );
    }
  }
}

class _AssignedTasksContent extends StatelessWidget {
  const _AssignedTasksContent({
    required this.tasks,
    required this.statusFilter,
    required this.priorityFilter,
    required this.disabled,
    required this.onStatusChanged,
    required this.onPriorityChanged,
  });

  final List<_TaskItem> tasks;
  final String statusFilter;
  final String? priorityFilter;
  final bool disabled;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
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
            Text('Status', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['All', 'Assigned', 'In Progress'].map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: statusFilter == option,
                  onSelected: (_) => onStatusChanged(option),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Priority', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ['High', 'Medium', 'Low'].map((option) {
                return ChoiceChip(
                  label: Text(option),
                  selected: priorityFilter == option,
                  onSelected: (_) => onPriorityChanged(priorityFilter == option ? null : option),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...tasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TaskCard(task: task),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final _TaskItem task;

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
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 4, color: priorityColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(task.title, style: textTheme.titleMedium),
                        ),
                        _StatusBadge(label: task.status, color: statusColor, icon: statusIcon),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(AppIcons.location, size: AppIconSize.sm, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            task.location,
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          task.teamNote,
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View Task Details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Composed manually per DESIGN_SYSTEM.md — Status Badge is "Tokens only".
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSize.sm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
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
            Icon(AppIcons.task, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No assigned tasks', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned maintenance tasks will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
            Text('Unable to load tasks', style: Theme.of(context).textTheme.titleMedium),
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
            Icon(AppIcons.offline, size: AppIconSize.xl, color: semantic.warning),
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
            Icon(AppIcons.permissionDenied, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Permission required', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance team access is required for this screen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
    required this.teamNote,
  });

  final String title;
  final String location;
  final String status;
  final String priority;
  final String teamNote;
}