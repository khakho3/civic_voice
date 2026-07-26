import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Wraps a fixed header (search field, filter chips) above a scrollable
/// list. The header hides as soon as the user scrolls down past a small
/// threshold (just enough to ignore incidental jitter) and reappears just
/// as promptly the moment they reverse direction — no waiting for the
/// gesture to end, no 50%-of-header snap decision. It's always fully shown
/// once the list is back at the very top.
///
/// Global (`lib/widgets/`) rather than module-scoped: any screen with fixed
/// chrome eating vertical space above a scrollable list should reuse this
/// rather than reimplementing it per module. Only search fields/filter
/// chips/dropdowns belong in [header] — stat or metric cards are content,
/// not transient chrome, so they belong in the scrollable [child] itself
/// (as its first item), not wrapped in here.
class CollapsibleListHeader extends StatefulWidget {
  const CollapsibleListHeader({
    super.key,
    required this.header,
    required this.child,
  });

  final Widget header;
  final Widget child;

  @override
  State<CollapsibleListHeader> createState() => _CollapsibleListHeaderState();
}

class _CollapsibleListHeaderState extends State<CollapsibleListHeader>
    with TickerProviderStateMixin {
  // A small threshold before a scroll reversal counts as a deliberate
  // direction change in either direction — big enough to ignore incidental
  // jitter (a settle bounce, a one-off correction as the viewport resizes),
  // small enough that both hiding and revealing still feel close to
  // instant compared to waiting for the whole gesture to end.
  static const double _directionThreshold = 24;

  bool _hidden = false;
  double _openFraction = 1;
  double _accumulated = 0;
  AnimationController? _animController;

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.duration(context, AppMotionDuration.fast),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: AppMotionCurve.decelerate,
    );
    final tween = Tween<double>(begin: _openFraction, end: target);
    controller.addListener(() {
      setState(() => _openFraction = tween.evaluate(animation));
    });
    _animController?.dispose();
    _animController = controller;
    controller.forward();
  }

  void _setHidden(bool hidden) {
    if (hidden == _hidden) return;
    _hidden = hidden;
    _animateTo(hidden ? 0.0 : 1.0);
  }

  /// Shared by both the ordinary scroll path and the overscroll path
  /// below — same accumulate-then-threshold rule either way.
  void _applyDelta(double delta) {
    // A direction reversal starts the accumulator fresh rather than
    // needing to "cancel out" whatever ran up before it. Both directions
    // share the same threshold — an asymmetric "reveal instantly, zero
    // threshold" rule sounds appealing but fires on a single stray
    // corrective sample as readily as on a genuine reversal; this still
    // reacts within a couple dozen pixels either way, nowhere near the
    // old "wait for the whole gesture to end" behavior.
    if ((delta < 0) != (_accumulated < 0)) _accumulated = 0;
    _accumulated += delta;

    if (_accumulated < -_directionThreshold) {
      _setHidden(false);
    } else if (_accumulated > _directionThreshold) {
      _setHidden(true);
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Ignore anything that isn't the primary vertical list — a nested
    // horizontal scrollable (a filter-chip row inside [header]) bubbles
    // its own notifications up through this same listener otherwise.
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      if (delta == null || delta == 0) return false;

      if (notification.metrics.pixels <= 4) {
        _accumulated = 0;
        _setHidden(false);
        return false;
      }

      // Resizing the Expanded list's viewport as our own hide/reveal
      // transition plays can shrink the list's own maxScrollExtent enough
      // that Flutter's scroll machinery forces `pixels` back toward its
      // new valid range — arriving as an ordinary ScrollUpdateNotification
      // with no `dragDetails` (nothing actually touched the screen to
      // cause it). Only distrust that specific case — a `dragDetails`-null
      // update while our own transition is animating — so a genuine
      // fling's momentum (which also reports `dragDetails: null` on every
      // update) is still trusted once our own animation has settled.
      final isRealDrag = notification.dragDetails != null;
      final animatingOwnTransition = _animController?.isAnimating ?? false;
      if (!isRealDrag && animatingOwnTransition) return false;

      _applyDelta(delta);
      return false;
    }

    // Once collapsing the header frees enough room that the rest of the
    // content fits entirely, maxScrollExtent can hit 0 — every further
    // drag then reports as overscroll instead of an ordinary scroll
    // update, since there's no scroll range left to move `pixels`
    // through. Without this, a short list's header would be stranded
    // hidden with no gesture able to bring it back.
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      _applyDelta(notification.overscroll);
      return false;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        children: [
          ClipRect(
            key: const ValueKey('collapsible_header'),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: _openFraction,
              child: widget.header,
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
