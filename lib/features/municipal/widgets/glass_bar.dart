import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// A translucent, backdrop-blurred bar — the Civic Glass chrome component
/// for header/navigation/action-bar surfaces that float over scrollable
/// content (§19.10 Glass Usage Rules: glass is permitted on navigation
/// panels; prohibited on long-form/input-heavy content, which is why only
/// chrome — never body content or forms — uses this).
///
/// Translucency alone reads as a plain solid color on a flat canvas — the
/// blur is what actually makes scrolled content look frosted underneath.
/// Callers must be positioned as a [Stack] overlay above scrollable content
/// (not a `Column` sibling that pushes content into its own separate box)
/// for that blur to have anything visible to blur.
class GlassBar extends StatelessWidget {
  const GlassBar({super.key, required this.child, this.border});

  final Widget child;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppGlassBlur.medium,
          sigmaY: AppGlassBlur.medium,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: semantic.glassNavSurface,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
