import 'package:firebase_auth/firebase_auth.dart';

import 'api_client.dart';

enum PasswordLoginFailure {
  credentials,
  throttled,
  offline,
  unavailable,
  account,
}

PasswordLoginFailure passwordLoginFailure(Object error) {
  if (error is ApiException) {
    return switch (error.statusCode) {
      401 => PasswordLoginFailure.credentials,
      403 => PasswordLoginFailure.account,
      429 => PasswordLoginFailure.throttled,
      // A connection failure/timeout says nothing about device internet access.
      0 || 408 => PasswordLoginFailure.unavailable,
      _ => PasswordLoginFailure.unavailable,
    };
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'network-request-failed' => PasswordLoginFailure.unavailable,
      'too-many-requests' => PasswordLoginFailure.throttled,
      // A rejected custom handoff is a service/project/session problem,
      // not proof that the password the API already verified was wrong.
      _ => PasswordLoginFailure.unavailable,
    };
  }
  return PasswordLoginFailure.unavailable;
}

class PasswordIdentity {
  const PasswordIdentity({required this.uid, required this.idToken});
  final String uid;
  final String idToken;
}

class PasswordSession {
  const PasswordSession({required this.uid, required this.user});
  final String uid;
  final SyncedUser user;
}

class PasswordChangedSignInRequired implements Exception {
  const PasswordChangedSignInRequired();
}

/// Server password verification -> Firebase custom-token exchange -> API sync.
/// Account UI/persistence is published only after this verified transaction.
class PasswordSessionService {
  PasswordSessionService({
    Future<String> Function(String phone, String password)? passwordLogin,
    Future<PasswordIdentity> Function(String token)? exchange,
    Future<SyncedUser> Function(String idToken)? sync,
    Future<void> Function(String idToken, String password)? changePassword,
  }) : _passwordLogin = passwordLogin ?? _requestHandoff,
       _exchange = exchange ?? _exchangeHandoff,
       _sync = sync ?? _syncAccount,
       _changePassword = changePassword ?? _changeAccountPassword;

  static final instance = PasswordSessionService();
  final Future<String> Function(String, String) _passwordLogin;
  final Future<PasswordIdentity> Function(String) _exchange;
  final Future<SyncedUser> Function(String) _sync;
  final Future<void> Function(String, String) _changePassword;
  static const _roles = {
    'CITIZEN',
    'MUNICIPAL',
    'MAINTENANCE',
    'MINISTRY',
    'ADMIN',
  };

  Future<PasswordSession> signIn({
    required String phone,
    required String password,
    String? expectedUid,
  }) async {
    final handoff = await _passwordLogin(phone, password);
    if (handoff.trim().isEmpty) throw _invalidSession;
    final identity = await _exchange(handoff);
    if (identity.uid.isEmpty ||
        identity.idToken.isEmpty ||
        (expectedUid != null && identity.uid != expectedUid)) {
      throw _invalidSession;
    }
    late final SyncedUser user;
    try {
      user = await _sync(identity.idToken);
    } on ApiException catch (error) {
      // The password was already verified. A rejected session/sync must not
      // be presented as an invalid password.
      if (error.statusCode == 401) {
        throw const ApiException(
          statusCode: 503,
          message: 'Could not complete sign-in. Please try again.',
        );
      }
      rethrow;
    }
    if (user.firebaseUid != identity.uid ||
        !user.active ||
        user.isGuest ||
        !_roles.contains(user.role) ||
        user.publicId.isEmpty) {
      throw _invalidSession;
    }
    return PasswordSession(uid: identity.uid, user: user);
  }

  Future<PasswordSession> completeFirstLogin({
    required String uid,
    required String phone,
    required String idToken,
    required String newPassword,
  }) async {
    await _changePassword(idToken, newPassword);
    try {
      final renewed = await signIn(
        phone: phone,
        password: newPassword,
        expectedUid: uid,
      );
      if (renewed.user.mustChangePassword) throw _invalidSession;
      return renewed;
    } catch (_) {
      // The password was saved. Never tell the person to retry saving it
      // just because obtaining a replacement session failed afterwards.
      throw const PasswordChangedSignInRequired();
    }
  }

  static const _invalidSession = ApiException(
    statusCode: 403,
    message: 'Could not verify this account. Please sign in again.',
  );

  static Future<String> _requestHandoff(String phone, String password) =>
      ApiClient.instance.passwordLogin(phone: phone, password: password);
  static Future<SyncedUser> _syncAccount(String token) =>
      ApiClient.instance.syncUser(idToken: token);
  static Future<void> _changeAccountPassword(String token, String password) =>
      ApiClient.instance.changePassword(idToken: token, newPassword: password);
  static Future<PasswordIdentity> _exchangeHandoff(String token) async {
    final credential = await FirebaseAuth.instance.signInWithCustomToken(token);
    final user = credential.user;
    if (user == null || user.isAnonymous) throw _invalidSession;
    final idToken = await user.getIdToken(true);
    if (idToken == null) throw _invalidSession;
    return PasswordIdentity(uid: user.uid, idToken: idToken);
  }
}
