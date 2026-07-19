import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.8:4000',
  );

  static String assetUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return '$baseUrl$value';
    if (uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2') {
      final api = Uri.parse(baseUrl);
      return uri
          .replace(scheme: api.scheme, host: api.host, port: api.port)
          .toString();
    }
    return value;
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message:
            decoded['error'] as String? ??
            'Request failed (${response.statusCode})',
      );
    }
    return decoded;
  }

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

    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String idToken,
  }) async {
    return _decode(
      await http.get(
        Uri.parse('$baseUrl$path'),
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );
  }

  Future<void> deleteReport(String id, {required String idToken}) async {
    _decode(
      await http.delete(
        Uri.parse('$baseUrl/api/reports/$id'),
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );
  }

  Future<Map<String, dynamic>> _multipart(
    String method,
    String path, {
    required String idToken,
    required Map<String, String> fields,
    Map<String, List<String>> files = const {},
  }) async {
    final request = http.MultipartRequest(method, Uri.parse('$baseUrl$path'))
      ..headers['Authorization'] = 'Bearer $idToken'
      ..fields.addAll(fields);
    for (final entry in files.entries) {
      for (final filePath in entry.value) {
        if (await File(filePath).exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              filePath,
              contentType: _imageMediaType(filePath),
            ),
          );
        }
      }
    }
    final streamed = await request.send();
    return _decode(await http.Response.fromStream(streamed));
  }

  MediaType _imageMediaType(String path) {
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'heic' => MediaType('image', 'heic'),
      'heif' => MediaType('image', 'heif'),
      _ => MediaType('image', 'jpeg'),
    };
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
  Future<SyncedUser> syncUser({
    required String idToken,
    String? fullName,
  }) async {
    final result = await _post('/api/auth/sync', {
      ...fullName == null ? const {} : {'fullName': fullName},
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
  Future<Map<String, dynamic>> createStaffUser({
    required String idToken,
    required String fullName,
    required String phone,
    required String role,
    String? adminTier,
    String? region,
    String? assembly,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName,
      'phone': phone,
      'role': role,
    };
    if (adminTier != null) body['adminTier'] = adminTier;
    if (region != null) body['region'] = region;
    if (assembly != null) body['assembly'] = assembly;
    final result = await _post('/api/admin/users', body, idToken: idToken);
    return result;
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

  Future<void> sendForgotPasswordOtp(String phone) async {
    await _post('/api/auth/forgot-password-otp', {'phone': phone});
  }

  Future<void> sendAuthenticatedPasswordChangeOtp({
    required String idToken,
    required String phone,
  }) async {
    await _post('/api/auth/change-password-otp', {
      'phone': phone,
    }, idToken: idToken);
  }

  Future<String> verifyAuthenticatedPasswordChangeOtp({
    required String idToken,
    required String otp,
  }) async {
    final result = await _post('/api/auth/verify-change-password-otp', {
      'otp': otp,
    }, idToken: idToken);
    return result['resetToken'] as String;
  }

  Future<String> verifyPasswordResetOtp({
    required String phone,
    required String otp,
  }) async {
    final result = await _post('/api/auth/verify-password-reset-otp', {
      'phone': phone,
      'otp': otp,
    });
    return result['resetToken'] as String;
  }

  Future<void> registerPushToken({
    required String idToken,
    required String token,
    required String platform,
  }) async {
    await _post('/api/auth/push-token', {
      'token': token,
      'platform': platform,
    }, idToken: idToken);
  }

  Future<void> resetPassword({
    required String phone,
    required String resetToken,
    required String newPassword,
  }) async {
    await _post('/api/auth/reset-password', {
      'phone': phone,
      'resetToken': resetToken,
      'newPassword': newPassword,
    });
  }

  Future<List<Map<String, dynamic>>> listReports({
    required String idToken,
  }) async {
    final result = await _get('/api/reports', idToken: idToken);
    return (result['reports'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listMunicipalMaintenanceOptions({
    required String idToken,
  }) async {
    final result = await _get(
      '/api/reports/maintenance-options',
      idToken: idToken,
    );
    return (result['teams'] as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> listMaintenanceTeams({
    required String idToken,
  }) async {
    final result = await _get('/api/admin/maintenance-teams', idToken: idToken);
    return (result['teams'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createMaintenanceTeam({
    required String idToken,
    required Map<String, dynamic> fields,
  }) async {
    final result = await _post(
      '/api/admin/maintenance-teams',
      fields,
      idToken: idToken,
    );
    return result['team'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMaintenanceTeam(
    String teamId, {
    required String idToken,
    required Map<String, dynamic> fields,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/maintenance-teams/$teamId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(fields),
    );
    return _decode(response)['team'] as Map<String, dynamic>;
  }

  Future<void> deleteMaintenanceTeam(
    String teamId, {
    required String idToken,
  }) async {
    _decode(
      await http.delete(
        Uri.parse('$baseUrl/api/admin/maintenance-teams/$teamId'),
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );
  }

  Future<Map<String, dynamic>> getReport(
    String id, {
    required String idToken,
  }) async {
    final result = await _get('/api/reports/$id', idToken: idToken);
    return result['report'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claimReportReview(
    String id, {
    required String idToken,
  }) async {
    final result = await _post(
      '/api/reports/$id/claim-review',
      const {},
      idToken: idToken,
    );
    return result['report'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createReport({
    required String idToken,
    required Map<String, String> fields,
    List<String> photoPaths = const [],
  }) async {
    final result = await _multipart(
      'POST',
      '/api/reports',
      idToken: idToken,
      fields: fields,
      files: {'photos': photoPaths},
    );
    return result['report'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateReport(
    String id, {
    required String idToken,
    required Map<String, String> fields,
    List<String> resolutionPhotoPaths = const [],
  }) async {
    final result = await _multipart(
      'PATCH',
      '/api/reports/$id',
      idToken: idToken,
      fields: fields,
      files: {'resolutionPhotos': resolutionPhotoPaths},
    );
    return result['report'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listUsers({
    required String idToken,
  }) async {
    final result = await _get('/api/admin/users', idToken: idToken);
    return (result['users'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateUser(
    String userId, {
    required String idToken,
    required Map<String, dynamic> fields,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/admin/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(fields),
    );
    return _decode(response)['user'] as Map<String, dynamic>;
  }

  Future<void> deleteUser(String userId, {required String idToken}) async {
    _decode(
      await http.delete(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: {'Authorization': 'Bearer $idToken'},
      ),
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String idToken,
    String? fullName,
    String? avatarPath,
    bool removeAvatar = false,
  }) async {
    final result = await _multipart(
      'PATCH',
      '/api/auth/me',
      idToken: idToken,
      fields: {
        ...fullName == null ? const {} : {'fullName': fullName},
        if (removeAvatar) 'removeAvatar': 'true',
      },
      files: {
        if (avatarPath != null) 'avatar': [avatarPath],
      },
    );
    return result['user'] as Map<String, dynamic>;
  }
}

class SyncedUser {
  const SyncedUser({
    required this.id,
    required this.publicId,
    required this.role,
    required this.fullName,
    required this.mustChangePassword,
    required this.phone,
    required this.avatarUrl,
    required this.adminTier,
    required this.region,
    required this.assembly,
    required this.maintenanceTeamId,
    required this.maintenanceTeamName,
    required this.maintenanceTeamLeadUserId,
  });

  final String id;
  final String publicId;
  final String role;
  final String fullName;
  final bool mustChangePassword;
  final String? phone;
  final String? avatarUrl;
  final String? adminTier;
  final String? region;
  final String? assembly;
  final String? maintenanceTeamId;
  final String? maintenanceTeamName;
  final String? maintenanceTeamLeadUserId;

  factory SyncedUser.fromJson(Map<String, dynamic> json) {
    return SyncedUser(
      id: json['id'] as String,
      publicId: json['publicId'] as String? ?? json['id'] as String,
      role: json['role'] as String,
      fullName: json['fullName'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      adminTier: json['adminTier'] as String?,
      region: json['region'] as String?,
      assembly: json['assembly'] as String?,
      maintenanceTeamId: json['maintenanceTeamId'] as String?,
      maintenanceTeamName: json['maintenanceTeamName'] as String?,
      maintenanceTeamLeadUserId: json['maintenanceTeamLeadUserId'] as String?,
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
