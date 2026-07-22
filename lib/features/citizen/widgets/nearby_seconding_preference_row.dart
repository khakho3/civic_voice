import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/app_cache_service.dart';
import '../../../widgets/glass_dialog_backdrop.dart';

class NearbySecondingPreferenceRow extends StatefulWidget {
  const NearbySecondingPreferenceRow({super.key});

  @override
  State<NearbySecondingPreferenceRow> createState() =>
      _NearbySecondingPreferenceRowState();
}

class _NearbySecondingPreferenceRowState
    extends State<NearbySecondingPreferenceRow> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = AppCacheService.instance.nearbySecondingEnabled;
  }

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
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _enabled,
        onChanged: _setEnabled,
        title: Row(
          children: [
            Flexible(
              child: Text(
                'Nearby Reports',
                style: textTheme.bodyLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton(
              onPressed: _showHelp,
              tooltip: 'About Nearby Reports',
              iconSize: AppIconSize.sm,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
              ),
              icon: const Icon(AppIcons.info),
            ),
          ],
        ),
      ),
    );
  }
}
