import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A frosted, translucent floating action button — same blur+glass
/// language as [GlassBar]'s chrome, rather than a solid Material 3
/// default FAB. Kept fully opaque on the *icon* itself (only the
/// background is glass) so the tap affordance never loses contrast —
/// a FAB is a high-emphasis primary action, translucency shouldn't
/// undermine that the way it would on chrome/cards.
class GlassFab extends StatelessWidget {
  const GlassFab({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  static const _diameter = 56.0;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlassBlur.small,
          sigmaY: AppGlassBlur.small,
        ),
        child: Container(
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: semantic.glassNavSurface,
            border: Border.all(color: semantic.glassBorder),
            boxShadow: AppShadow.level1,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Tooltip(
                message: tooltip ?? '',
                child: Icon(icon, color: AppColors.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
