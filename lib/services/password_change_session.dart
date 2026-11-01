import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'api_client.dart';
import 'auth_transitions.dart';
import 'session_scope.dart';

/// Keeps OTP/grant requests and their completion attached to the opening session.
class PasswordChangeSession {
  PasswordChangeSession({
    AuthSessionFence? owner,
    Future<String?> Function()? credential,
  }) : _owner = SessionScope.capture(auth: owner),
       _credential = credential ?? _currentToken;
  final SessionScope _owner;
  final Future<String?> Function() _credential;
  bool get isCurrent => _owner.isCurrent;
  static Future<String?> _currentToken() async => Firebase.apps.isEmpty
      ? null
      : FirebaseAuth.instance.currentUser?.getIdToken();
  static const _changed = ApiException(
    statusCode: 401,
    message: 'Your session changed. Please sign in again.',
  );

  void check() {
    if (!isCurrent) throw _changed;
  }

  Future<String> _token() async {
    check();
    final token = await _credential();
    check();
    if (token == null || token.isEmpty) throw _changed;
    return token;
  }

  Future<DateTime?> sendCode(String phone) async {
    final token = await _token();
    final expiry = await ApiClient.instance.sendAuthenticatedPasswordChangeOtp(
      idToken: token,
      phone: phone,
    );
    check();
    return expiry;
  }

  Future<String> verifyCode(String code) async {
    final token = await _token();
    final grant = await ApiClient.instance.verifyAuthenticatedPasswordChangeOtp(
      idToken: token,
      otp: code,
    );
    check();
    return grant;
  }

  /// Returns ownership of completion, not whether the acknowledged save happened.
  Future<bool> savePassword({
    required String phone,
    required String resetToken,
    required String newPassword,
  }) async {
    check();
    await ApiClient.instance.resetPassword(
      phone: phone,
      resetToken: resetToken,
      newPassword: newPassword,
    );
    return isCurrent;
  }
}
