import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thin wrapper around civic_voice_api (c:\Projects\mobile\servers\civic_voice_api).
/// Only covers the calls the real auth flow needs right now — registration,
/// resolving a phone number to its synthetic login email (see the backend's
/// src/utils/staffAuth.js), and syncing the signed-in Firebase user into
/// Postgres. Every other module still reads local/mock data; widening this
/// client is future work, not something to speculatively build out now.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  /// LAN IP of the machine running civic_voice_api during local dev — a
  /// physical device can't reach "localhost" (that resolves to itself).
  /// Swap this for a real deployed URL once the backend has one.
  ///
  /// Deliberately mutable (not const): widget tests override this to a
  /// guaranteed-unreachable address in setUp() so they never make live
  /// calls against the real dev backend/WittyFlow, regardless of whether
  /// civic_voice_api happens to be running on the machine the tests run
  /// on (it usually is, since that's the same machine).
  static String baseUrl = 'http://192.168.100.8:4000';

  /// Thrown for any non-2xx response, carrying the backend's own error
  /// message (civic_voice_api always responds with `{ "error": "..." }`)
  /// so callers can show it directly instead of a generic failure.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? idToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(body),
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['error'] as String? ?? 'Request failed (${response.statusCode})',
      );
    }

    return decoded;
  }

  /// Sends a real SMS verification code to confirm the citizen owns this
  /// phone number before any account gets created for it. Must succeed
  /// before [registerCitizen] will accept the matching otp.
  Future<void> sendRegistrationOtp(String phone) async {
    await _post('/api/auth/registration-otp', {'phone': phone});
  }

  /// Completes Citizen self-registration — creates the Firebase Auth
  /// identity (real phone number + a synthetic login email + the password
  /// the citizen just typed) and the mirrored Postgres row, but only once
  /// [otp] matches what [sendRegistrationOtp] most recently sent. Returns
  /// the synthetic email so the caller can immediately sign in with it via
  /// FirebaseAuth.instance.signInWithEmailAndPassword.
  Future<String> registerCitizen({
    required String fullName,
    required String phone,
    required String password,
    required String otp,
  }) async {
    final result = await _post('/api/auth/citizen-register', {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'otp': otp,
    });
    return result['email'] as String;
  }

  /// Resolves a phone number (staff or citizen) to the synthetic email its
  /// Firebase account was created with — the piece every real sign-in
  /// needs before it can call signInWithEmailAndPassword.
  Future<String> resolveLoginEmail(String phone) async {
    final result = await _post('/api/auth/login-email', {'phone': phone});
    return result['email'] as String;
  }

  /// Upserts the signed-in Firebase user into Postgres and returns that
  /// row — the only place the app learns a signed-in user's real `role`.
  Future<SyncedUser> syncUser({required String idToken, String? fullName}) async {
    final result = await _post('/api/auth/sync', {
      if (fullName != null) 'fullName': fullName,
    }, idToken: idToken);
    return SyncedUser.fromJson(result['user'] as Map<String, dynamic>);
  }

  /// Admin provisions a Municipal/Maintenance/Ministry/Admin account —
  /// creates the real Firebase identity (phone + synthetic login email +
  /// a generated temp password) and mirrors it into Postgres, then SMS's
  /// the temp password via WittyFlow. [idToken] must belong to a
  /// signed-in real ADMIN — the backend 403s otherwise. [role] is the
  /// backend's UserRole string (MUNICIPAL/MAINTENANCE/MINISTRY/ADMIN).
  ///
  /// Region/Assembly/Admin-tier scoping — real on the Flutter side via
  /// AdminSession — has no backend model yet (no Assembly/Team table in
  /// Postgres), so none of that is sent or persisted here yet.
  Future<void> createStaffUser({
    required String idToken,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    await _post('/api/admin/users', {
      'fullName': fullName,
      'phone': phone,
      'role': role,
    }, idToken: idToken);
  }

  /// Sets a new real Firebase password for the signed-in user and, if they
  /// had User.mustChangePassword set (a staff account still on its
  /// generated temp password), clears it. Used for both the forced
  /// first-login reset and a voluntary change-password.
  Future<void> changePassword({
    required String idToken,
    required String newPassword,
  }) async {
    await _post('/api/auth/change-password', {
      'newPassword': newPassword,
    }, idToken: idToken);
  }
}

class SyncedUser {
  const SyncedUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.mustChangePassword,
  });

  final String id;
  final String role;
  final String fullName;
  final bool mustChangePassword;

  factory SyncedUser.fromJson(Map<String, dynamic> json) {
    return SyncedUser(
      id: json['id'] as String,
      role: json['role'] as String,
      fullName: json['fullName'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
    );
  }
}

class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.message});

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
