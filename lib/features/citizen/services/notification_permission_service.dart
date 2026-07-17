import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests the OS notification permission at most once per install.
///
/// There's no push backend yet (no Firebase Cloud Messaging), so this only
/// gets the permission in place ahead of that work — it doesn't send
/// anything. Persisting "asked" locally means we never re-prompt after the
/// first decision, matching the location flow's "ask, don't nag" pattern.
class NotificationPermissionService {
  const NotificationPermissionService();

  static const _askedKey = 'notification_permission_asked';

  Future<bool> hasAskedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askedKey) ?? false;
  }

  Future<PermissionStatus> requestOnce() async {
    final status = await Permission.notification.request();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
    return status;
  }

  Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }
}
