import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/models/admin_system_activity_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a scoped backend Admin account into the live directory model', () {
    final user = AdminUserItem.fromApi({
      'id': 'admin-cuid',
      'publicId': 'ADM-000021',
      'fullName': 'Assembly Administrator',
      'phone': '+233500000000',
      'email': null,
      'role': 'ADMIN',
      'active': true,
      'adminTier': 'admin',
      'region': 'greaterAccra',
      'assembly': 'Accra',
      'createdAt': '2026-07-19T09:00:00.000Z',
      'updatedAt': '2026-07-19T09:30:00.000Z',
    });

    expect(user.apiRecordId, 'admin-cuid');
    expect(user.userId, 'ADM-000021');
    expect(user.role, AppRole.systemAdministrator);
    expect(user.adminTier, AdminTier.admin);
    expect(user.region, Region.greaterAccra);
    expect(user.assembly?.name, 'Accra');
    expect(user.status, AdminUserStatus.active);
  });

  test('legacy bootstrap Admin accounts map safely to Super Admin', () {
    final user = AdminUserItem.fromApi({
      'id': 'super-admin-cuid',
      'fullName': 'Platform Administrator',
      'phone': '+233500000001',
      'role': 'ADMIN',
      'active': true,
      'adminTier': null,
      'createdAt': '2026-07-19T09:00:00.000Z',
      'updatedAt': '2026-07-19T09:30:00.000Z',
    });

    expect(user.adminTier, AdminTier.superAdmin);
  });

  test(
    'maps a scoped audit event into its municipality and display values',
    () {
      final item = ActivityItem.fromApi({
        'id': 'audit-1',
        'title': 'Report status updated',
        'description': 'A report was accepted for review.',
        'severity': 'ALERT',
        'category': 'SYSTEM_UPDATE',
        'tag': 'Reports',
        'region': 'greaterAccra',
        'assembly': 'Accra',
        'createdAt': '2026-07-19T10:15:00.000Z',
      });

      expect(item.id, 'audit-1');
      expect(item.severity, ActivitySeverity.alert);
      expect(item.category, ActivityCategory.systemUpdate);
      expect(item.assembly?.name, 'Accra');
      expect(item.tag, 'Reports');
    },
  );

  test('maps live platform health and formats process uptime', () {
    final health = SystemHealthStats.fromApi({
      'apiOnline': true,
      'databaseOnline': true,
      'dbLatencyMs': 12.4,
      'uptimeSeconds': 367200,
      'checkedAt': '2026-07-19T10:15:00.000Z',
    });

    expect(health.apiOnline, isTrue);
    expect(health.databaseOnline, isTrue);
    expect(health.dbLatencyMs, 12);
    expect(health.uptimeLabel, '4d 6h');
    expect(health.checkedAt, isNotNull);
  });
}
