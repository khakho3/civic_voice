import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Shows a confirm/cancel [AlertDialog] and resolves to whether the user
/// confirmed — `false` for both "Cancel" and dismissing the dialog (tap
/// outside, back button), so callers never need to distinguish the two.
///
/// Global (`lib/widgets/`), not module-scoped: important-action
/// confirmation applies the same way across every module, not just
/// System Administrator. [destructive] tints the confirm button
/// [AppColors.error] for actions that remove access or apply changes
/// that are hard to walk back (deactivating an account, saving
/// platform-wide settings) — leave it false for lower-stakes
/// confirmations (signing out).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
