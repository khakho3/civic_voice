import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A titled, bordered group of [SettingsRow]s — originally built for Admin
/// System Settings, promoted to `lib/widgets/` since every module's profile
/// screen now uses the identical shape for its own "System Preferences"
/// section (Theme, Language).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: children[i],
                ),
                if (i != children.length - 1)
                  Divider(height: 1, color: colorScheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A single row inside a [SettingsSection] — label (+ optional description
/// and [ComingSoonBadge]-style badge) with a trailing control (switch,
/// dropdown, segmented button).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.trailing,
    this.description,
    this.badge,
  });

  final String label;
  final Widget trailing;
  final String? description;

  /// Shown inline after [label] — typically a [ComingSoonBadge] for a
  /// setting that isn't backed by a real feature yet.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: description == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(child: Text(label, style: textTheme.bodyLarge)),
                  if (badge != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    badge!,
                  ],
                ],
              ),
              if (description != null) ...[
                const SizedBox(height: 2),
                Text(
                  description!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        trailing,
      ],
    );
  }
}
