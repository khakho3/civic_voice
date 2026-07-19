import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests the OS notification permission at most once per install.
///
/// Firebase Cloud Messaging registration is handled centrally after this
/// permission decision. Persisting "asked" locally means the explanatory
/// prompt is shown once, while every notification screen still exposes the
/// current OS state and a direct Enable/Settings action.
class NotificationPermissionService {
  const NotificationPermissionService();

  // Versioned because the original citizen-only prompt could mark itself
  // asked without ever reaching the OS dialog. V2 is the first app-wide,
  // post-login permission explanation for every authenticated role.
  static const _askedKey = 'notification_permission_prompted_v2';

  Future<bool> hasAskedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_askedKey) ?? false;
  }

  Future<PermissionStatus> requestOnce() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
    return Permission.notification.request();
  }

  Future<void> markAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_askedKey, true);
  }

  Future<PermissionStatus> currentStatus() => Permission.notification.status;

  Future<bool> openSettings() => openAppSettings();
}
