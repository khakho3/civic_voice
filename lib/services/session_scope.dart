import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'api_client.dart';
import 'app_cache_service.dart';
import 'auth_transitions.dart';

/// An open UI action belongs to both its SDK session and its local namespace.
class SessionScope {
  SessionScope.capture({AuthSessionFence? auth})
    : _auth = auth ?? AuthSessionFence.capture(currentUid: _uid),
      _generation = AppCacheService.instance.sessionGeneration;

  final AuthSessionFence _auth;
  final int _generation;

  static String? _uid() => Firebase.apps.isEmpty
      ? AppCacheService.instance.activeAccountId
      : FirebaseAuth.instance.currentUser?.uid;

  bool get isCurrent =>
      _auth.isCurrent &&
      _generation == AppCacheService.instance.sessionGeneration;

  void check() {
    if (!isCurrent) {
      throw const ApiException(
        statusCode: 401,
        message: 'Your session changed. Please sign in again.',
      );
    }
  }
}
