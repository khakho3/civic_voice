import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// The shared transition for bottom-nav tab switches — a soft, symmetric
/// crossfade+scale with no directional slide, deliberately distinct from
/// [AppMotion.pageTransitionsTheme]'s Fade-Forwards (which stays reserved
/// for drill-down/back-button navigation, e.g. `pushNamed` to a details or
/// notifications screen). Both the incoming and outgoing route use this
/// same builder, so [Navigator.pushReplacement]/`pushAndRemoveUntil` play
/// it forward on the way in and in reverse on the way out — tabs read as
/// peers, with no destination feeling "further forward" than another.
///
/// [primary] is reserved for Citizen's central Report action — a bigger,
/// bouncier settle instead of the other tabs' subtle one, so the app's one
/// "do something new" destination reads as distinctly more emphatic than
/// switching between viewing tabs.
Route<T> tabRoute<T>(
  BuildContext context,
  WidgetBuilder builder, {
  String? routeName,
  bool primary = false,
}) {
  final duration = AppMotion.duration(
    context,
    primary ? AppMotionDuration.emphasized : AppMotionDuration.moderate,
  );
  return PageRouteBuilder<T>(
    settings: RouteSettings(name: routeName),
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final scale = Tween<double>(begin: primary ? 0.82 : 0.96, end: 1.0)
          .animate(
            CurvedAnimation(
              parent: animation,
              curve: primary
                  ? AppMotionCurve.overshoot
                  : AppMotionCurve.decelerate,
            ),
          );
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(scale: scale, child: child),
      );
    },
  );
}
