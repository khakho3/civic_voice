import 'package:civic_voice/features/admin/models/admin_role_management_data.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/models/app_role.dart';
import 'package:civic_voice/models/region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a scoped backend Admin account into the live directory model', () {
    final user = AdminUserItem.fromApi({
      'id': 'admin-cuid',
      'publicId': '3b76382f-a077-4731-84b9-c92a9d45df86',
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
    expect(user.userId, '3b76382f-a077-4731-84b9-c92a9d45df86');
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
}
