import 'dart:async';
import 'package:flutter/material.dart';
import 'busy_indicator.dart';

enum AsyncActionKind { filled, outlined, text }

/// Keeps async retry/refresh feedback in its own button, with a stable label
/// footprint and no overlapping requests. The caller owns the resulting data.
class AsyncActionButton extends StatefulWidget {
  const AsyncActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style,
    this.kind = AsyncActionKind.filled,
  });
  final String label;
  final FutureOr<void> Function()? onPressed;
  final ButtonStyle? style;
  final AsyncActionKind kind;
  @override
  State<AsyncActionButton> createState() => _AsyncActionButtonState();
}

class _AsyncActionButtonState extends State<AsyncActionButton> {
  bool _busy = false;
  bool _failed = false;
  Future<void> _run() async {
    if (_busy || widget.onPressed == null) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.onPressed!();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final callback = _busy || widget.onPressed == null ? null : _run;
    final label = BusyLabel(
      busy: _busy,
      busyLabel: '${widget.label}. Please wait.',
      child: Text(widget.label),
    );
    final button = switch (widget.kind) {
      AsyncActionKind.filled => FilledButton(
        style: widget.style,
        onPressed: callback,
        child: label,
      ),
      AsyncActionKind.outlined => OutlinedButton(
        style: widget.style,
        onPressed: callback,
        child: label,
      ),
      AsyncActionKind.text => TextButton(
        style: widget.style,
        onPressed: callback,
        child: label,
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        button,
        if (_failed)
          Semantics(
            liveRegion: true,
            child: Text(
              'Could not complete this action. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
