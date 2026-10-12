import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'profile_action_row.dart';
import 'profile_section.dart';

/// The Profile's one standalone destructive Log out row: same height and
/// rhythm as the action rows above it, error-tinted label and icon, and no
/// chevron (it confirms and signs out rather than opening a screen).
/// Callers confirm through `showConfirmDialog` with copy accurate to the
/// session (registered vs guest).
class ProfileSessionSection extends StatelessWidget {
  const ProfileSessionSection({
    super.key,
    required this.onLogOut,
    this.label = 'Log out',
  });

  final VoidCallback? onLogOut;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ProfileGroupTile(
        child: ProfileActionRow(
          icon: AppIcons.logOut,
          label: label,
          onTap: onLogOut,
          destructive: true,
          showChevron: false,
        ),
      ),
    );
  }
}
