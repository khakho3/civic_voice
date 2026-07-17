import 'package:flutter/material.dart';
import 'package:civic_voice/core/theme/app_theme.dart';

/// MNT-007 — Maintenance Profile.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToTasks,
  });

  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToTasks;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppScreenState _state = AppScreenState.success;

  final TextEditingController _nameController = TextEditingController(
    text: 'Marcus Johnson',
  );

  // Admin-set contact credentials — read-only here (see [_ProfileForm]'s
  // own doc comment), so these are plain values, not editable controllers.
  static const _email = 'marcus.johnson@civicvoice.gov';
  static const _phone = '+1 (555) 018-2940';

  String? _nameError;
  bool _changesSaved = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameError = 'Full name is required.';
        _changesSaved = false;
      });
      return;
    }
    setState(() {
      _nameError = null;
      _changesSaved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CivicVoice')),
      body: SafeArea(child: _buildBody(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(AppIcons.task), label: 'Tasks'),
          NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
        ],
        onDestinationSelected: (index) {
          if (index == 0) {
            widget.onNavigateToDashboard?.call();
          } else if (index == 1) {
            widget.onNavigateToTasks?.call();
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case AppScreenState.loading:
        return const _LoadingView();
      case AppScreenState.empty:
        return _EmptyView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.error:
        return _ErrorView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.offline:
        return _OfflineView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.permission:
        return _PermissionView(
          onRetry: () => setState(() => _state = AppScreenState.success),
        );
      case AppScreenState.disabled:
        return _buildForm(context, disabled: true);
      case AppScreenState.success:
        return _buildForm(context);
    }
  }

  Widget _buildForm(BuildContext context, {bool disabled = false}) {
    return _ProfileForm(
      disabled: disabled,
      nameController: _nameController,
      email: _email,
      phone: _phone,
      nameError: _nameError,
      changesSaved: _changesSaved,
      onFieldChanged: disabled
          ? null
          : (_) {
              if (_changesSaved || _nameError != null) {
                setState(() {
                  _changesSaved = false;
                  _nameError = null;
                });
              }
            },
      onSave: disabled ? null : _handleSave,
    );
  }
}

/// Email and Phone render as locked [_InfoTile]s, the same read-only
/// treatment Department/District/Employee ID already get — an
/// admin-provisioned account's contact credentials are set by whoever
/// provisioned it, not self-editable (changing either means a real
/// identity change: a different sign-in email, a different verified
/// number). Full Name is the only field a maintenance technician can
/// change here.
class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.disabled,
    required this.nameController,
    required this.email,
    required this.phone,
    required this.nameError,
    required this.changesSaved,
    required this.onFieldChanged,
    required this.onSave,
  });

  final bool disabled;
  final TextEditingController nameController;
  final String email;
  final String phone;
  final String? nameError;
  final bool changesSaved;
  final ValueChanged<String>? onFieldChanged;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;

    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: IgnorePointer(
        ignoring: disabled,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('My Profile', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Manage professional credentials',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (changesSaved) ...[
              _SavedBanner(semantic: semantic),
              const SizedBox(height: AppSpacing.md),
            ],
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      AppIcons.profile,
                      size: AppIconSize.xl,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(nameController.text, style: textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Chip(label: const Text('Senior Technician')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.maintenanceTeam,
                    label: 'Department',
                    value: 'Maintenance',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _InfoTile(
                    icon: AppIcons.location,
                    label: 'District',
                    value: 'West District',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoTile(
              icon: AppIcons.idCard,
              label: 'Employee ID',
              value: 'CV-2940-MJ',
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Personal Information', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Full Name',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: nameController,
              onChanged: onFieldChanged,
              enabled: !disabled,
              decoration: InputDecoration(
                hintText: 'Full Name',
                prefixIcon: const Icon(AppIcons.profile),
                errorText: nameError,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Contact Information', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            _InfoTile(
              icon: AppIcons.email,
              label: 'Email',
              value: email,
              caption: 'Contact your administrator to change this',
            ),
            const SizedBox(height: AppSpacing.sm),
            _InfoTile(
              icon: AppIcons.phone,
              label: 'Phone',
              value: phone,
              caption: 'Contact your administrator to change this',
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedBanner extends StatelessWidget {
  const _SavedBanner({required this.semantic});
  final AppSemanticColors semantic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: semantic.success.withValues(alpha: 0.08),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: semantic.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.success, color: semantic.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changes saved',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: semantic.success),
                ),
                Text(
                  'Permitted profile fields were updated.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
  });
  final IconData icon;
  final String label;
  final String value;

  /// Shown under [value] to explain why this field is read-only, e.g.
  /// "Contact your administrator to change this."
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: AppIconSize.md, color: colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: textTheme.titleSmall),
                  if (caption != null)
                    Text(
                      caption!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Loading profile',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Retrieving maintenance staff information.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.profile,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No profile data',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Staff profile information is not available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.error, size: AppIconSize.xl, color: semantic.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load profile',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try again without exposing administrator-only information.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.error),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  const _OfflineView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.offline,
              size: AppIconSize.xl,
              color: semantic.warning,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Offline', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Reconnect to save profile changes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: semantic.warning),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.permissionDenied,
              size: AppIconSize.xl,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Permission required',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Maintenance profile access is required.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
