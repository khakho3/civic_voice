import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'glass_dialog_backdrop.dart';

/// A compact profile-section help action that keeps explanatory copy out of
/// the main page while preserving it in the same glass dialog treatment used
/// by confirmation dialogs.
class ProfileInfoButton extends StatelessWidget {
  const ProfileInfoButton({
    super.key,
    required this.title,
    required this.message,
    this.items = const <String>[],
  });

  final String title;
  final String message;
  final List<String> items;

  Future<void> _showInfo(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => GlassDialogBackdrop(
        child: AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (items.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppSemanticColors.of(context).actionText,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compact glyph, full 48px touch target. Inside a switch row it takes
    // the tap itself, so opening help never toggles the switch.
    return IconButton(
      onPressed: () => _showInfo(context),
      tooltip: 'About $title',
      iconSize: AppIconSize.md,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      constraints: const BoxConstraints.tightFor(
        width: AppDimensions.controlHeightStandard,
        height: AppDimensions.controlHeightStandard,
      ),
      icon: const Icon(AppIcons.info),
    );
  }
}
