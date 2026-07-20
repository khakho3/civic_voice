import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Weight is deliberately light by default (a faint hairline, no shadow) —
/// a card should read as a soft grouping, not a boxed panel. Pass
/// [elevated] for the rare surface that genuinely needs to float.
class CivicGlassCard extends StatelessWidget {
  const CivicGlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.borderRadius = AppRadius.allMd,
    this.backgroundColor,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            theme.extension<AppSemanticColors>()!.glassSurface,
        borderRadius: borderRadius,
        border: Border.all(color: outline.withValues(alpha: outline.a * 0.6)),
        boxShadow: elevated ? AppShadow.level1 : AppShadow.level0,
      ),
      child: child,
    );
  }
}
