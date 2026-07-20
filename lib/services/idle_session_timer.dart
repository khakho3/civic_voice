import 'dart:async';

import 'package:flutter/foundation.dart';

import '../features/admin/services/admin_system_settings_directory.dart';
import 'app_cache_service.dart';

/// Real, app-wide idle-timeout — [AdminSystemSettingsDirectory]'s Session
/// Timeout setting decides how long the app can sit untouched before
/// [onExpire] fires. A `Listener` wrapping the whole app (see
/// `main.dart`'s `_CivicVoiceAppState`) calls [registerActivity] on every
/// pointer event; the actual sign-out/navigation lives in `main.dart`
/// since only the app shell holds a `Navigator` to act through — this
/// class only owns the timer itself.
///
/// [onExpire] is only set while an app instance is actually mounted (see
/// `_CivicVoiceAppState.dispose`), so a stray fire can never reach a torn-
/// down widget tree.
class IdleSessionTimer {
  IdleSessionTimer._();

  static final IdleSessionTimer instance = IdleSessionTimer._();

  Timer? _timer;

  /// Set by the app shell; null (and therefore inert) whenever no
  /// [CivicVoiceApp] is mounted to act on it.
  VoidCallback? onExpire;

  void registerActivity() {
    if (AppCacheService.instance.keepSignedIn) {
      cancel();
      return;
    }
    _timer?.cancel();
    final callback = onExpire;
    if (callback == null) return;
    _timer = Timer(_currentDuration(), callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  static Duration _currentDuration() => parseSessionTimeout(
    AdminSystemSettingsDirectory.instance.settings.value.sessionTimeout,
  );

  /// Exposed for tests — parses labels like "30 minutes" into a
  /// [Duration], defaulting to 30 minutes for anything unrecognized.
  @visibleForTesting
  static Duration parseSessionTimeout(String label) {
    final minutes = int.tryParse(label.split(' ').first) ?? 30;
    return Duration(minutes: minutes);
  }
}
