import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'profile_edit_button.dart';

/// The personal identity block at the top of every role's Profile —
/// initials avatar, the person's actual name, an optional concise subtitle,
/// and neutral pills. Bare (no card): the hero reads as the page's own
/// identity, not a boxed section.
///
/// [onEdit] mounts the small edit pencil on the avatar; pass null for
/// identities with nothing self-editable (Guest). This is the personal
/// Profile hero only — Admin's User Details record uses its own compact
/// left-aligned identity, not this.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.name,
    this.subtitle,
    this.pills = const [],
    this.onEdit,
  });

  final String name;

  /// Plain descriptive text under the name (e.g. "Administrator account").
  final String? subtitle;

  /// Neutral role/status pills ("Guest", "Team Lead"). Only real, current
  /// facts: never a decorative badge for everyone.
  final List<String> pills;

  /// Opens the permission-scoped editor; null hides the pencil.
  final VoidCallback? onEdit;

  /// Avatar diameter (web `--space-4xl + --space-md`).
  static const double avatarSize = AppSpacing.xxxxl + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.isEmpty ? '' : part[0])
        .take(2)
        .join()
        .toUpperCase();

    // The stack is padded by the pencil's touch-target overhang on every
    // side so its full 48px target stays hit-testable (Flutter does not
    // hit-test outside a parent's bounds) while the avatar stays centred.
    const overhang = ProfileEditButton.hitOverhang;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Column(
        children: [
          SizedBox.square(
            dimension: avatarSize + overhang * 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: semantic.actionFill.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initials,
                      style: textTheme.headlineMedium?.copyWith(
                        color: semantic.actionText,
                      ),
                    ),
                  ),
                ),
                if (onEdit != null)
                  // The 24px disc sits on the avatar's lower-right edge; its
                  // 48px touch target extends past the avatar, centred on it.
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: ProfileEditButton(onPressed: onEdit),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            header: true,
            child: Text(
              name,
              style: textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs / 2),
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
              children: [for (final pill in pills) ProfileHeroPill(pill)],
            ),
          ],
        ],
      ),
    );
  }
}

/// Neutral caption pill for the Profile hero (web `.profile-hero__pill`).
class ProfileHeroPill extends StatelessWidget {
  const ProfileHeroPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outline),
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: AppFontWeight.semiBold,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
