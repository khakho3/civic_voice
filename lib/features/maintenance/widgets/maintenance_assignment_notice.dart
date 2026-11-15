import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/async_action_button.dart';
import '../../../widgets/glass_card.dart';

/// Shared nonblocking membership guidance on Home, Tasks and Profile.
class MaintenanceAssignmentNotice extends StatelessWidget {
  const MaintenanceAssignmentNotice({super.key, this.onRetry});

  static const title = 'No team assigned';
  static const message =
      'Ask an administrator to add your account to a maintenance team. '
      'Your profile and notifications are still available.';

  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                AppIcons.team,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            AsyncActionButton(label: 'Retry', onPressed: onRetry),
          ],
        ],
      ),
    ),
  );
}
