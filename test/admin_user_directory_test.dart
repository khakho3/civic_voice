import 'package:flutter_test/flutter_test.dart';
import 'package:civic_voice/features/admin/models/admin_user_management_data.dart';
import 'package:civic_voice/features/admin/services/admin_user_directory.dart';
import 'package:civic_voice/models/app_role.dart';

void main() {
  final directory = AdminUserDirectory.instance;

  tearDown(() {
    directory.users.value = mockAdminUsers();
  });

  test(
    'changing a user role updates the existing entry instead of duplicating it',
    () {
      directory.users.value = [
        AdminUserItem.fromApi({
          'id': 'stable-db-id-123',
          'fullName': 'Genny Amadapah',
          'phone': '+233241234567',
          'role': 'CITIZEN',
          'active': true,
          'publicId': 'CIT-000123',
          'createdAt': DateTime(2026).toIso8601String(),
          'updatedAt': DateTime(2026).toIso8601String(),
        }),
      ];

      expect(directory.users.value.length, 1);

      // Simulate the PATCH response after an Admin changes this account's
      // role to Municipal Officer — same underlying row (same 'id'), but
      // the backend mints a fresh publicId matching the new role (see
      // adminUsers.js's roleChanged branch).
      directory.upsertFromApi({
        'id': 'stable-db-id-123',
        'fullName': 'Genny Amadapah',
        'phone': '+233241234567',
        'role': 'MUNICIPAL',
        'active': true,
        'publicId': 'MUN-000045',
        'region': 'greaterAccra',
        'assembly': 'Accra Metropolitan',
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      });

      expect(
        directory.users.value.length,
        1,
        reason:
            'role change must update the existing row, not add a second one',
      );
      expect(directory.users.value.single.userId, 'MUN-000045');
      expect(directory.users.value.single.role, AppRole.municipalOfficer);
      expect(directory.users.value.single.apiId, 'stable-db-id-123');
    },
  );
}
