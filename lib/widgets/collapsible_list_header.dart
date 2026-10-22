import 'dart:ui';

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
  late final AnimationController _railOverlay = AnimationController(
    vsync: this,
  );
  late final CurvedAnimation _railOverlayCurve = CurvedAnimation(
    parent: _railOverlay,
    curve: AppMotionCurve.decelerate,
  );

  @override
  void dispose() {
    _animController?.dispose();
    _railOverlayCurve.dispose();
    _railOverlay.dispose();
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
  double? _railListTop;
  int _railTransition = 0;
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
    if (_railCollapsed == collapsed) return;
    final height = _railKey.currentContext?.size?.height ?? 0;
    // Keep short lists expanded: reclaiming header height must not erase
    // their scroll range and strand the person in the compact mode.
    if (collapsed &&
        (notification.metrics.maxScrollExtent <= height ||
            notification.metrics.pixels < height)) {
      return;
    }
    _adjustingRail = true;
    _railTransition++;
    _railOverlay.duration = AppMotion.duration(
      context,
      AppMotionDuration.standard,
    );
    if (_railOverlay.duration == Duration.zero) {
      _railOverlay.value = collapsed ? 1 : 0;
    } else {
      _railOverlay.animateTo(collapsed ? 1 : 0);
    }
    setState(() => _railCollapsed = collapsed);
    if (AppMotion.duration(context, AppMotionDuration.standard) ==
        Duration.zero) {
      _finishRailTransition();
    }
  }

  void _finishRailTransition() {
    final transition = _railTransition;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || transition != _railTransition) return;
      _adjustingRail = false;
    });
  }

  void _correctRailOrigin(double top) {
    final previousTop = _railListTop;
    _railListTop = top;
    final scrollContext = _lastRailScroll?.context;
    if (_adjustingRail &&
        _railCollapsed &&
        previousTop != null &&
        scrollContext != null &&
        scrollContext.mounted) {
      final position = Scrollable.maybeOf(scrollContext)?.position;
      if (position != null &&
          position.hasContentDimensions &&
          !position.outOfRange) {
        final target = (position.pixels + top - previousTop).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        // Layout correction preserves the held drag and fling activity.
        position.correctBy(target - position.pixels);
      }
    }
  }

  /// Collapsed-rail mode: expand only at the true top (or by pulling down
  /// there); collapse after a deliberate downward scroll; ignore upward
  /// scrolling in between.
  bool _onRailScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
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
      final duration = AppMotion.duration(context, AppMotionDuration.standard);
      final activeHeader = KeyedSubtree(
        key: ValueKey(_railCollapsed ? 'collapsed_rail' : 'expanded_header'),
        child: _railCollapsed ? rail : widget.header,
      );
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
            child: CustomMultiChildLayout(
              delegate: _SearchRailLayout(
                _railOverlayCurve,
                _correctRailOrigin,
              ),
              children: [
                LayoutId(id: _RailSlot.list, child: widget.child),
                LayoutId(
                  id: _RailSlot.fog,
                  child: IgnorePointer(
                    child: FadeTransition(
                      opacity: _railOverlayCurve,
                      child: const _SearchRailFog(),
                    ),
                  ),
                ),
                LayoutId(
                  id: _RailSlot.header,
                  child: ClipRect(
                    key: _railKey,
                    child: duration == Duration.zero
                        ? KeyedSubtree(
                            key: const ValueKey('collapsible_header'),
                            child: activeHeader,
                          )
                        : AnimatedSize(
                            key: const ValueKey('collapsible_header'),
                            duration: duration,
                            curve: AppMotionCurve.decelerate,
                            alignment: Alignment.topCenter,
                            onEnd: _finishRailTransition,
                            child: AnimatedSwitcher(
                              duration: duration,
                              layoutBuilder: (current, previous) => Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: [
                                  for (final outgoing in previous)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: IgnorePointer(
                                        child: ExcludeFocus(
                                          child: ExcludeSemantics(
                                            child: outgoing,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ?current,
                                ],
                              ),
                              child: activeHeader,
                            ),
                          ),
                  ),
                ),
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

// Paint the list first, then the frost and controls. A translucent Column
// sibling cannot blur a list that is laid out entirely below it.
enum _RailSlot { list, fog, header }

class _SearchRailLayout extends MultiChildLayoutDelegate {
  _SearchRailLayout(this.overlay, this.correctOrigin)
    : super(relayout: overlay);
  final Animation<double> overlay;
  final ValueChanged<double> correctOrigin;

  @override
  void performLayout(Size size) {
    final header = layoutChild(
      _RailSlot.header,
      BoxConstraints.tightFor(width: size.width),
    );
    final top = header.height * (1 - overlay.value);
    correctOrigin(top);
    layoutChild(
      _RailSlot.list,
      BoxConstraints.tight(Size(size.width, size.height - top)),
    );
    positionChild(_RailSlot.list, Offset(0, top));
    layoutChild(
      _RailSlot.fog,
      BoxConstraints.tight(Size(size.width, header.height + 32)),
    );
    positionChild(_RailSlot.fog, Offset.zero);
    positionChild(_RailSlot.header, Offset.zero);
  }

  @override
  bool shouldRelayout(_SearchRailLayout oldDelegate) => true;
}

class _SearchRailFog extends StatelessWidget {
  const _SearchRailFog();
  @override
  Widget build(BuildContext context) => ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: AppGlassBlur.medium,
        sigmaY: AppGlassBlur.medium,
      ),
      child: CustomPaint(painter: _FogMaskPainter()),
    ),
  );
}

class _FogMaskPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mask inside the backdrop layer. An enclosing ShaderMask introduces a
    // separate offscreen surface, so the filter cannot sample the list below.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_FogMaskPainter oldDelegate) => false;
}
