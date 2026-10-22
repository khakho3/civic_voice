import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// One native sheet route: a quiet feathered edge, readable surface and
/// direction-aware motion. Keep the framework's barrier, Back and drag handling.
Future<T?> showCivicBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool showDragHandle = true,
  bool enableDrag = true,
  bool form = false,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  backgroundColor: Colors.transparent,
  elevation: 0,
  clipBehavior: Clip.none,
  showDragHandle: false,
  enableDrag: enableDrag,
  sheetAnimationStyle: AnimationStyle(
    duration: AppMotion.duration(context, AppMotionDuration.standard),
    reverseDuration: AppMotion.duration(context, AppMotionDuration.fast),
  ),
  builder: (context) => CivicSheetSurface(
    form: form,
    showDragHandle: showDragHandle,
    enableDrag: enableDrag,
    child: builder(context),
  ),
);

class CivicSheetSurface extends StatelessWidget {
  const CivicSheetSurface({
    super.key,
    required this.child,
    this.form = false,
    this.showDragHandle = true,
    this.enableDrag = true,
  });
  final Widget child;
  final bool form;
  final bool showDragHandle;
  final bool enableDrag;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -24,
          left: 0,
          right: 0,
          height: 48,
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppGlassBlur.small,
                    sigmaY: AppGlassBlur.small,
                  ),
                  child: CustomPaint(painter: _SheetEdgeMask()),
                ),
              ),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: AppComponentRadius.bottomSheet,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppGlassBlur.small,
              sigmaY: AppGlassBlur.small,
            ),
            child: Material(
              color: form
                  ? Theme.of(context).colorScheme.surface
                  : semantic.glassSurface,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDragHandle)
                    if (enableDrag)
                      Semantics(
                        label: 'Drag down to close',
                        child: SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.outline,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Align(
                        alignment: Alignment.centerRight,
                        child: CloseButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                  Flexible(fit: FlexFit.loose, child: child),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetEdgeMask extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mask within the backdrop layer so it can still sample the page below.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white],
          stops: [0, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SheetEdgeMask oldDelegate) => false;
}
