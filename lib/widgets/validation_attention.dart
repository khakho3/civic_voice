import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reveal validation only after an attempted action, once inline errors exist.
/// Scheduled work cannot steal focus after navigation or a newer request.
abstract final class ValidationAttention {
  static final _requests = Expando<int>();

  static bool validate(GlobalKey<FormState> key) {
    final valid = key.currentState?.validate() ?? false;
    final context = key.currentContext;
    if (!valid && context != null) firstError(context);
    return valid;
  }

  static void firstError(BuildContext root) => _schedule(root, () {
    BuildContext? first;
    void visit(Element element) {
      if (first != null) return;
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) return;
      if (widget is InputDecorator &&
          widget.decoration.enabled &&
          (widget.decoration.errorText != null ||
              widget.decoration.error != null)) {
        first = element;
        return;
      }
      element.visitChildren(visit);
    }

    root.visitChildElements(visit);
    return first;
  });

  static void reveal(BuildContext root, GlobalKey target) =>
      _schedule(root, () => target.currentContext);

  static void _schedule(BuildContext root, BuildContext? Function() target) {
    final request = (_requests[root] ?? 0) + 1;
    _requests[root] = request;
    bool current() =>
        root.mounted &&
        _requests[root] == request &&
        (ModalRoute.of(root)?.isCurrent ?? true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!current()) return;
      final context = target();
      if (context == null || !context.mounted) return;
      FocusNode? node;
      FocusNode? actionNode;
      void visit(Element element) {
        final widget = element.widget;
        final candidate = Focus.maybeOf(element, createDependency: false);
        if (candidate != null &&
            candidate is! FocusScopeNode &&
            candidate.canRequestFocus) {
          actionNode ??= candidate;
        }
        if (widget is EditableText &&
            !widget.readOnly &&
            widget.focusNode.canRequestFocus) {
          node = widget.focusNode;
          return;
        }
        if (node == null) element.visitChildren(visit);
      }

      if (context is Element) visit(context);
      // Decorated dropdowns keep their Focus above the InputDecorator.
      if (node == null) {
        context.visitAncestorElements((element) {
          if (element.widget is Focus && element.widget is! FocusScope) {
            final candidate = (element.widget as Focus).focusNode;
            if (candidate?.canRequestFocus == true) {
              node = candidate;
              return false;
            }
          }
          return element != root;
        });
      }
      node ??= actionNode;
      if (node != null) {
        node!.requestFocus();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!current() ||
            !context.mounted ||
            (node != null && !node!.hasFocus)) {
          return;
        }
        Scrollable.ensureVisible(
          context,
          alignment: 0.25,
          duration: AppMotion.duration(context, AppMotionDuration.standard),
          curve: Curves.easeOut,
        );
      });
      WidgetsBinding.instance.ensureVisualUpdate();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
