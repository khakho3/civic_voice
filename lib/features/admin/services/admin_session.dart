import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../services/mock_auth_service.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';

/// The single place every Admin screen checks "am I allowed to do this" —
/// reads the current mock identity from [MockAuthService] and turns
/// [AdminTier.admin]/[AdminTier.superAdmin] plus a jurisdiction into
/// concrete yes/no answers, so the tier's already-declared permission map
/// (`AdminTier.permissions` — see its own doc comment) actually gates the
/// UI instead of just describing it on the Role Management catalog.
///
/// A [AdminTier.superAdmin] session ("people like us" — national platform
/// controllers) is unrestricted. An [AdminTier.admin] session is scoped to
/// exactly one [Assembly]: it can provision and see only the Municipal
/// Officer and Maintenance Team accounts within that assembly, and can't
/// reassign roles or deactivate/delete accounts at all — matching
/// [AdminTier.admin]'s existing `editUserRoles: false`, `deleteRecords:
/// false` declarations.
///
/// Reads [MockAuthService] fresh on every property access rather than
/// caching — this mirrors real auth-claim reads and means switching test
/// roles/tiers via [TestRoleSelectorScreen] takes effect immediately
/// without this class needing its own invalidation.
class AdminSession {
  const AdminSession._();

  static const AdminSession instance = AdminSession._();

  AppRole? get _role => MockAuthService().getCurrentRole();

  AdminTier? get _tier => MockAuthService().getCurrentAdminTier();

  /// True for a [AppRole.systemAdministrator] session holding
  /// [AdminTier.superAdmin] — unrestricted, national. Also true (fail-open,
  /// not fail-closed) when no mock identity is set yet, so screens behave
  /// normally before `MockAuthService.initialize()` has run rather than
  /// looking broken.
  bool get isSuperAdmin =>
      _role != AppRole.systemAdministrator || _tier != AdminTier.admin;

  /// The [Region]/[Assembly] an [AdminTier.admin] session is scoped to —
  /// null for Super Admin (national, no jurisdiction of its own).
  Region? get region => isSuperAdmin ? null : MockAuthService().getCurrentRegion();

  Assembly? get assembly =>
      isSuperAdmin ? null : MockAuthService().getCurrentAssembly();

  /// Roles this session can provision from Create User. Super Admin gets
  /// every admin-provisioned role (citizens self-register, so they're never
  /// in this list either way); an assembly Admin can only staff their own
  /// assembly's day-to-day team.
  List<AppRole> get creatableRoles => isSuperAdmin
      ? const [
          AppRole.systemAdministrator,
          AppRole.ministrySupervisor,
          AppRole.municipalOfficer,
          AppRole.maintenanceTeam,
        ]
      : const [AppRole.municipalOfficer, AppRole.maintenanceTeam];

  bool canCreateRole(AppRole role) => creatableRoles.contains(role);

  /// [AdminTier.admin]'s `editUserRoles: false` — an assembly Admin can see
  /// and support their team, not promote/demote or reassign what module an
  /// account opens.
  bool get canEditUserRoles =>
      isSuperAdmin || AdminTier.admin.permissions[PermissionType.editUserRoles]!;

  /// [AdminTier.admin]'s `deleteRecords: false` extended to account
  /// deactivation — the closest equivalent this app has to a destructive
  /// record change for a user account.
  bool get canDeactivateUsers =>
      isSuperAdmin || AdminTier.admin.permissions[PermissionType.deleteRecords]!;

  /// The subset of [users] this session is allowed to see. Super Admin sees
  /// every account; an assembly Admin sees only accounts provisioned within
  /// their own [assembly] — including their own account.
  List<AdminUserItem> visibleUsers(List<AdminUserItem> users) {
    if (isSuperAdmin) return users;
    final ownAssembly = assembly;
    if (ownAssembly == null) return const [];
    return [
      for (final user in users)
        if (user.assembly?.name == ownAssembly.name &&
            user.assembly?.region == ownAssembly.region)
          user,
    ];
  }
}
