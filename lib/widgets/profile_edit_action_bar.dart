import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Sticky bottom Cancel/Save bar for a profile screen's edit mode — sits
/// below the scrollable content, not as its last item, so it stays
/// reachable without scrolling all the way down a long form to find it.
/// The one shape every module's profile screen now shares (previously
/// Admin/Municipal/Ministry each built a slightly different version of the
/// same idea).
class ProfileEditActionBar extends StatelessWidget {
  const ProfileEditActionBar({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  final VoidCallback? onCancel;
  final VoidCallback? onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        safeAreaBottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: saving ? null : onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilledButton(
              onPressed: saving ? null : onSave,
              child: saving
                  ? const SizedBox(
                      width: AppIconSize.sm,
                      height: AppIconSize.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
