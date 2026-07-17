import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';
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
  bool _saving = false;

  static const _roles = <AppRole>[
    AppRole.systemAdministrator,
    AppRole.ministrySupervisor,
    AppRole.municipalOfficer,
    AppRole.citizen,
    AppRole.maintenanceTeam,
  ];

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    await MockAuthService().selectRole(_selectedRole);
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
                      setState(() => _selectedRole = role);
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
                              onChanged: _saving
                                  ? null
                                  : (role) =>
                                        setState(() => _selectedRole = role),
                            ),
                        ],
                      ),
                    ),
                  ),
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
