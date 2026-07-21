import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A top-of-screen banner for a push notification that arrives while the
/// app is already open — `FirebaseMessaging.onMessage` fires for exactly
/// this case, but by itself only delivers the payload silently; nothing
/// shows the user anything happened. This is that missing piece: slides
/// down over whatever screen is currently showing, auto-dismisses, and is
/// tappable/swipe-up-dismissable, independent of any one screen's widget
/// tree (uses the root [Overlay], reached via the app's global navigator
/// key) so it works no matter which screen is on top when the push arrives.
class InAppNotificationBanner {
  InAppNotificationBanner._();

  static OverlayEntry? _current;

  static void show(
    OverlayState overlay, {
    required String title,
    required String message,
    IconData icon = AppIcons.notifications,
    Color color = AppColors.primary,
    VoidCallback? onTap,
  }) {
    // Only one at a time — a second push arriving mid-banner replaces
    // rather than stacking, so they can't pile up over each other.
    _current?.remove();

    late final OverlayEntry entry;
    void dismiss() {
      entry.remove();
      if (identical(_current, entry)) _current = null;
    }

    entry = OverlayEntry(
      builder: (context) => _BannerCard(
        title: title,
        message: message,
        icon: icon,
        color: color,
        onTap: onTap,
        onDismiss: dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _BannerCard extends StatefulWidget {
  const _BannerCard({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.onDismiss,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  @override
  State<_BannerCard> createState() => _BannerCardState();
}

class _BannerCardState extends State<_BannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
  Timer? _autoDismissTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _autoDismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _autoDismissTimer?.cancel();
    if (mounted) await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: SlideTransition(
          position: _offset,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Dismissible(
              key: const ValueKey('in-app-notification-banner'),
              direction: DismissDirection.up,
              onDismissed: (_) {
                _autoDismissTimer?.cancel();
                _dismissing = true;
                widget.onDismiss();
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AppComponentRadius.card,
                  onTap: widget.onTap == null
                      ? null
                      : () {
                          _dismiss();
                          widget.onTap!();
                        },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppComponentRadius.card,
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                      boxShadow: AppShadow.level2,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: AppIconSize.xl,
                          height: AppIconSize.xl,
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(widget.icon, color: widget.color),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: theme.textTheme.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.message.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.message,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
