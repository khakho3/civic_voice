import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_role.dart';

class MockAuthService {
  MockAuthService._();

  static final MockAuthService _instance = MockAuthService._();

  factory MockAuthService() => _instance;

  static const _roleKey = 'test_user_role';

  AppRole? _currentRole;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedRole = _prefs?.getString(_roleKey);
    if (savedRole == null) return;

    _currentRole = AppRole.values.firstWhere(
      (role) => role.name == savedRole,
      orElse: () => AppRole.citizen,
    );
  }

  AppRole? getCurrentRole() => _currentRole;

  Future<void> selectRole(AppRole role) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _currentRole = role;
    await prefs.setString(_roleKey, role.name);
  }

  Future<void> clearUser() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _currentRole = null;
    await prefs.remove(_roleKey);
  }

  bool isInitialized() => _prefs != null;
}
