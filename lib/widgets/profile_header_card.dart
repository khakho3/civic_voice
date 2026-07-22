import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The identity block at the top of every module's profile screen —
/// initials avatar, name, and optional subtitle/pills. Bare (no card
/// border): a profile hero reads as the page's own identity, not a boxed
/// section like the grouped info below it — matching the majority of this
/// app's profile screens (Municipal/Maintenance) rather than the one
/// bordered outlier (Admin's old `_ProfileCard`).
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    this.subtitle,
    this.pills = const [],
  });

  final String name;

  /// Plain descriptive text under the name (e.g. "Administrator account").
  /// Mutually usable alongside [pills] — some screens want both.
  final String? subtitle;

  /// Small tinted chips under the name/subtitle (e.g. "Verified Official",
  /// "ID #1234").
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Center(
      child: Column(
        children: [
          ClipOval(
            child: SizedBox(
              width: 80,
              height: 80,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (pills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: pills,
            ),
          ],
        ],
      ),
    );
  }
}
