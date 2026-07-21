import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';
import '../../../services/api_client.dart';

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
  String? currentApiUserId;

  AdminUserItem? get currentUser {
    final id = currentApiUserId;
    if (id == null) return null;
    for (final user in users.value) {
      if (user.apiRecordId == id) return user;
    }
    return null;
  }

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final response = await ApiClient.instance.listUsers(idToken: token);
    users.value = response.map(AdminUserItem.fromApi).toList();
  }

  void upsertFromApi(Map<String, dynamic> json) {
    final user = AdminUserItem.fromApi(json);
    // Match on the stable database id, not userId — userId mirrors the
    // backend's publicId, which the server deliberately mints fresh
    // whenever role changes (CIT-000123 -> MUN-000045, still the same
    // row). Matching on userId meant a role edit's response never matched
    // its own pre-edit entry here, so it got prepended as a second row
    // instead of replacing the first — same account, same everything,
    // just two entries with different roles.
    users.value = [
      user,
      for (final existing in users.value)
        if (existing.apiId != user.apiId) existing,
    ];
  }

  Future<void> saveOnServer(AdminUserItem user) async {
    if (Firebase.apps.isEmpty) {
      updateUser(user);
      return;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    final response = await ApiClient.instance.updateUser(
      user.apiRecordId,
      idToken: token,
      fields: {
        'role': _backendRole(user.role),
        'active': user.status != AdminUserStatus.inactive,
        'adminTier': user.adminTier?.name,
        'region': user.region?.name,
        'assembly': user.assembly?.name,
      },
    );
    upsertFromApi(response);
  }

  Future<void> deleteOnServer(AdminUserItem user) async {
    if (Firebase.apps.isEmpty) {
      users.value = users.value
          .where((existing) => existing.userId != user.userId)
          .toList();
      return;
    }
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in Admin is required');
    await ApiClient.instance.deleteUser(user.apiRecordId, idToken: token);
    users.value = users.value
        .where((existing) => existing.userId != user.userId)
        .toList();
  }

  Future<void> toggleActiveOnServer(AdminUserItem user) async {
    final updated = user.copyWith(
      status: user.status == AdminUserStatus.inactive
          ? AdminUserStatus.active
          : AdminUserStatus.inactive,
    );
    await saveOnServer(updated);
  }

  static String _backendRole(AppRole role) => switch (role) {
    AppRole.citizen => 'CITIZEN',
    AppRole.municipalOfficer => 'MUNICIPAL',
    AppRole.maintenanceTeam => 'MAINTENANCE',
    AppRole.ministrySupervisor => 'MINISTRY',
    AppRole.systemAdministrator => 'ADMIN',
  };

  AdminUserItem createUser({
    required String name,
    String? email,
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
      userId:
          '${_publicIdPrefix(role)}-${(_nextUserNumber++).toString().padLeft(6, '0')}',
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

  static String _publicIdPrefix(AppRole role) => switch (role) {
    AppRole.citizen => 'CIT',
    AppRole.municipalOfficer => 'MUN',
    AppRole.maintenanceTeam => 'MNT',
    AppRole.ministrySupervisor => 'MIN',
    AppRole.systemAdministrator => 'ADM',
  };

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

  /// The Municipal Officer account that "represents" [assemblyName]/[region]
  /// wherever only one contact can be shown (e.g. Ministry's per-assembly
  /// performance view) — whichever provisioned officer for that assembly
  /// was created first. `null` when no officer has been provisioned for it
  /// yet, so callers can fall back to placeholder contact info.
  ///
  /// [assemblyName] is matched in `"<name> <type label>"` form (e.g. "Accra
  /// Metropolitan") — the shape [RegionalLeaderItem.name] already uses —
  /// rather than [Assembly.name] alone, since a caller like Ministry's
  /// Municipality Detail only has that composite label on hand, not the
  /// [Assembly] record itself.
  ///
  /// Deliberately not a full hierarchy: an assembly can have several
  /// Municipal Officer accounts (Admins staff their own team as it grows),
  /// but Francis's call was to keep this simple rather than model seniority
  /// — the earliest account is just a stable, unambiguous pick.
  AdminUserItem? correspondentOfficerFor(String assemblyName, Region region) {
    AdminUserItem? earliest;
    for (final user in users.value) {
      if (user.role != AppRole.municipalOfficer) continue;
      final assembly = user.assembly;
      if (assembly == null || assembly.region != region) continue;
      if ('${assembly.name} ${assembly.type.label}' != assemblyName) continue;
      if (earliest == null ||
          user.accountCreated.isBefore(earliest.accountCreated)) {
        earliest = user;
      }
    }
    return earliest;
  }

  /// The System Administrator (Admin-tier) account that "represents"
  /// [assembly] wherever only one contact can be shown (e.g. that assembly's
  /// own Admin Dashboard greeting) — whichever provisioned Admin account for
  /// that assembly was created first, mirroring [correspondentOfficerFor]'s
  /// same reasoning. `null` when no Admin has been provisioned for it yet,
  /// so callers can fall back to a placeholder identity.
  AdminUserItem? correspondentAdminFor(Assembly assembly) {
    AdminUserItem? earliest;
    for (final user in users.value) {
      if (user.role != AppRole.systemAdministrator) continue;
      if (user.adminTier != AdminTier.admin) continue;
      final userAssembly = user.assembly;
      if (userAssembly == null) continue;
      if (userAssembly.name != assembly.name ||
          userAssembly.region != assembly.region) {
        continue;
      }
      if (earliest == null ||
          user.accountCreated.isBefore(earliest.accountCreated)) {
        earliest = user;
      }
    }
    return earliest;
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
