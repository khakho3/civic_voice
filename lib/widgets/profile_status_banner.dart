import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum ProfileBannerTone { success, warning, error }

/// The one Profile status banner every role shares: saved, offline, or a
/// failure, with readable semantic ink on a light tint. Announced once as a
/// live region when it appears.
class ProfileStatusBanner extends StatelessWidget {
  const ProfileStatusBanner({
    super.key,
    required this.tone,
    required this.title,
    this.message,
  });

  final ProfileBannerTone tone;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    final (hue, ink, icon) = switch (tone) {
      ProfileBannerTone.success => (
        semantic.success,
        semantic.successText,
        AppIcons.success,
      ),
      ProfileBannerTone.warning => (
        semantic.warning,
        semantic.warningText,
        AppIcons.offline,
      ),
      ProfileBannerTone.error => (
        semantic.error,
        semantic.errorText,
        AppIcons.warning,
      ),
    };

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            hue.withValues(alpha: 0.09),
            colorScheme.surface,
          ),
          borderRadius: AppRadius.allMd,
          border: Border.all(color: hue.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: AppIconSize.standard, color: ink),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: textTheme.titleSmall),
                  if (message != null)
                    Text(
                      message!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
