import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_card.dart';

/// Full-page state message — icon badge + title + message + up to two
/// actions. Shared shape for Empty / Error / Offline / Permission (§19.18)
/// across every module.
///
/// Global (`lib/widgets/`) rather than module-scoped: originally built for
/// the Municipal Officer module as `MunicipalStateMessage`, promoted and
/// renamed here once the Ministry Supervisor module needed the identical
/// pattern — every module shares one state-message treatment, not a
/// per-module reimplementation of it.
///
/// [bordered] wraps the content in an outlined card, as approved for
/// several screens' Error/Offline/Permission states.
class AppStateMessage extends StatelessWidget {
  const AppStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.badgeColor,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.primaryActionColor,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.bordered = false,
  });

  final IconData icon;

  /// Tint for the circular icon badge. Defaults to the neutral secondary
  /// surface when a status color doesn't apply.
  final Color? badgeColor;
  final String title;
  final String message;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;

  /// Overrides the primary button's fill color — retry-style actions
  /// commonly use [AppColors.error] rather than the default primary blue;
  /// permission/access actions typically stay the default.
  final Color? primaryActionColor;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final tint = badgeColor ?? colorScheme.onSurfaceVariant;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: AppIconSize.md, color: tint),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: textTheme.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
        if (primaryActionLabel != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: primaryActionColor == null
                  ? null
                  : FilledButton.styleFrom(backgroundColor: primaryActionColor),
              onPressed: onPrimaryAction,
              child: Text(primaryActionLabel!),
            ),
          ),
        ],
        if (secondaryActionLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel!),
            ),
          ),
        ],
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: content,
    );

    if (!bordered) {
      return Center(child: padded);
    }

    // Every caller renders this inside a full-height Expanded with nothing
    // else competing for the space, so — matching the unbordered path
    // above — it should be vertically centered too; sizing the card to its
    // own content without centering just leaves a large empty gap below it.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: GlassCard(padding: EdgeInsets.zero, child: padded),
      ),
    );
  }
}
