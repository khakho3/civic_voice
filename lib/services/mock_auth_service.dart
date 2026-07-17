import 'package:shared_preferences/shared_preferences.dart';

import '../features/admin/models/admin_role_management_data.dart';
import '../models/app_role.dart';
import '../models/assembly.dart';
import '../models/ghana_assemblies_data.dart';
import '../models/region.dart';

/// Mock identity for testing every module route before Firebase is
/// connected. Beyond the bare [AppRole], a System Administrator session
/// also carries [AdminTier] — and, when that tier is [AdminTier.admin]
/// (one per assembly, not the national [AdminTier.superAdmin]), the
/// [Region]/[Assembly] jurisdiction that account is scoped to. [AdminSession]
/// (`lib/features/admin/services/admin_session.dart`) reads this identity to
/// decide what an Admin-tier test session can actually see and do.
class MockAuthService {
  MockAuthService._();

  static final MockAuthService _instance = MockAuthService._();

  factory MockAuthService() => _instance;

  static const _roleKey = 'test_user_role';
  static const _tierKey = 'test_admin_tier';
  static const _regionKey = 'test_admin_region';
  static const _assemblyKey = 'test_admin_assembly';

  AppRole? _currentRole;
  AdminTier? _currentAdminTier;
  Region? _currentRegion;
  Assembly? _currentAssembly;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;

    final savedRole = prefs.getString(_roleKey);
    if (savedRole == null) return;
    _currentRole = AppRole.values.firstWhere(
      (role) => role.name == savedRole,
      orElse: () => AppRole.citizen,
    );

    final savedTier = prefs.getString(_tierKey);
    _currentAdminTier = savedTier == null
        ? null
        : AdminTier.values.firstWhere(
            (tier) => tier.name == savedTier,
            orElse: () => AdminTier.admin,
          );

    final savedRegion = prefs.getString(_regionKey);
    _currentRegion = savedRegion == null
        ? null
        : Region.values.firstWhere(
            (region) => region.name == savedRegion,
            orElse: () => Region.greaterAccra,
          );

    final savedAssemblyName = prefs.getString(_assemblyKey);
    _currentAssembly = (savedAssemblyName == null || _currentRegion == null)
        ? null
        : ghanaAssemblies[_currentRegion]?.firstWhere(
            (assembly) => assembly.name == savedAssemblyName,
            orElse: () => ghanaAssemblies[_currentRegion]!.first,
          );
  }

  AppRole? getCurrentRole() => _currentRole;

  AdminTier? getCurrentAdminTier() => _currentAdminTier;

  Region? getCurrentRegion() => _currentRegion;

  Assembly? getCurrentAssembly() => _currentAssembly;

  Future<void> selectRole(
    AppRole role, {
    AdminTier? adminTier,
    Region? region,
    Assembly? assembly,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _currentRole = role;
    await prefs.setString(_roleKey, role.name);

    final effectiveTier = role == AppRole.systemAdministrator
        ? adminTier
        : null;
    final scoped = effectiveTier == AdminTier.admin;
    _currentAdminTier = effectiveTier;
    _currentRegion = scoped ? region : null;
    _currentAssembly = scoped ? assembly : null;

    if (effectiveTier == null) {
      await prefs.remove(_tierKey);
    } else {
      await prefs.setString(_tierKey, effectiveTier.name);
    }
    if (_currentRegion == null) {
      await prefs.remove(_regionKey);
    } else {
      await prefs.setString(_regionKey, _currentRegion!.name);
    }
    if (_currentAssembly == null) {
      await prefs.remove(_assemblyKey);
    } else {
      await prefs.setString(_assemblyKey, _currentAssembly!.name);
    }
  }

  Future<void> clearUser() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _currentRole = null;
    _currentAdminTier = null;
    _currentRegion = null;
    _currentAssembly = null;
    await prefs.remove(_roleKey);
    await prefs.remove(_tierKey);
    await prefs.remove(_regionKey);
    await prefs.remove(_assemblyKey);
  }

  bool isInitialized() => _prefs != null;
}
