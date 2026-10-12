import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../services/app_cache_service.dart';
import '../services/app_haptics.dart';
import 'profile_preference_row.dart';

/// Persisted, device-local opt-out for gentle action haptics (F09), shared
/// by all five Profiles. Turning it on plays one pulse as confirmation.
///
/// Flutter cannot tell whether the device has a vibrator or whether the
/// system touch-vibration setting is off, so the caption says honestly
/// that the device can still silence it rather than claiming support.
class HapticsPreferenceRow extends StatefulWidget {
  const HapticsPreferenceRow({super.key});

  @override
  State<HapticsPreferenceRow> createState() => _HapticsPreferenceRowState();
}

class _HapticsPreferenceRowState extends State<HapticsPreferenceRow> {
  late bool _enabled = AppCacheService.instance.hapticFeedbackEnabled;

  Future<void> _setEnabled(bool value) async {
    setState(() => _enabled = value);
    await AppCacheService.instance.setHapticFeedbackEnabled(value);
    if (value) AppHaptics.activate();
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSwitchRow(
      icon: AppIcons.haptics,
      label: 'Haptic feedback',
      caption: 'Your device settings can still turn vibration off.',
      value: _enabled,
      onChanged: _setEnabled,
      pulseOnToggle: false,
    );
  }
}
