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
    // Flat, single-level Row (not Row-inside-Expanded-inside-Row) — both
    // text pieces are independently Flexible with ellipsis, so on a very
    // narrow phone they shrink first rather than forcing a RenderFlex
    // overflow around the one genuinely fixed-width child, ComingSoonBadge.
    return Row(
      children: [
        Flexible(
          child: Text(
            'Language',
            style: textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const ComingSoonBadge(),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            'English',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
