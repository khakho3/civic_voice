import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Wraps a `showDialog`/`showModalBottomSheet` `builder` return value so
/// the barrier + page content behind it blurs instead of showing through
/// sharply. The dialog/sheet surface itself is glass (translucent) per
/// `dialogTheme`/`bottomSheetTheme` — without this, page content read
/// straight through and visually collided with the dialog's own text.
///
/// Wrap the *builder's return value*, not the dialog/sheet widget's
/// content — `BackdropFilter` blurs whatever is already painted behind
/// it in the same stacking context (the barrier + page), then whatever
/// this wraps paints crisply on top, unaffected by the blur itself.
class GlassDialogBackdrop extends StatelessWidget {
  const GlassDialogBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // AppGlassBlur.small, not .medium — at 20 sigma the barrier/page
    // behind the dialog blurred into an almost-flat wash, and combined
    // with the dialog's own translucent surface, that read as "no glass
    // effect" rather than frosted glass. A lighter blur still fixes the
    // original text-collision problem (that's the point of blurring at
    // all) while leaving enough structure/color visible through the
    // translucency to actually look like glass.
    return BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: AppGlassBlur.small,
        sigmaY: AppGlassBlur.small,
      ),
      child: child,
    );
  }
}
