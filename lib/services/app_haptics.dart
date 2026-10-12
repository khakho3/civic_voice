import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_cache_service.dart';

/// The single entry point for optional action haptics (F09).
///
/// Call [activate] when the user deliberately activates an action — a
/// confirm button, a navigation destination, a menu choice, a toggle. Never
/// call it for typing, scrolling, loading, completion, or a disabled
/// control; feedback describes the tap, not the result.
///
/// The device-local opt-out lives in [AppCacheService.hapticFeedbackEnabled]
/// (edited from every Profile's Haptic feedback row). The OS still decides
/// whether a pulse is felt: Android honours the system touch-vibration
/// setting and some devices have no vibrator, and Flutter cannot detect
/// either. A missing or refused pulse is therefore silent and never fails
/// or delays the action that triggered it.
abstract final class AppHaptics {
  const AppHaptics._();

  /// Pulses closer together than this collapse into one, so a control that
  /// both closes a menu and confirms a choice cannot double-buzz.
  static const Duration minimumInterval = Duration(milliseconds: 80);

  static DateTime? _lastPulse;

  /// Whether the user has left haptic feedback on.
  static bool get enabled => AppCacheService.instance.hapticFeedbackEnabled;

  /// Plays one gentle selection pulse if enabled. Fire-and-forget: callers
  /// do not await it, and any platform error is swallowed.
  static void activate() {
    if (!enabled) return;
    final now = DateTime.now();
    final last = _lastPulse;
    if (last != null && now.difference(last) < minimumInterval) return;
    _lastPulse = now;
    HapticFeedback.selectionClick().catchError((Object _) {});
  }

  /// Clears the throttle between tests.
  @visibleForTesting
  static void resetForTest() => _lastPulse = null;
}
