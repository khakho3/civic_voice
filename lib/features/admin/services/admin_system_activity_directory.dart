import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../services/api_client.dart';
import '../models/admin_system_activity_data.dart';
import 'admin_session.dart';

class AdminSystemActivityDirectory {
  AdminSystemActivityDirectory._();

  static final instance = AdminSystemActivityDirectory._();

  final ValueNotifier<List<ActivityItem>> items = ValueNotifier(
    Firebase.apps.isEmpty ? mockActivityItems() : const <ActivityItem>[],
  );
  final ValueNotifier<SystemHealthStats?> health = ValueNotifier(
    Firebase.apps.isEmpty ? mockSystemHealthStats() : null,
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
      final response = await ApiClient.instance.listAdminActivity(
        idToken: token,
      );
      items.value = response.map(ActivityItem.fromApi).toList();
      hasLiveSnapshot = true;
      if (AdminSession.instance.isSuperAdmin) {
        await refreshHealth(idToken: token);
      } else {
        health.value = null;
      }
    } catch (exception) {
      error.value = exception.toString();
      rethrow;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshHealth({String? idToken}) async {
    if (Firebase.apps.isEmpty || !AdminSession.instance.isSuperAdmin) return;
    try {
      final token =
          idToken ?? await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) throw StateError('A signed-in Admin is required');
      health.value = SystemHealthStats.fromApi(
        await ApiClient.instance.getAdminHealth(idToken: token),
      );
    } catch (_) {
      health.value = const SystemHealthStats(
        apiOnline: false,
        databaseOnline: false,
        dbLatencyMs: 0,
        uptimeSeconds: 0,
      );
    }
  }
}
