import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/app_cache_service.dart';
import '../../../widgets/glass_dialog_backdrop.dart';
import '../../../widgets/profile_preference_row.dart';

/// Citizen-only Nearby Reports preference (P03): leading location icon,
/// switch, and an information dialog. It only controls whether the
/// dashboard offers one nearby report to confirm — no background location
/// tracking is promised or performed.
class NearbySecondingPreferenceRow extends StatefulWidget {
  const NearbySecondingPreferenceRow({super.key});

  @override
  State<NearbySecondingPreferenceRow> createState() =>
      _NearbySecondingPreferenceRowState();
}

class _NearbySecondingPreferenceRowState
    extends State<NearbySecondingPreferenceRow> {
  late bool _enabled = AppCacheService.instance.nearbySecondingEnabled;

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await AppCacheService.instance.setNearbySecondingEnabled(value);
  }

  Future<void> _showHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => GlassDialogBackdrop(
        child: AlertDialog(
          title: const Text('Nearby Reports'),
          content: const Text(
            'Shows one nearby report you can help confirm when you open the dashboard. Your location is not tracked in the background.',
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
    return ProfileSwitchRow(
      icon: AppIcons.location,
      label: 'Nearby Reports',
      value: _enabled,
      onChanged: _setEnabled,
      labelTrailing: IconButton(
        onPressed: _showHelp,
        tooltip: 'About Nearby Reports',
        iconSize: AppIconSize.md,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        icon: const Icon(AppIcons.info),
      ),
    );
  }
}
