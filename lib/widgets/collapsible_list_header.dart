import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

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
///
/// **Collapsed-rail mode (F03).** Pass [collapsedHeader] — typically a
/// compact [SearchTriggerField] first, then the sticky text-only filter
/// chips — and the behavior changes to the accepted search contract: the
/// full [header] shows only at the true top of the list; scrolling down
/// swaps in the compact rail, which stays put; ordinary upward scrolling
/// does not re-expand it, so the header never flickers open and shut while
/// reading. Search from the rail opens the focused mode explicitly.
/// Without [collapsedHeader] the original reveal-on-reverse behavior is
/// kept, so existing screens are unchanged until they adopt the rail.
class CollapsibleListHeader extends StatefulWidget {
  const CollapsibleListHeader({
    super.key,
    required this.header,
    required this.child,
    this.collapsedHeader,
  });

  final Widget header;
  final Widget child;

  /// The compact sticky rail shown once the list scrolls away from the top.
  final Widget? collapsedHeader;

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

  bool _railCollapsed = false;
  double _railAccumulated = 0;
  final _railKey = GlobalKey();
  bool _adjustingRail = false;
  ScrollNotification? _lastRailScroll;

  void _revealRailAtTop() {
    final notification = _lastRailScroll;
    final context = notification?.context;
    if (!_railCollapsed ||
        notification == null ||
        context == null ||
        !context.mounted) {
      return;
    }
    final position = Scrollable.maybeOf(context)?.position;
    if (position != null && position.pixels <= 4) {
      _setRailCollapsed(false, notification);
    }
  }

  void _setRailCollapsed(bool collapsed, ScrollNotification notification) {
    if (_railCollapsed == collapsed || _adjustingRail) return;
    final height = _railKey.currentContext?.size?.height ?? 0;
    // Keep short lists expanded: reclaiming header height must not erase
    // their scroll range and strand the person in the compact mode.
    if (collapsed &&
        (notification.metrics.maxScrollExtent <= height ||
            notification.metrics.pixels < height)) {
      return;
    }
    final position = notification.context == null
        ? null
        : Scrollable.maybeOf(notification.context!)?.position;
    final offset = position?.pixels;
    _adjustingRail = true;
    setState(() => _railCollapsed = collapsed);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nextHeight = _railKey.currentContext?.size?.height ?? height;
      if (position != null && position.hasPixels && offset != null) {
        // The header is outside the viewport. Compensate for its height
        // change so the card being read stays at the same screen position.
        final target = (collapsed ? offset + nextHeight - height : 0.0).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        position.jumpTo(target);
      }
      _adjustingRail = false;
    });
  }

  /// Collapsed-rail mode: expand only at the true top (or by pulling down
  /// there); collapse after a deliberate downward scroll; ignore upward
  /// scrolling in between.
  bool _onRailScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical ||
        _adjustingRail) {
      return false;
    }
    _lastRailScroll = notification;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (notification.metrics.pixels <= 4 && delta < 0) {
        _railAccumulated = 0;
        _setRailCollapsed(false, notification);
        return false;
      }
      if (delta <= 0) {
        _railAccumulated = 0;
        return false;
      }
      _railAccumulated += delta;
      if (!_railCollapsed && _railAccumulated > _directionThreshold) {
        _setRailCollapsed(true, notification);
      }
    } else if (notification is OverscrollNotification &&
        notification.overscroll < 0 &&
        notification.metrics.pixels <= 4 &&
        _railCollapsed) {
      _setRailCollapsed(false, notification);
    }
    return false;
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (widget.collapsedHeader != null) return _onRailScroll(notification);
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
    final rail = widget.collapsedHeader;
    if (rail != null) {
      return Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && event.scrollDelta.dy < 0) {
            _revealRailAtTop();
          }
        },
        child: Focus(
          onKeyEvent: (_, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                    event.logicalKey == LogicalKeyboardKey.pageUp ||
                    event.logicalKey == LogicalKeyboardKey.home)) {
              _revealRailAtTop();
            }
            return KeyEventResult.ignored;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: Column(
              children: [
                // One mounted header at a time: a crossfade would leave duplicate
                // focusable search/filter controls during the transition.
                SizedBox(
                  key: _railKey,
                  child: KeyedSubtree(
                    key: const ValueKey('collapsible_header'),
                    child: _railCollapsed
                        ? KeyedSubtree(
                            key: const ValueKey('collapsed_rail'),
                            child: rail,
                          )
                        : KeyedSubtree(
                            key: const ValueKey('expanded_header'),
                            child: widget.header,
                          ),
                  ),
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ),
      );
    }
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
