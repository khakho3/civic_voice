import '../widgets/in_app_notification_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_role.dart';
import '../models/notification_inbox.dart';
import 'api_client.dart';
import 'app_cache_service.dart';
import 'mock_auth_service.dart';
import '../features/maintenance/services/maintenance_session.dart';

class InboxOwner {
  const InboxOwner(this.key, this.role);
  final String key;
  final AppRole role;
}

InboxOwner? currentInboxOwner() {
  if (Firebase.apps.isEmpty) return null;
  final user = FirebaseAuth.instance.currentUser;
  final auth = MockAuthService();
  final role = auth.getCurrentRole();
  if (user == null || role == null || auth.mustChangePasswordOnFirstLogin()) {
    return null;
  }
  return InboxOwner(
    '${user.uid}|${AppCacheService.instance.sessionGeneration}|${role.name}|${auth.getCurrentAdminTier()?.name}|${auth.getCurrentRegion()?.name}|${auth.getCurrentAssembly()?.fullName}|${MaintenanceSession.instance.profile.value.teamId}',
    role,
  );
}

enum InboxStatus { idle, loading, ready, error }

/// The API owns notification history and read/dismiss state. No local fallback.
class NotificationInboxDirectory extends ChangeNotifier {
  NotificationInboxDirectory({
    required this.owner,
    required this.token,
    required this.list,
    required this.write,
  });
  static final instance = NotificationInboxDirectory(
    owner: currentInboxOwner,
    token: () async => Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser?.getIdToken(),
    list: (token, cursor) =>
        ApiClient.instance.notificationInbox(idToken: token, cursor: cursor),
    write: (token, ids, action) => ApiClient.instance.notificationAction(
      idToken: token,
      ids: ids,
      action: action,
    ),
  );
  final InboxOwner? Function() owner;
  final Future<String?> Function() token;
  final Future<Map<String, dynamic>> Function(String, String?) list;
  final Future<Map<String, dynamic>> Function(String, List<String>, String)
  write;
  InboxOwner? _snapshotOwner;
  InboxPage? _page;
  InboxStatus _status = InboxStatus.idle;
  int _revision = 0;
  bool _writing = false, _uncertain = false;
  String? _error;
  List<String?> _cursors = [null];
  bool get current =>
      owner()?.key == _snapshotOwner?.key && _snapshotOwner != null;
  InboxPage? get page => current ? _page : null;
  InboxStatus get status => current ? _status : InboxStatus.idle;
  bool get writing => current && _writing;
  bool get uncertain => current && _uncertain;
  String? get error => current ? _error : null;
  bool get canPrevious => current && _cursors.length > 1;
  bool get canNext => page?.nextCursor != null;
  // Keep the last verified badge while refreshing this same owner.
  int get unreadCount => page?.unreadCount ?? 0;
  void clearSession() {
    InAppNotificationBanner.dismiss();
    ++_revision;
    _snapshotOwner = null;
    _page = null;
    _status = InboxStatus.idle;
    _writing = false;
    _uncertain = false;
    _error = null;
    _cursors = [null];
    notifyListeners();
  }

  bool _owns(String key, int revision) =>
      owner()?.key == key &&
      _snapshotOwner?.key == key &&
      revision == _revision;
  Future<void> refresh({bool reset = false}) async {
    final identity = owner();
    if (identity == null) {
      clearSession();
      return;
    }
    if (_snapshotOwner?.key != identity.key) {
      clearSession();
      _snapshotOwner = identity;
    }
    if (_writing) return;
    if (reset) _cursors = [null];
    final revision = ++_revision;
    _status = InboxStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final credential = await token();
      if (!_owns(identity.key, revision)) return;
      if (credential == null) throw StateError('Sign in required');
      final data = await list(credential, _cursors.last);
      if (!_owns(identity.key, revision)) return;
      _page = InboxPage.parse(data, identity.role);
      _status = InboxStatus.ready;
      _uncertain = false;
    } catch (_) {
      if (!_owns(identity.key, revision)) return;
      _page = null;
      _status = InboxStatus.error;
      _error =
          'Your inbox could not be verified. Please refresh and try again.';
    }
    if (_owns(identity.key, revision)) notifyListeners();
  }

  Future<void> next() async {
    if (writing || uncertain || status != InboxStatus.ready || !canNext) return;
    if (_cursors.contains(page!.nextCursor)) {
      _error = 'This inbox page could not be verified. Refresh your inbox.';
      _uncertain = true;
      notifyListeners();
      return;
    }
    _cursors = [..._cursors, page!.nextCursor];
    await refresh();
  }

  Future<void> previous() async {
    if (writing || uncertain || !canPrevious) return;
    _cursors = _cursors.sublist(0, _cursors.length - 1);
    await refresh();
  }

  Future<bool> act(List<String> ids, String action) async {
    if (writing ||
        uncertain ||
        status != InboxStatus.ready ||
        ids.isEmpty ||
        ids.length > 50 ||
        !['read', 'unread', 'dismiss'].contains(action) ||
        ids.toSet().length != ids.length ||
        ids.any((id) => !page!.rows.any((row) => row.id == id))) {
      return false;
    }
    final identity = _snapshotOwner!;
    final revision = _revision;
    final frozen = List<String>.unmodifiable(ids);
    _writing = true;
    _error = null;
    notifyListeners();
    try {
      final credential = await token();
      if (!_owns(identity.key, revision)) return false;
      if (credential == null) throw StateError('Sign in required');
      final response = await write(credential, frozen, action);
      if (!_owns(identity.key, revision)) return false;
      final count = response['updated'];
      if (count is! int || count < 0 || count > frozen.length) {
        throw const FormatException('Unverified write');
      }
      _writing = false;
      await refresh();
      return current &&
          owner()?.key == identity.key &&
          status == InboxStatus.ready &&
          count == frozen.length;
    } catch (_) {
      if (_owns(identity.key, revision)) {
        _writing = false;
        _uncertain = true;
        _error =
            'This change could not be confirmed. Refresh your inbox before trying again.';
        notifyListeners();
      }
      return false;
    } finally {
      if (_owns(identity.key, revision) && _writing) {
        _writing = false;
        notifyListeners();
      }
    }
  }
}
