import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A translucent "glass" surface card — the repeated `GlassCard` component
/// used throughout the approved Municipal Officer screens (stats, recent
/// activity, summaries). Module-scoped for now; promote to `lib/shared/` if
/// other modules need the same component.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: semantic.glassCardSurface,
        border: Border.all(color: semantic.glassBorder),
        borderRadius: AppComponentRadius.card,
        boxShadow: AppShadow.level1,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
