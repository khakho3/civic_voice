import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/admin/models/admin_role_management_data.dart';
import '../../../features/admin/widgets/region_assembly_picker.dart';
import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../services/mock_auth_service.dart';

class TestRoleSelectorScreen extends StatefulWidget {
  const TestRoleSelectorScreen({
    super.key,
    required this.onRoleSelected,
    required this.onSkip,
  });

  final ValueChanged<AppRole> onRoleSelected;
  final VoidCallback onSkip;

  @override
  State<TestRoleSelectorScreen> createState() => _TestRoleSelectorScreenState();
}

class _TestRoleSelectorScreenState extends State<TestRoleSelectorScreen> {
  late AppRole _selectedRole =
      MockAuthService().getCurrentRole() ?? AppRole.citizen;
  late AdminTier _tier =
      MockAuthService().getCurrentAdminTier() ?? AdminTier.superAdmin;
  Region? _region = MockAuthService().getCurrentRegion();
  Assembly? _assembly = MockAuthService().getCurrentAssembly();
  late bool _mustChangePassword = MockAuthService()
      .mustChangePasswordOnFirstLogin();
  bool _saving = false;
  String? _assemblyError;

  static const _roles = <AppRole>[
    AppRole.systemAdministrator,
    AppRole.ministrySupervisor,
    AppRole.municipalOfficer,
    AppRole.citizen,
    AppRole.maintenanceTeam,
  ];

  /// Resets the Admin Tier back to Super Admin whenever System Administrator
  /// is freshly picked, so reselecting it doesn't silently carry over
  /// whatever tier a previous test session (or an earlier toggle in this
  /// same visit) left behind — easy to mistake for Super-Admin-only content
  /// having broken, since Admin tier hides it by design.
  void _selectRole(AppRole role) {
    setState(() {
      _selectedRole = role;
      if (role == AppRole.systemAdministrator) {
        _tier = AdminTier.superAdmin;
        _assemblyError = null;
      }
    });
  }

  Future<void> _continue() async {
    if (_saving) return;
    final needsAssembly =
        _selectedRole == AppRole.systemAdministrator &&
        _tier == AdminTier.admin;
    if (needsAssembly && _assembly == null) {
      setState(
        () => _assemblyError = 'Select the assembly this account manages',
      );
      return;
    }
    setState(() => _saving = true);
    await MockAuthService().selectRole(
      _selectedRole,
      adminTier: _selectedRole == AppRole.systemAdministrator ? _tier : null,
      region: needsAssembly ? _region : null,
      assembly: needsAssembly ? _assembly : null,
      mustChangePasswordOnFirstLogin: _selectedRole == AppRole.citizen
          ? false
          : _mustChangePassword,
    );
    if (!mounted) return;
    widget.onRoleSelected(_selectedRole);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: AppRadius.allXl,
                      child: Image.asset(
                        AppAssets.logoApp,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Select Test Role',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Temporary mock auth for checking every module route before Firebase is connected.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RadioGroup<AppRole>(
                    groupValue: _selectedRole,
                    onChanged: (role) {
                      if (_saving || role == null) return;
                      _selectRole(role);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: AppRadius.allMd,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          for (final role in _roles)
                            _RoleOption(
                              role: role,
                              onChanged: _saving ? null : _selectRole,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedRole == AppRole.systemAdministrator) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text('Admin Tier', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    RadioGroup<AdminTier>(
                      groupValue: _tier,
                      onChanged: (tier) {
                        if (_saving || tier == null) return;
                        setState(() {
                          _tier = tier;
                          _assemblyError = null;
                        });
                      },
                      child: Row(
                        children: [
                          for (final tier in AdminTier.values)
                            Expanded(
                              child: RadioListTile<AdminTier>(
                                value: tier,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  tier.label,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_tier == AdminTier.admin) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'This account manages one assembly\'s day-to-day '
                        'users — select which one.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RegionAssemblyPicker(
                        region: _region,
                        assembly: _assembly,
                        assemblyErrorText: _assemblyError,
                        onRegionChanged: (region) => setState(() {
                          _region = region;
                          _assemblyError = null;
                        }),
                        onAssemblyChanged: (assembly) => setState(() {
                          _assembly = assembly;
                          _assemblyError = null;
                        }),
                      ),
                    ],
                  ],
                  if (_selectedRole != AppRole.citizen) ...[
                    const SizedBox(height: AppSpacing.md),
                    CheckboxListTile(
                      value: _mustChangePassword,
                      onChanged: _saving
                          ? null
                          : (value) => setState(
                              () => _mustChangePassword = value ?? false,
                            ),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Simulate first login with temp password',
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text(
                        'Routes this account to the forced password reset '
                        'screen after sign-in.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _saving ? null : _continue,
                    child: Text(_saving ? 'Saving...' : 'Continue'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: const Text('Skip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({required this.role, required this.onChanged});

  final AppRole role;
  final ValueChanged<AppRole>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onChanged == null ? null : () => onChanged!(role),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Radio<AppRole>(value: role),
            const SizedBox(width: AppSpacing.xs),
            Icon(role.icon, color: AppColors.primary, size: AppIconSize.md),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _labelFor(role),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(AppRole role) {
    return switch (role) {
      AppRole.systemAdministrator => 'Admin',
      AppRole.ministrySupervisor => 'Ministry',
      AppRole.municipalOfficer => 'Municipal',
      AppRole.citizen => 'Citizen',
      AppRole.maintenanceTeam => 'Maintenance',
    };
  }
}
