import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../utils/time_greeting.dart';

class AdminDashboardGreeting extends StatelessWidget {
  const AdminDashboardGreeting({super.key, this.fullName, this.municipality});

  final String? fullName;
  final String? municipality;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fullName == null
              ? 'Assembly Overview'
              : '${timeBasedGreeting()}, $fullName',
          style: theme.textTheme.headlineSmall,
        ),
        if (municipality case final label?) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                AppIcons.municipality,
                size: AppIconSize.sm,
                color: secondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(color: secondary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
