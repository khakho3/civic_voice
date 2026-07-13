import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-001 — Maintenance Team Dashboard.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  AppScreenState _state = AppScreenState.success;

  final int assignedCount = 12;
  final int activeCount = 3;
  final int completedCount = 45;
  final List<_TaskPreview> recentTasks = const [
    _TaskPreview(
      title: 'Oak St Pothole',
      location: '1242 Oak Street, Downtown',
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Street Light Failure',
      location: 'Maple Ave & 5th Crossing',
      icon: AppIcons.location,
    ),
    _TaskPreview(
      title: 'Hydrant Maintenance',
      location: 'West Park Perimeter',
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
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
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
        return _EmptyView(onRefresh: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.error:
        return _ErrorView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.offline:
        return _OfflineView(onRetry: () => setState(() => _state = AppScreenState.success));
      case AppScreenState.permission:
        return const _PermissionView();
      case AppScreenState.disabled:
      case AppScreenState.success:
        return _DashboardContent(
          assignedCount: assignedCount,
          activeCount: activeCount,
          completedCount: completedCount,
          recentTasks: recentTasks,
          disabled: _state == AppScreenState.disabled,
        );
    }
  }
}

/// Success state — the real dashboard content.
class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.assignedCount,
    required this.activeCount,
    required this.completedCount,
    required this.recentTasks,
    required this.disabled,
  });

  final int assignedCount;
  final int activeCount;
  final int completedCount;
  final List<_TaskPreview> recentTasks;
  final bool disabled;

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
              Text('Good Morning, Marcus', style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Here is your workload overview for today.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Stat cards row.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.task,
                      label: 'Assigned',
                      value: '$assignedCount',
                      accentColor: colorScheme.primary,
                      tag: 'Total',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.analytics,
                      label: 'Active',
                      value: '$activeCount',
                      accentColor: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatCard(
                      icon: AppIcons.statusResolved,
                      label: 'Completed',
                      value: '$completedCount',
                      accentColor: semantic.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Search bar — themed InputDecorationTheme, no manual styling.
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

              // Map placeholder — real Google Maps integration is a
              // separate follow-up task (API key + google_maps_flutter).
              _MapPlaceholder(),
              const SizedBox(height: AppSpacing.lg),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Assigned Tasks', style: textTheme.titleMedium),
                  TextButton(onPressed: () {}, child: const Text('View All')),
                ],
              ),
              ...recentTasks.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskListTile(task: task),
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
      shape: RoundedRectangleBorder(
        borderRadius: AppComponentRadius.card,
        side: BorderSide(color: accentColor.withValues(alpha: 0.3)),
      ),
      color: accentColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.allXs,
                  ),
                  child: Icon(icon, size: AppIconSize.sm, color: accentColor),
                ),
                if (tag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: AppRadius.allXs,
                    ),
                    child: Text(tag!, style: textTheme.labelSmall),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(value, style: textTheme.headlineSmall),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for the live map — layout-accurate, not yet wired to
/// google_maps_flutter. Follow-up task, not a redesign of the approved screen.
class _MapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(AppIcons.pinned, size: AppIconSize.lg, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nearby Tasks map coming soon',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _TaskListTile extends StatelessWidget {
  const _TaskListTile({required this.task});

  final _TaskPreview task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(task.icon, color: colorScheme.primary),
        ),
        title: Text(task.title),
        subtitle: Text(task.location),
        trailing: const _StatusBadge(label: 'Assigned', color: AppColors.statusAssigned),
      ),
    );
  }
}

/// Composed manually per DESIGN_SYSTEM.md — Status Badge is "Tokens only".
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

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
          Icon(AppIcons.statusAssigned, size: AppIconSize.sm, color: color),
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
            Icon(AppIcons.empty, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('No assigned work yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned tasks will appear here after dispatch updates your queue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
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
            Text('Unable to load dashboard', style: Theme.of(context).textTheme.titleMedium),
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
            Icon(AppIcons.offline, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Assigned tasks will sync once you reconnect.',
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
            Icon(AppIcons.permissionDenied, size: AppIconSize.xl, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text('Permission required', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Sign in with your maintenance credentials to view assigned work.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskPreview {
  const _TaskPreview({required this.title, required this.location, required this.icon});
  final String title;
  final String location;
  final IconData icon;
}
