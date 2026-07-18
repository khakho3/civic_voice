import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'coming_soon_badge.dart';

/// Locked "English" language row shown in every module's profile "System
/// Preferences" section and on Admin System Settings — no multi-language
/// content exists anywhere in the app yet, so this is genuinely inert
/// (no control at all), not just visually implied.
class LanguagePreferenceRow extends StatelessWidget {
  const LanguagePreferenceRow({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(child: Text('Language', style: textTheme.bodyLarge)),
              const SizedBox(width: AppSpacing.xs),
              const ComingSoonBadge(),
            ],
          ),
        ),
        Text(
          'English',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
