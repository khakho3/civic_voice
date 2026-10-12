import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'coming_soon_badge.dart';
import 'profile_preference_row.dart';

/// Inert Language row shown in every role's Profile preferences.
/// Localization is not available yet, so the far-right neutral Coming Soon
/// badge is the whole affordance — no language value or chooser that would
/// imply working localization.
class LanguagePreferenceRow extends StatelessWidget {
  const LanguagePreferenceRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePreferenceRow(
      icon: AppIcons.language,
      label: 'Language',
      trailing: ComingSoonBadge(),
    );
  }
}
