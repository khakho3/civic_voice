import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'coming_soon_badge.dart';

/// Inert language row shown in every module's profile "System Preferences"
/// section. Localization is not available yet, so the neutral badge is the
/// entire affordance rather than a misleading language-value control.
class LanguagePreferenceRow extends StatelessWidget {
  const LanguagePreferenceRow({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        const Icon(AppIcons.language, size: AppIconSize.md),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Language',
            style: textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const ComingSoonBadge(),
      ],
    );
  }
}
