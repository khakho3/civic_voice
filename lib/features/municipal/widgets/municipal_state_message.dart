import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Full-page state message — icon badge + title + message + up to two
/// actions. Shared shape for Error / Offline / Permission (§19.18) across
/// Municipal Officer screens. Confirmed against both MUN-001 Dashboard and
/// MUN-002 Incoming Reports approved frames.
///
/// [bordered] wraps the content in an outlined card, as approved for
/// Incoming Reports' Error/Offline/Permission states.
class MunicipalStateMessage extends StatelessWidget {
  const MunicipalStateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.badgeColor,
    this.primaryActionLabel,
    this.onPrimaryAction,
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
        Text(
          message,
          style: textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (primaryActionLabel != null) ...[
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
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

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline),
          borderRadius: AppComponentRadius.card,
        ),
        child: padded,
      ),
    );
  }
}
