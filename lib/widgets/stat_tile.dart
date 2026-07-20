import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A single borderless stat — icon, value, label, optional delta. Replaces
/// the "grid of fully-carded tiles, each with its own decorated icon-badge
/// Container" pattern repeated across every dashboard (Citizen, Municipal,
/// Admin, Ministry) — grouping a `Row`/`GridView` of these reads as one
/// lightweight stat strip instead of a grid of boxes-in-boxes. Callers
/// still own the grouping (Row, GridView, optional dividers between tiles)
/// — this widget only owns the single-tile content.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
    this.deltaColor,
    this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;

  /// Small trailing signal next to the value, e.g. "+12%" — omitted when
  /// there's nothing meaningful to compare against.
  final String? delta;
  final Color? deltaColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tint = iconColor ?? AppColors.primary;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSize.md, color: tint),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (delta != null) ...[
              const SizedBox(width: 4),
              Text(
                delta!,
                style: textTheme.labelSmall?.copyWith(
                  color: deltaColor ?? colorScheme.onSurfaceVariant,
                  fontWeight: AppFontWeight.semiBold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.allSm,
      child: Padding(padding: const EdgeInsets.all(4), child: content),
    );
  }
}

/// A thin vertical hairline for separating [StatTile]s laid out in a `Row`
/// — used instead of giving each tile its own bordered card.
class StatTileDivider extends StatelessWidget {
  const StatTileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      color: outline.withValues(alpha: outline.a * 0.6),
    );
  }
}
