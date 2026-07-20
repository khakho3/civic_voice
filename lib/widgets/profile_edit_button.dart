import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Compact edit-pencil affordance for a [ProfileSection] header — a small
/// icon with a tight tap target, not a full 48×48 Material [IconButton]
/// with its default ink splash. Same [AppIcons.edit] glyph and 'Edit'
/// tooltip every call site already relied on, just visually restrained.
class ProfileEditButton extends StatelessWidget {
  const ProfileEditButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(AppIcons.edit, size: AppIconSize.sm),
      tooltip: 'Edit',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      splashRadius: 18,
    );
  }
}
