import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_haptics.dart';
import 'glass_dialog_backdrop.dart';

/// Shows a confirm/cancel [AlertDialog] and resolves to whether the user
/// confirmed — `false` for both "Cancel" and dismissing the dialog (tap
/// outside, back button), so callers never need to distinguish the two.
///
/// Global (`lib/widgets/`), not module-scoped: important-action
/// confirmation applies the same way across every module, not just
/// System Administrator. [destructive] fills the confirm button with the
/// error red and white ink for actions that remove access or apply changes
/// that are hard to walk back (deactivating an account, saving
/// platform-wide settings) — leave it false for lower-stakes
/// confirmations (signing out). Callers never pass their own colors, so
/// every role renders the same pair in both themes.
///
/// Actions are compact and trailing: each button keeps its intrinsic width
/// and the 48px control height, and [AlertDialog]'s overflow bar stacks
/// them (still trailing-aligned) when a narrow screen or large text scale
/// leaves no room side by side. An optional [icon] sits above the title.
///
/// While the dialog animates closed, its route ignores pointer and focus
/// input (Flutter's `ModalRoute` does this during the reverse animation),
/// so a rapid second tap cannot fire a second decision.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => GlassDialogBackdrop(
      child: _ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        icon: icon,
      ),
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = AppSemanticColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      icon: icon == null
          ? null
          : _ConfirmIcon(icon: icon!, destructive: destructive),
      title: Text(title),
      content: Text(message),
      actionsAlignment: MainAxisAlignment.end,
      actionsOverflowAlignment: OverflowBarAlignment.end,
      actionsOverflowButtonSpacing: AppSpacing.sm,
      actions: [
        TextButton(
          // Dark theme keeps Cancel neutral so the gold/red confirm is the
          // single emphasized action (web confirm-dialog.css parity).
          style: isDark
              ? TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: semantic.error,
                  foregroundColor: semantic.onError,
                )
              : null,
          onPressed: () {
            AppHaptics.activate();
            Navigator.of(context).pop(true);
          },
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}

class _ConfirmIcon extends StatelessWidget {
  const _ConfirmIcon({required this.icon, required this.destructive});

  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final semantic = AppSemanticColors.of(context);
    final hue = destructive ? semantic.error : semantic.actionFill;
    final ink = destructive ? semantic.errorText : semantic.actionText;

    return ExcludeSemantics(
      child: Container(
        width: AppIconSize.xl,
        height: AppIconSize.xl,
        decoration: BoxDecoration(
          color: hue.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: AppIconSize.standard, color: ink),
      ),
    );
  }
}
