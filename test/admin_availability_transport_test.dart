import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_overview.dart';
import 'package:civic_voice/features/admin/services/admin_resource.dart';
import 'package:civic_voice/features/admin/services/admin_read_failure.dart';
import 'package:civic_voice/features/admin/services/admin_system_activity_directory.dart';
import 'package:civic_voice/services/api_client.dart';

void main() {
  test(
    'a stopped local HTTP listener classifies actual overview and health transport failures as unreachable',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close(force: true);
      final original = ApiClient.baseUrl;
      ApiClient.baseUrl = 'http://127.0.0.1:$port';
      addTearDown(() => ApiClient.baseUrl = original);
      final source = AdminResource<AdminOverview>(
        owner: () => 'fixture',
        credential: () async => 'fixture',
        fetch: (token) => ApiClient.instance.adminOverview(idToken: token),
        parse: AdminOverview.parse,
      );
      addTearDown(source.dispose);
      final health = AdminSystemActivityDirectory.forTesting(
        firebaseAvailable: () => true,
        tokenProvider: () async => 'fixture',
        activityFetcher: (_) async => [],
        healthFetcher: (token) =>
            ApiClient.instance.getAdminHealth(idToken: token),
        isSuperAdmin: () => true,
      );
      await Future.wait([source.load(), health.refreshHealth()]);
      expect(source.failure, AdminReadFailure.unreachable);
      expect(source.data, isNull);
      expect(health.healthFailure.value, AdminReadFailure.unreachable);
      expect(health.health.value, isNull);
      expect(health.hasLiveHealthSnapshot, isFalse);
    },
  );
}
