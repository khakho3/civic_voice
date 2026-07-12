import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A translucent "glass" surface card — the repeated `GlassCard` component
/// used throughout the approved Municipal Officer screens (stats, recent
/// activity, summaries, list rows). Module-scoped for now; promote to
/// `lib/shared/` if other modules need the same component.
///
/// No [BackdropFilter] here (unlike [GlassBar]) — this is deliberately
/// translucency-only. Cards repeat per list item (report cards, team
/// cards), and blurring each one individually on every scroll frame is a
/// real performance cost for no real payoff, since there's nothing
/// distinct stacked behind an individual card the way there is behind the
/// header/nav bars.
///
/// Per §19.10 Glass Usage Rules, glass is prohibited on input-heavy
/// forms/long-form content — screens with a form section (Verification's
/// checklist, Report Progress's evidence upload) keep that section on a
/// plain opaque surface instead of wrapping it in [GlassCard].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When set, the card becomes tappable (ripple feedback) — used for
  /// selectable/navigable list rows (report cards, team cards).
  final VoidCallback? onTap;

  /// Overrides the default glass hairline — e.g. a thicker primary-colored
  /// border to highlight a selected list row (Assign Team's team cards).
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    final decoration = BoxDecoration(
      color: semantic.glassCardSurface,
      border: border ?? Border.all(color: semantic.glassBorder),
      borderRadius: AppComponentRadius.card,
      boxShadow: AppShadow.level1,
    );

    if (onTap == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: AppComponentRadius.card,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
