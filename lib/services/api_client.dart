import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Thin wrapper around civic_voice_api (c:\Projects\mobile\servers\civic_voice_api).
/// Auth uses server-verified password handoffs and signed session sync;
/// module requests share this client's base URL and request boundaries.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const _requestTimeout = Duration(seconds: 20);
  static const _uploadTimeout = Duration(seconds: 75);

  /// Public HTTPS endpoint used by release builds. Local development can
  /// override it with `--dart-define=API_BASE_URL=http://<host>:<port>`.
  ///
  /// Deliberately mutable (not const): widget tests override this to a
  /// guaranteed-unreachable address in setUp() so they never make live
  /// calls against the real dev backend/Speso, regardless of whether
  /// civic_voice_api happens to be running on the machine the tests run
  /// on (it usually is, since that's the same machine).
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.civicvoice.eraaxis.com',
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
    Map<String, dynamic> decoded;
    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException(
        statusCode: 502,
        message: 'The CivicVoice service returned an invalid response.',
      );
    }
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

  Future<T> _bounded<T>(
    Future<T> request, {
    Duration timeout = _requestTimeout,
  }) async {
    try {
      return await request.timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message:
            'The request took too long. Check your connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message:
            'Could not reach CivicVoice. Check your connection and try again.',
      );
    }
  }

  /// Thrown for any non-2xx response, carrying the backend's own error
  /// message (civic_voice_api always responds with `{ "error": "..." }`)
  /// so callers can show it directly instead of a generic failure.
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? idToken,
  }) async {
    final response = await _bounded(
      http.post(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          if (idToken != null) 'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ),
    );

    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    required String idToken,
  }) async {
    return _decode(
      await _bounded(
        http.get(
          Uri.parse('$baseUrl$path'),
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    required String idToken,
  }) async {
    final response = await _bounded(
      http.patch(
        Uri.parse('$baseUrl$path'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<void> deleteReport(String id, {required String idToken}) async {
    _decode(
      await _bounded(
        http.delete(
          Uri.parse('$baseUrl/api/reports/$id'),
          headers: {'Authorization': 'Bearer $idToken'},
        ),
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
    final streamed = await _bounded(request.send(), timeout: _uploadTimeout);
    return _decode(
      await _bounded(
        http.Response.fromStream(streamed),
        timeout: _uploadTimeout,
      ),
    );
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
  Future<DateTime?> sendRegistrationOtp(String phone) async {
    final result = await _post('/api/auth/registration-otp', {'phone': phone});
    return _otpExpiryFrom(result);
  }

  /// Completes Citizen self-registration — creates the Firebase Auth
  /// identity (real phone number + a synthetic login email + the password
  /// the citizen just typed) and the mirrored Postgres row, but only once
  /// Speso verifies [otp] against the latest code requested through
  /// [sendRegistrationOtp]. Returns the synthetic email so the caller can
  /// immediately sign in through Firebase password authentication.
  ///
  /// Pass [guestIdToken] when the caller is currently signed in as an
  /// Anonymous Auth guest (see [signInAsGuest]/[syncUser]) — the backend
  /// upgrades that same account in place instead of creating a new one,
  /// so any reports filed while a guest carry over automatically.
  Future<String> registerCitizen({
    required String fullName,
    required String phone,
    required String password,
    required String otp,
    String? guestIdToken,
  }) async {
    final result = await _post('/api/auth/citizen-register', {
      'fullName': fullName,
      'phone': phone,
      'password': password,
      'otp': otp,
    }, idToken: guestIdToken);
    return result['email'] as String;
  }

  /// The API verifies the password and returns a short-lived Firebase custom
  /// handoff. Never fall back to direct Firebase password authentication.
  Future<String> passwordLogin({
    required String phone,
    required String password,
  }) async {
    final response = await _bounded(
      http.post(
        Uri.parse('$baseUrl/api/auth/password-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      ),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Do not mistake an HTML proxy error or a missing endpoint for a bad
      // password, and do not render arbitrary upstream error bodies.
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Could not complete sign-in.',
      );
    }
    try {
      final result = jsonDecode(response.body);
      final token = result is Map ? result['customToken'] : null;
      if (token is String && token.trim().isNotEmpty) return token;
    } on FormatException {
      /* Handled as an invalid service response below. */
    }
    throw const ApiException(
      statusCode: 502,
      message: 'Could not verify the sign-in response.',
    );
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

  /// Best-effort evidence of a logout request, not proof of token revocation.
  Future<void> reportSignOut({required String idToken}) async {
    _decode(
      await _bounded(
        http.post(
          Uri.parse('$baseUrl/api/auth/session-events'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $idToken',
          },
          body: jsonEncode({'type': 'SIGN_OUT'}),
        ),
        timeout: const Duration(milliseconds: 1500),
      ),
    );
  }

  /// Admin provisions a Municipal/Maintenance/Ministry/Admin account —
  /// creates the real Firebase identity (phone + synthetic login email +
  /// a generated temp password) and mirrors it into Postgres, then SMS's
  /// the temp password via Speso. [idToken] must belong to a
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

  Future<DateTime?> sendForgotPasswordOtp(String phone) async {
    final result = await _post('/api/auth/forgot-password-otp', {
      'phone': phone,
    });
    return _otpExpiryFrom(result);
  }

  Future<DateTime?> sendAuthenticatedPasswordChangeOtp({
    required String idToken,
    required String phone,
  }) async {
    final result = await _post('/api/auth/change-password-otp', {
      'phone': phone,
    }, idToken: idToken);
    return _otpExpiryFrom(result);
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

  Future<void> unregisterPushToken({
    required String idToken,
    required String token,
  }) async {
    await _post('/api/auth/push-token/unregister', {
      'token': token,
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

  Future<List<Map<String, dynamic>>> fetchNearbySeconding({
    required String idToken,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime capturedAt,
  }) async {
    final query = Uri(
      queryParameters: {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'accuracy': '$accuracy',
        'capturedAt': _positionTimestamp(capturedAt),
      },
    ).query;
    final result = await _get(
      '/api/reports/nearby-seconding?$query',
      idToken: idToken,
    );
    return (result['reports'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> secondReport(
    String reportId, {
    required String idToken,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime capturedAt,
  }) async {
    final result = await _post(
      '/api/reports/${Uri.encodeComponent(reportId)}/second',
      {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'capturedAt': _positionTimestamp(capturedAt),
      },
      idToken: idToken,
    );
    if (result['secondedByMe'] != true) {
      throw const ApiException(
        statusCode: 502,
        message: 'Could not verify this confirmation. Refresh Nearby Reports before trying again.',
      );
    }
  }

  static String _positionTimestamp(DateTime value) =>
      DateTime.fromMillisecondsSinceEpoch(
        value.millisecondsSinceEpoch,
        isUtc: true,
      ).toIso8601String();

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
    final result = await _patch(
      '/api/admin/maintenance-teams/$teamId',
      fields,
      idToken: idToken,
    );
    return result['team'] as Map<String, dynamic>;
  }

  Future<void> deleteMaintenanceTeam(
    String teamId, {
    required String idToken,
  }) async {
    _decode(
      await _bounded(
        http.delete(
          Uri.parse('$baseUrl/api/admin/maintenance-teams/$teamId'),
          headers: {'Authorization': 'Bearer $idToken'},
        ),
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
    final key = fields['submissionKey'];
    if (key == null || !RegExp(r'^[a-zA-Z0-9_-]{16,128}$').hasMatch(key)) {
      throw const ApiException(
        statusCode: 400,
        message: 'Submission key required.',
      );
    }
    final result = await _multipart(
      'POST',
      '/api/reports',
      idToken: idToken,
      fields: fields,
      files: {'photos': photoPaths},
    );
    return validateReportReceipt(result, key);
  }

  Future<List<Map<String, dynamic>>> reportDuplicateCandidates({
    required String idToken,
    required Map<String, dynamic> issue,
  }) async {
    final result = await _post(
      '/api/reports/duplicate-candidates',
      issue,
      idToken: idToken,
    );
    final rows = result['reports'];
    if (rows is! List ||
        rows.length > 3 ||
        rows.any((row) => row is! Map<String, dynamic>)) {
      throw const FormatException('Similar reports could not be verified.');
    }
    return rows.cast<Map<String, dynamic>>();
  }

  /// A successful HTTP response alone cannot acknowledge an uncertain save.
  static Map<String, dynamic> validateReportReceipt(
    Map<String, dynamic> result,
    String key,
  ) {
    final receipt = result['submission'];
    final report = result['report'];
    if (receipt is! Map ||
        receipt['key'] != key ||
        receipt['replayed'] is! bool ||
        report is! Map<String, dynamic> ||
        report['id'] is! String ||
        (report['id'] as String).trim().isEmpty ||
        report['publicReference'] is! String ||
        (report['publicReference'] as String).trim().isEmpty) {
      throw const ApiException(
        statusCode: 502,
        message: 'Submission not confirmed. Check the same submission again.',
      );
    }
    return report;
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

  Future<List<Map<String, dynamic>>> listAdminActivity({
    required String idToken,
    String? search,
  }) async {
    final query = (search != null && search.trim().isNotEmpty)
        ? '?q=${Uri.encodeQueryComponent(search.trim())}'
        : '';
    final result = await _get('/api/admin/activity$query', idToken: idToken);
    return (result['activity'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getAdminHealth({required String idToken}) async {
    return _get('/api/admin/health', idToken: idToken);
  }

  Future<Map<String, dynamic>> getAdminSettings({
    required String idToken,
  }) async {
    final result = await _get('/api/admin/settings', idToken: idToken);
    return result['settings'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSessionSettings({
    required String idToken,
  }) async {
    return _get('/api/auth/session-settings', idToken: idToken);
  }

  Future<Map<String, dynamic>> updateAdminSettings({
    required String idToken,
    required Map<String, dynamic> fields,
  }) async {
    final result = await _patch(
      '/api/admin/settings',
      fields,
      idToken: idToken,
    );
    return result['settings'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> listMinistryMunicipalContacts({
    required String idToken,
  }) async {
    final result = await _get(
      '/api/ministry/municipal-contacts',
      idToken: idToken,
    );
    return (result['officers'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> updateUser(
    String userId, {
    required String idToken,
    required Map<String, dynamic> fields,
  }) async {
    final result = await _patch(
      '/api/admin/users/$userId',
      fields,
      idToken: idToken,
    );
    return result['user'] as Map<String, dynamic>;
  }

  Future<void> deleteUser(String userId, {required String idToken}) async {
    _decode(
      await _bounded(
        http.delete(
          Uri.parse('$baseUrl/api/admin/users/$userId'),
          headers: {'Authorization': 'Bearer $idToken'},
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String idToken,
    String? fullName,
  }) async {
    final result = await _patch('/api/auth/me', {
      ...fullName == null ? const {} : {'fullName': fullName},
    }, idToken: idToken);
    return result['user'] as Map<String, dynamic>;
  }

  DateTime? _otpExpiryFrom(Map<String, dynamic> result) {
    final value = result['expiresAt'];
    return value is String ? DateTime.tryParse(value) : null;
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
    required this.adminTier,
    required this.region,
    required this.assembly,
    required this.maintenanceTeamId,
    required this.maintenanceTeamName,
    required this.maintenanceTeamLeadUserId,
    required this.isGuest,
    this.firebaseUid,
    this.active = false,
  });

  final String id;
  final String publicId;
  final String role;
  final String fullName;
  final bool mustChangePassword;
  final String? phone;
  final String? adminTier;
  final String? region;
  final String? assembly;
  final String? maintenanceTeamId;
  final String? maintenanceTeamName;
  final String? maintenanceTeamLeadUserId;
  final bool isGuest;
  final String? firebaseUid;
  final bool active;

  factory SyncedUser.fromJson(Map<String, dynamic> json) {
    return SyncedUser(
      id: json['id'] as String,
      publicId: json['publicId'] as String? ?? json['id'] as String,
      role: json['role'] as String,
      fullName: json['fullName'] as String,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      phone: json['phone'] as String?,
      adminTier: json['adminTier'] as String?,
      region: json['region'] as String?,
      assembly: json['assembly'] as String?,
      maintenanceTeamId: json['maintenanceTeamId'] as String?,
      maintenanceTeamName: json['maintenanceTeamName'] as String?,
      maintenanceTeamLeadUserId: json['maintenanceTeamLeadUserId'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
      firebaseUid: json['firebaseUid'] as String?,
      active: json['active'] == true,
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
