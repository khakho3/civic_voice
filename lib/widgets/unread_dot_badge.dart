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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surface, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
