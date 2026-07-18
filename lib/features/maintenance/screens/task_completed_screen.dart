import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_task_directory.dart';

/// MNT-006 — Task Completed.
///
/// Reached from Update Progress once a task is saved as Completed — reads
/// back the same [MaintenanceTask] record Update Progress just wrote to
/// [MaintenanceTaskDirectory], rather than the fixed "Street Light Repair -
/// Sector 4" summary this screen showed for every task before, regardless
/// of which one was actually completed.
class TaskCompletedScreen extends StatelessWidget {
  const TaskCompletedScreen({super.key, required this.task, this.onBack});

  final MaintenanceTask task;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _TaskCompletedContent(task: task)),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'Task Completed',
              onBack: onBack,
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: semantic.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Text(
                  'READ ONLY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: semantic.success,
                    fontWeight: AppFontWeight.semiBold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCompletedContent extends StatelessWidget {
  const _TaskCompletedContent({required this.task});

  final MaintenanceTask task;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final resolvedAsFailed = task.status == MaintenanceTaskStatus.failed;
    final team = MaintenanceTaskDirectory.instance.teamForTask(task);
    final statusIcon = resolvedAsFailed
        ? AppIcons.statusRejected
        : AppIcons.statusResolved;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        DetailHeader.topInset(context) + AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(statusIcon, size: AppIconSize.xl, color: task.status.color),
                const SizedBox(height: AppSpacing.md),
                Text(
                  resolvedAsFailed ? 'Task Marked Failed' : 'Task Completed',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  resolvedAsFailed
                      ? 'This outcome has been recorded. This task is now read-only.'
                      : 'Completion recorded successfully. This task is now read-only.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Task Summary', style: textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Column(
              children: [
                _SummaryRow(
                  icon: AppIcons.task,
                  label: 'Task',
                  value: task.title,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  icon: AppIcons.location,
                  label: 'Location',
                  value: task.locationLabel,
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  icon: AppIcons.team,
                  label: 'Team',
                  value: team?.name ?? 'Unassigned team',
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  icon: AppIcons.calendar,
                  label: resolvedAsFailed ? 'Marked Failed' : 'Completed',
                  value: task.completedAtLabel ?? 'Just now',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            resolvedAsFailed ? 'Failure Notes' : 'Completion Notes',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: AppComponentRadius.card,
            ),
            child: Text(
              task.completionNotes ?? 'No notes were recorded.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Icon(icon, size: AppIconSize.md, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
