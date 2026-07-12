import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class CivicGlassCard extends StatelessWidget {
  const CivicGlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.borderRadius = AppRadius.allMd,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            theme.extension<AppSemanticColors>()!.glassSurface,
        borderRadius: borderRadius,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: AppShadow.level1,
      ),
      child: child,
    );
  }
}
