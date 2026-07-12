import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Wraps a fixed header (search field, filter chips) above a scrollable
/// list. The header — and, optionally, a second section below it — slides
/// out of the way as the user scrolls, tracking the drag 1:1 the way a
/// native app bar does (e.g. X/Twitter's): pushed up and out on the way
/// down, pulled back down on the way up, snapping to fully open or fully
/// closed on release. This is a real translation with the vacated space
/// reclaimed as it happens, so the list is genuinely pushed up underneath
/// — never just covered by chrome floating on top of it — and it's driven
/// directly off scroll deltas rather than a fixed-duration animation
/// re-triggered after the fact, so it never feels laggy or disconnected
/// from the gesture.
///
/// [revealAtTopSection] is for content that should be more conservative
/// about reappearing than [header] — e.g. a stats row that only comes back
/// once the user has scrolled all the way back to the top, rather than
/// tracking every small upward drag the way [header] does. It hides in
/// lockstep with [header] on the way down, but stays hidden through any
/// partial scroll-up and only slides back once the list is truly at the
/// top. It renders below [header]; pass `null` if a screen doesn't need it.
class CollapsibleListHeader extends StatefulWidget {
  const CollapsibleListHeader({
    super.key,
    required this.header,
    required this.child,
    this.revealAtTopSection,
  });

  final Widget header;
  final Widget child;
  final Widget? revealAtTopSection;

  @override
  State<CollapsibleListHeader> createState() => _CollapsibleListHeaderState();
}

class _CollapsibleListHeaderState extends State<CollapsibleListHeader>
    with TickerProviderStateMixin {
  final GlobalKey _headerContentKey = GlobalKey();
  final GlobalKey _topSectionContentKey = GlobalKey();

  double _headerHide = 0;
  double _topSectionHide = 0;
  bool _atTop = true;

  // Cached rather than read live off RenderBox.size: scroll notifications
  // (in particular ScrollEndNotification, dispatched while the viewport is
  // still settling its dimensions) can arrive synchronously from *inside*
  // a layout pass, and reading an arbitrary RenderBox's size mid-layout
  // trips Flutter's sizeAccessAllowed assertion. Measuring only ever
  // happens in a post-frame callback, once layout has fully settled.
  double? _headerHeight;
  double? _topSectionHeight;

  AnimationController? _headerSnapController;
  AnimationController? _topSectionRevealController;

  // Resizing the Expanded list's viewport as our own snap/reveal animation
  // plays can shrink the list's own maxScrollExtent enough that Flutter's
  // scroll machinery forces `pixels` back toward 0 to stay in range (most
  // visible on short lists, where collapsing the chrome frees up most of
  // the remaining scroll range). That self-inflicted correction arrives as
  // its own ScrollStartNotification/Update/End trio — but, unlike a real
  // user gesture, it starts with `dragDetails: null` on the
  // ScrollStartNotification itself (nothing actually touched the screen to
  // kick it off). Tracking that per-activity, rather than per-notification,
  // is what makes this reliable: a genuine drag's *momentum tail* also
  // reports `dragDetails: null` on its individual update notifications, so
  // gating each notification in isolation would wrongly distrust real fling
  // scrolling too.
  bool _trustCurrentActivity = true;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(covariant CollapsibleListHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.header != widget.header ||
        oldWidget.revealAtTopSection != widget.revealAtTopSection) {
      _scheduleMeasure();
    }
  }

  @override
  void dispose() {
    _headerSnapController?.dispose();
    _topSectionRevealController?.dispose();
    super.dispose();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final newHeaderHeight = _readSize(_headerContentKey);
      final newTopSectionHeight = _readSize(_topSectionContentKey);
      final changed =
          (newHeaderHeight != null && newHeaderHeight != _headerHeight) ||
          (newTopSectionHeight != null &&
              newTopSectionHeight != _topSectionHeight);
      if (changed) {
        setState(() {
          _headerHeight = newHeaderHeight ?? _headerHeight;
          _topSectionHeight = newTopSectionHeight ?? _topSectionHeight;
        });
      }
    });
  }

  double? _readSize(GlobalKey key) {
    final renderObject = key.currentContext?.findRenderObject();
    return renderObject is RenderBox && renderObject.hasSize
        ? renderObject.size.height
        : null;
  }

  void _animateHeaderTo(double target) {
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.duration(context, AppMotionDuration.fast),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: AppMotionCurve.decelerate,
    );
    final tween = Tween<double>(begin: _headerHide, end: target);
    controller.addListener(() {
      setState(() => _headerHide = tween.evaluate(animation));
    });
    _headerSnapController?.dispose();
    _headerSnapController = controller;
    controller.forward();
  }

  void _animateTopSectionTo(double target) {
    final controller = AnimationController(
      vsync: this,
      duration: AppMotion.duration(context, AppMotionDuration.standard),
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: AppMotionCurve.decelerate,
    );
    final tween = Tween<double>(begin: _topSectionHide, end: target);
    controller.addListener(() {
      setState(() => _topSectionHide = tween.evaluate(animation));
    });
    _topSectionRevealController?.dispose();
    _topSectionRevealController = controller;
    controller.forward();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Ignore anything that isn't the primary vertical list — a nested
    // horizontal scrollable (the filter-chip row inside [header]) bubbles
    // its own notifications up through this same listener otherwise.
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      _trustCurrentActivity = notification.dragDetails != null;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta;
      // Only ever driven by the user's actual finger — dragDetails is null
      // for physics-driven updates (fling momentum, and critically the
      // overscroll "spring back" once a short list hits its scroll
      // boundary), which would otherwise fight the snap that just ran and
      // drag the header back open right after it correctly hid.
      if (delta != null && notification.dragDetails != null) {
        // Track the drag 1:1 in both directions — cancel any in-flight
        // snap so a fresh drag always takes back over immediately.
        _headerSnapController?.dispose();
        _headerSnapController = null;
        final headerHeight = _headerHeight ?? 0;
        if (headerHeight > 0) {
          _headerHide = (_headerHide + delta).clamp(0.0, headerHeight);
        }

        // The top section only ever tracks the *hide* half of the same
        // gesture, staying in lockstep with the header as it pushes away.
        // It deliberately never creeps back open on a partial scroll-up —
        // only a genuine return to the top does that, handled below.
        if (delta > 0) {
          final topHeight = _topSectionHeight ?? 0;
          if (topHeight > 0) {
            _topSectionRevealController?.dispose();
            _topSectionRevealController = null;
            _topSectionHide = (_topSectionHide + delta).clamp(0.0, topHeight);
          }
        }

        setState(() {});
      }
    }

    // Collapsing the chrome can free up enough room that a short list now
    // fits its viewport entirely — maxScrollExtent drops to 0, `pixels`
    // gets clamped to 0, and from then on a downward drag produces only
    // OverscrollNotifications (clamping physics), never scroll updates.
    // Without handling these, the chrome would be stranded off-screen with
    // no gesture able to bring it back. A finger-driven pull-down at the
    // top boundary spends itself revealing the header 1:1 first, then the
    // top section — which is consistent with the at-top rule, because an
    // overscroll past the start IS the very top.
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0) {
      var pull = notification.overscroll;
      final headerHeight = _headerHeight ?? 0;
      if (headerHeight > 0 && _headerHide > 0) {
        _headerSnapController?.dispose();
        _headerSnapController = null;
        final newHide = (_headerHide + pull).clamp(0.0, headerHeight);
        pull += _headerHide - newHide;
        _headerHide = newHide;
      }
      final topHeight = _topSectionHeight ?? 0;
      if (topHeight > 0 && _topSectionHide > 0 && pull < 0) {
        _topSectionRevealController?.dispose();
        _topSectionRevealController = null;
        _topSectionHide = (_topSectionHide + pull).clamp(0.0, topHeight);
      }
      setState(() {});
    }

    if (notification is ScrollUpdateNotification && _trustCurrentActivity) {
      final atTop = notification.metrics.pixels <= 4;
      if (atTop != _atTop) {
        setState(() => _atTop = atTop);
        if (atTop) {
          if (_topSectionHide > 0) _animateTopSectionTo(0);
          if (_headerHide > 0) _animateHeaderTo(0);
        }
      }
    }

    if (notification is ScrollEndNotification && _trustCurrentActivity) {
      final atTop = notification.metrics.pixels <= 4;
      _atTop = atTop;
      if (atTop) {
        // Everything comes home at the top — and never the opposite: a
        // release at the top must not snap the header back toward hidden,
        // even if the drag left it more than half-way there.
        if (_headerHide > 0) _animateHeaderTo(0);
        if (_topSectionHide > 0) _animateTopSectionTo(0);
      } else {
        final headerHeight = _headerHeight ?? 0;
        if (headerHeight > 0 && _headerHide > 0 && _headerHide < headerHeight) {
          final target = _headerHide > headerHeight / 2 ? headerHeight : 0.0;
          _animateHeaderTo(target);
        }

        // Unlike the header, the top section only ever has one resting
        // point to snap toward away from the top: fully hidden. Revealing
        // it is exclusively the at-top mechanism's job — a drag that lifts
        // a finger mid-way through hiding it should still finish the hide,
        // not linger at whatever fraction the raw delta landed on.
        final topHeight = _topSectionHeight ?? 0;
        if (topHeight > 0 &&
            _topSectionHide > 0 &&
            _topSectionHide < topHeight) {
          _animateTopSectionTo(topHeight);
        }
      }
    }

    return false;
  }

  Widget _slidingSection({
    required Key sectionKey,
    required GlobalKey contentKey,
    required Widget child,
    required double hide,
    required double? measuredHeight,
  }) {
    if (hide <= 0 || measuredHeight == null) {
      return ClipRect(
        key: sectionKey,
        child: KeyedSubtree(key: contentKey, child: child),
      );
    }
    return ClipRect(
      key: sectionKey,
      child: SizedBox(
        height: (measuredHeight - hide).clamp(0.0, measuredHeight),
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: measuredHeight,
          maxHeight: measuredHeight,
          child: Transform.translate(
            offset: Offset(0, -hide),
            child: KeyedSubtree(key: contentKey, child: child),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Column(
        children: [
          _slidingSection(
            sectionKey: const ValueKey('collapsible_header'),
            contentKey: _headerContentKey,
            hide: _headerHide,
            measuredHeight: _headerHeight,
            child: widget.header,
          ),
          if (widget.revealAtTopSection != null)
            _slidingSection(
              sectionKey: const ValueKey('collapsible_top_section'),
              contentKey: _topSectionContentKey,
              hide: _topSectionHide,
              measuredHeight: _topSectionHeight,
              child: widget.revealAtTopSection!,
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
