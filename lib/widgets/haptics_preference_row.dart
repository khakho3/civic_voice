import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../services/app_cache_service.dart';

/// Persisted, device-local opt-out for restrained action haptics.
class HapticsPreferenceRow extends StatefulWidget {
  const HapticsPreferenceRow({super.key});

  @override
  State<HapticsPreferenceRow> createState() => _HapticsPreferenceRowState();
}

class _HapticsPreferenceRowState extends State<HapticsPreferenceRow> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = AppCacheService.instance.hapticFeedbackEnabled;
  }

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await AppCacheService.instance.setHapticFeedbackEnabled(value);
    if (value) await HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          const Icon(Icons.vibration_outlined, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              onChanged: _setEnabled,
              title: Text(
                'Haptic feedback',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
