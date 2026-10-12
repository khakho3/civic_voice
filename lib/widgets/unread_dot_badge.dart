import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Overlays a small, plain dot on the top-right corner of [child] when
/// [show] is true — "there's new stuff," never a count. Used on every
/// module's notification bell, plus Municipal's Inbox tab icon and
/// Maintenance's Tasks tab icon, all driven by the same
/// `NotificationDirectory.hasUnread` signal filtered per surface.
class UnreadDotBadge extends StatelessWidget {
  const UnreadDotBadge({super.key, required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = AppSemanticColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          // Error red, not brand gold: gold is 1.47:1 against a light
          // header, and web's shared unread badge uses the error hue too.
          // The dot pops in once when unread state appears; reduced motion
          // shows it immediately.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: AppMotion.duration(context, AppMotionDuration.standard),
            curve: AppMotionCurve.emphasized,
            builder: (context, scale, dot) => Opacity(
              opacity: ((scale - 0.6) / 0.4).clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: dot),
            ),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: semantic.error,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
