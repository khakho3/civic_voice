import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Neutral (not status-colored) tag flagging a setting or field that isn't
/// backed by a real feature yet — deliberately plain rather than a tinted
/// status-style pill, so it doesn't read as a status value. Global
/// (`lib/widgets/`): used on both Admin System Settings' rows and every
/// module's profile "Language" row, not one screen's own concern.
class ComingSoonBadge extends StatelessWidget {
  const ComingSoonBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.allSm,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        'Coming Soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: AppFontWeight.semiBold,
        ),
      ),
    );
  }
}
