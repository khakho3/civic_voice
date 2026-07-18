import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A tappable icon+label(+trailing label) row inside a [ProfileSection] —
/// Change Password, Last Activity, etc. The trailing chevron only renders
/// when [onTap] is set, so a row never implies navigability it doesn't
/// actually have.
class ProfileActionRow extends StatelessWidget {
  const ProfileActionRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailingLabel,
    this.caption,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingLabel;

  /// Shown under [label] instead of a trailing value (e.g. "Last updated 3
  /// months ago") — mutually exclusive with [trailingLabel] in practice,
  /// though nothing enforces that.
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final row = Row(
      children: [
        Icon(icon, size: AppIconSize.md, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: caption == null
              ? Text(
                  label,
                  style: textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(caption!, style: textTheme.bodySmall),
                  ],
                ),
        ),
        if (trailingLabel != null) ...[
          Text(
            trailingLabel!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (onTap != null)
          Icon(
            AppIcons.chevronRight,
            size: AppIconSize.sm,
            color: colorScheme.onSurfaceVariant,
          ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: row,
      ),
    );
  }
}
