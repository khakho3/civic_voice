import 'package:flutter/material.dart';

import '../../../services/app_cache_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: _enabled,
        onChanged: _setEnabled,
        title: Text('Nearby report confirmations', style: textTheme.bodyLarge),
        subtitle: const Text(
          "Show a card when you're near an unconfirmed report you could help verify",
        ),
      ),
    );
  }
}
