import 'package:flutter/foundation.dart';

import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';

/// In-memory admin user directory — the same "single shared mock service"
/// pattern as citizen's `ReportCrudService`, so creating a user from
/// [AdminCreateUserScreen] (not built yet at the time User Management first
/// shipped) actually shows up back in [AdminUserManagementScreen]'s list
/// instead of vanishing into an unwired callback. Replaces User
/// Management's previous screen-local `_users` state, which only
/// [_toggleActive] ever mutated — now every admin screen reads/writes
/// through this one list.
class AdminUserDirectory {
  AdminUserDirectory._();

  static final AdminUserDirectory instance = AdminUserDirectory._();

  final ValueNotifier<List<AdminUserItem>> users = ValueNotifier(
    mockAdminUsers(),
  );

  int _nextUserNumber = 200;

  AdminUserItem createUser({
    required String name,
    required String email,
    required String phone,
    required AppRole role,
    AdminTier? adminTier,
    Region? region,
    Assembly? assembly,
  }) {
    final now = DateTime.now();
    final effectiveTier = role == AppRole.systemAdministrator
        ? (adminTier ?? AdminTier.admin)
        : null;
    final needsAssembly = AdminUserItem.roleRequiresAssembly(
      role,
      effectiveTier,
    );
    final newUser = AdminUserItem(
      name: name,
      email: email,
      phone: phone,
      role: role,
      status: AdminUserStatus.active,
      userId: 'CV-USER-${(_nextUserNumber++).toString().padLeft(4, '0')}',
      lastSignIn: now,
      accountCreated: now,
      adminTier: effectiveTier,
      region: (AdminUserItem.roleRequiresRegion(role) || needsAssembly)
          ? region
          : null,
      assembly: needsAssembly ? assembly : null,
    );
    users.value = [newUser, ...users.value];
    return newUser;
  }

  void updateUser(AdminUserItem updated) {
    users.value = [
      for (final user in users.value)
        if (user.userId == updated.userId) updated else user,
    ];
  }

  AdminUserItem? userById(String userId) {
    for (final user in users.value) {
      if (user.userId == userId) return user;
    }
    return null;
  }

  void toggleActive(AdminUserItem user) {
    updateUser(
      user.copyWith(
        status: user.status == AdminUserStatus.inactive
            ? AdminUserStatus.active
            : AdminUserStatus.inactive,
      ),
    );
  }
}
