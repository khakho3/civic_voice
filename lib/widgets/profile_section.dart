import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A titled, bordered group of profile rows — icon + title header with an
/// optional trailing action (an edit pencil, typically), opaque bordered
/// body. Never [GlassCard]: glass is prohibited on input-heavy sections
/// (Design System §19.10), and any section here can contain live text
/// fields once its screen enters edit mode.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  /// Kept for source compatibility while role profiles migrate. Section
  /// labels deliberately do not render an icon; each row owns its meaning.
  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppComponentRadius.card,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(
                alpha: colorScheme.outlineVariant.a * 0.6,
              ),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
