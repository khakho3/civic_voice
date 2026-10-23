import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../../models/app_role.dart';
import '../../../services/mock_auth_service.dart';
import '../../../services/notification_inbox_directory.dart';
import '../models/admin_role_management_data.dart';

String? adminRequestKey() {
  final owner = currentInboxOwner();
  return owner?.role == AppRole.systemAdministrator ? owner!.key : null;
}

bool get verifiedSuperAdmin =>
    adminRequestKey() != null &&
    MockAuthService().getCurrentAdminTier() == AdminTier.superAdmin;

/// Shared lifecycle for scoped Admin reads and versioned, acknowledged writes.
class AdminResource<T> extends ChangeNotifier {
  AdminResource({
    required this.fetch,
    required this.parse,
    String? Function()? owner,
    Future<String?> Function()? credential,
  }) : owner = owner ?? adminRequestKey,
       credential =
           credential ??
           (() async => FirebaseAuth.instance.currentUser?.getIdToken());
  final Future<Map<String, dynamic>> Function(String token) fetch;
  final T Function(Map<String, dynamic>) parse;
  final String? Function() owner;
  final Future<String?> Function() credential;
  T? _data;
  String? _key;
  int _revision = 0;
  bool _loading = false,
      _writing = false,
      _uncertain = false,
      _disposed = false;
  String? _error;
  bool get _current => !_disposed && _key != null && owner() == _key;
  T? get data => _current ? _data : null;
  bool get loading => _current && _loading;
  bool get writing => _current && _writing;
  bool get uncertain => _current && _uncertain;
  String? get error => _current ? _error : null;
  bool _owns(String key, int revision) =>
      _current && _key == key && _revision == revision;
  void clearSession() {
    ++_revision;
    _key = null;
    _data = null;
    _loading = false;
    _writing = false;
    _uncertain = false;
    _error = null;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }

  Future<void> load() async {
    if (_disposed) return;
    final key = owner();
    if (key == null) {
      clearSession();
      return;
    }
    if (key != _key) {
      clearSession();
      _key = key;
    }
    if (_writing) return;
    final revision = ++_revision;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final token = await credential();
      if (!_owns(key, revision)) return;
      if (token == null) throw StateError('Sign in required');
      final raw = await fetch(token);
      if (!_owns(key, revision)) return;
      _data = parse(raw);
      _uncertain = false;
    } catch (_) {
      if (!_owns(key, revision)) return;
      _data = null;
      _error =
          'This information could not be verified. Please refresh and try again.';
    } finally {
      if (_owns(key, revision)) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> mutate(
    Future<void> Function(String token, T previous) operation, {
    bool Function(T refreshed)? verify,
  }) async {
    if (!_current || _data == null || _loading || _writing || _uncertain) {
      return false;
    }
    final key = _key!, revision = _revision, previous = _data as T;
    _writing = true;
    _error = null;
    notifyListeners();
    try {
      final token = await credential();
      if (!_owns(key, revision)) return false;
      if (token == null) throw StateError('Sign in required');
      await operation(token, previous);
      if (!_owns(key, revision)) return false;
      _writing = false;
      await load();
      final ready =
          _current &&
          _key == key &&
          !_loading &&
          _error == null &&
          _data != null;
      if (!ready) return false;
      if (verify != null && !verify(_data as T)) {
        _uncertain = true;
        _error =
            'The saved state could not be verified. Reload before trying again.';
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      if (_owns(key, revision)) {
        _writing = false;
        _uncertain = true;
        _error =
            'The change could not be confirmed, or this item changed. Reload before trying again.';
        notifyListeners();
      }
      return false;
    } finally {
      if (_owns(key, revision) && _writing) {
        _writing = false;
        notifyListeners();
      }
    }
  }
}
