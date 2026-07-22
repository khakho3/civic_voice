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
                          const Padding(
                            padding: EdgeInsets.only(top: 7),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.primary,
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
    return IconButton(
      onPressed: () => _showInfo(context),
      tooltip: 'About $title',
      iconSize: AppIconSize.sm,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(
        width: AppSpacing.xl,
        height: AppSpacing.xl,
      ),
      icon: const Icon(AppIcons.info),
    );
  }
}
