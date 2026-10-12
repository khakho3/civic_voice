import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';
import 'profile_section.dart';

/// A leading-icon action row inside a [ProfileSection] — About CivicVoice,
/// Change password, Log out. Same 64px height and 16px inset as every
/// other Profile row so actions keep one rhythm.
///
/// The trailing chevron renders only when [onTap] is set and [showChevron]
/// is true, so a row never implies navigation it does not have; the logout
/// row turns it off. [destructive] tints label and icon with the readable
/// error ink.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailingLabel,
    this.caption,
    this.onTap,
    this.destructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final String? trailingLabel;

  /// Secondary line under [label].
  final String? caption;
  final VoidCallback? onTap;
  final bool destructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final ink = destructive ? semantic.errorText : null;
    final iconColor = ink ?? colorScheme.onSurfaceVariant;

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ProfileRowMetrics.minHeight),
      child: Padding(
        padding: ProfileRowMetrics.padding,
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.standard, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyLarge?.copyWith(color: ink)),
                  if (caption != null)
                    Text(
                      caption!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                trailingLabel!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onTap != null && showChevron) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.chevronRight,
                size: AppIconSize.sm,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: () {
          AppHaptics.activate();
          onTap!();
        },
        child: row,
      ),
    );
  }
}
