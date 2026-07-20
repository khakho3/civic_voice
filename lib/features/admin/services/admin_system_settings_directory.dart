import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../models/admin_system_settings_data.dart';

/// Real, process-wide source of truth for ADM-007 System Settings — a
/// `ValueNotifier` singleton, the same pattern as every other `*Directory`
/// in this app. Backed by a real civic_voice_api endpoint
/// (GET/PATCH /api/admin/settings) — [refresh]/[save] are the only ways
/// [settings] changes now, replacing the earlier local-only mock that
/// reset on every app restart and never left the device.
class AdminSystemSettingsDirectory {
  AdminSystemSettingsDirectory._();

  static final AdminSystemSettingsDirectory instance =
      AdminSystemSettingsDirectory._();

  final ValueNotifier<SystemSettingsData> settings = ValueNotifier(
    mockSystemSettings(),
  );
  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  bool hasLiveSnapshot = false;

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    loading.value = true;
    error.value = null;
    try {
      final response = await ApiClient.instance.getAdminSettings(
        idToken: token,
      );
      settings.value = SystemSettingsData.fromApi(response);
      hasLiveSnapshot = true;
    } catch (exception) {
      error.value = exception.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  /// Saves [draft] for real — only the three server-backed fields are
  /// actually sent (see [SystemSettingsData.fromApi]'s doc comment).
  /// Throws [ApiException] on failure (e.g. a non-Super-Admin session);
  /// callers show that message rather than a generic one.
  Future<void> save(SystemSettingsData draft) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final response = await ApiClient.instance.updateAdminSettings(
      idToken: token,
      fields: {
        'sessionTimeout': draft.sessionTimeout,
        'auditLogging': draft.auditLogging,
        'allowNewAccountCreation': draft.allowNewAccountCreation,
      },
    );
    settings.value = SystemSettingsData.fromApi(response);
    hasLiveSnapshot = true;
  }
}
