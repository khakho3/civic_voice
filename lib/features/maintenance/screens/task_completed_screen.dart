import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/app_state_message.dart';
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
  const TaskCompletedScreen({
    super.key,
    required this.task,
    required this.onNavigateToDashboard,
  });

  final MaintenanceTask task;
  final VoidCallback onNavigateToDashboard;

  @override
  Widget build(BuildContext context) {
    if (task.status != MaintenanceTaskStatus.pendingApproval &&
        task.status != MaintenanceTaskStatus.completed &&
        task.status != MaintenanceTaskStatus.failed) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.only(top: DetailHeader.topInset(context)),
                child: AppStateMessage(
                  icon: AppIcons.info,
                  title: 'Task not submitted',
                  message: 'This task has not reached an outcome yet.',
                  primaryActionLabel: 'Back to Task Details',
                  onPrimaryAction: onNavigateToDashboard,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: DetailHeader(
                title: 'Task Record',
                onBack: onNavigateToDashboard,
              ),
            ),
          ],
        ),
      );
    }
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final pending = task.status == MaintenanceTaskStatus.pendingApproval;
    final failed = task.status == MaintenanceTaskStatus.failed;
    final ink = pending
        ? semantic.statusPendingApprovalText
        : failed
        ? semantic.errorText
        : semantic.successText;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onNavigateToDashboard();
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: _TaskCompletedContent(
                task: task,
                onNavigateToDashboard: onNavigateToDashboard,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: DetailHeader(
                title: pending
                    ? 'Submitted for Approval'
                    : failed
                    ? 'Task Marked Failed'
                    : 'Task Completed',
                leadingIcon: AppIcons.back,
                onBack: onNavigateToDashboard,
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: TintedBadge(
                    label: pending ? 'AWAITING CONFIRMATION' : 'READ ONLY',
                    color: task.status.color,
                    textColor: ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCompletedContent extends StatelessWidget {
  const _TaskCompletedContent({
    required this.task,
    required this.onNavigateToDashboard,
  });

  final MaintenanceTask task;
  final VoidCallback onNavigateToDashboard;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pending = task.status == MaintenanceTaskStatus.pendingApproval;
    final resolvedAsFailed = task.status == MaintenanceTaskStatus.failed;
    final team = MaintenanceTaskDirectory.instance.teamForTask(task);
    final statusIcon = pending
        ? AppIcons.verify
        : resolvedAsFailed
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
                Icon(
                  statusIcon,
                  size: AppIconSize.xl,
                  color: task.status.color,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  pending
                      ? 'Submitted for Approval'
                      : resolvedAsFailed
                      ? 'Task Marked Failed'
                      : 'Task Completed',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  pending
                      ? 'A municipal officer will confirm the work before the report closes. You will be notified if it is returned for rework.'
                      : resolvedAsFailed
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
                  value: task.teamName ?? team?.name ?? 'Unassigned team',
                ),
                const Divider(height: AppSpacing.lg),
                _SummaryRow(
                  icon: AppIcons.calendar,
                  label: pending
                      ? 'Submitted'
                      : resolvedAsFailed
                      ? 'Marked Failed'
                      : 'Completed',
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
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNavigateToDashboard,
              icon: const Icon(AppIcons.back),
              label: const Text('Back to Task Details'),
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
