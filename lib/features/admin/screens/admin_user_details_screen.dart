import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/app_role.dart';
import '../../../models/assembly.dart';
import '../../../models/region.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../models/admin_role_management_data.dart';
import '../models/admin_user_management_data.dart';
import '../services/admin_session.dart';
import '../services/admin_user_directory.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/region_assembly_picker.dart';

const _kMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) =>
    '${date.day} ${_kMonthNames[date.month - 1]} ${date.year}';

String _formatSignIn(DateTime date) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  if (!isToday) return _formatDate(date);
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return 'Today, $hh:$mm';
}

/// ADM-003 — User Details.
///
/// Approved states (Figma "07/Details" export): Default, Loading, Offline,
/// Error ("Something went wrong"), Unauthorized, Success. No Validation
/// state: the export shows one where both dropdowns turn red with "Select
/// a valid role"/"Select an account status" errors, but both fields are
/// always backed by a real, non-null enum value in this implementation —
/// there's no way to reach an unselected/invalid state through the UI, so
/// there's nothing for that validation to ever catch.
///
/// This is the screen [AppRole]/[AdminUserStatus]/[AdminTier] all
/// converge on: "Assigned Role" edits [AppRole] (reassigning which module
/// an account can open), "Account Status" edits [AdminUserStatus], and —
/// new here, not in the export — selecting [AppRole.systemAdministrator]
/// reveals an "Admin Tier" selector for [AdminTier]. Francis was explicit
/// that any account-creation/editing surface must expose Admin and Super
/// Admin as distinct choices rather than a single generic "Admin", so this
/// selector isn't optional polish.
///
/// The export's top badge reads "Platform User" — a placeholder that
/// doesn't correspond to anything (every account in this system has one of
/// the five real [AppRole]s) — replaced with a live pill reflecting
/// whichever role is currently selected in the form below, the same
/// "preview the pending change" treatment "Permissions Summary" gets too.
///
/// "User Information" (name/email/User ID) renders read-only: nothing in
/// the export suggests admins can rename another account or change its
/// email from here, and User ID is never editable anywhere.
///
/// Saving is local to this screen only — [AdminUserItem]'s edits aren't
/// bubbled back into User Management's own separate in-memory list (same
/// "wire it up once the next screen needs it" scoping as every other
/// screen's mock data), but [onSaveChanges] is there for the app shell to
/// use once that's worth doing.
enum AdminUserDetailsViewState { loading, loaded, offline, error, unauthorized }

class AdminUserDetailsScreen extends StatefulWidget {
  const AdminUserDetailsScreen({
    super.key,
    required this.user,
    this.initialState = AdminUserDetailsViewState.loaded,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onNavigateToMaintenanceTeams,
    this.onOpenProfile,
    this.onNotificationsTap,
    this.onSaveChanges,
  });

  final AdminUserItem user;
  final AdminUserDetailsViewState initialState;

  final VoidCallback? onNavigateToDashboard;

  /// Also "Cancel"'s destination — this screen is a drill-down from the
  /// user list, so both the bottom-nav "Users" tab and "Cancel" mean the
  /// same thing: go back without necessarily having saved.
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onNotificationsTap;

  /// Fired with the edited record when "Save Changes" succeeds. See the
  /// class doc comment — nullable because nothing consumes it yet.
  final ValueChanged<AdminUserItem>? onSaveChanges;

  @override
  State<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends State<AdminUserDetailsScreen> {
  late AdminUserDetailsViewState _state = widget.initialState;
  late AppRole _role = widget.user.role;
  late AdminUserStatus _status = widget.user.status;
  late AdminTier? _tier = widget.user.adminTier;
  late Region? _region = widget.user.region;
  late Assembly? _assembly = widget.user.assembly;
  bool _showSuccess = false;

  void _retry() {
    setState(() => _state = AdminUserDetailsViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = AdminUserDetailsViewState.loaded);
      }
    });
  }

  Future<void> _handleCancel() async {
    final dirty =
        _role != widget.user.role ||
        _status != widget.user.status ||
        _tier != widget.user.adminTier ||
        _region != widget.user.region ||
        _assembly != widget.user.assembly;
    if (dirty) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message:
            'Unsaved changes to ${widget.user.name}\'s account will be '
            'lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    widget.onNavigateToUsers?.call();
  }

  Future<void> _save() async {
    final session = AdminSession.instance;
    // A session that can't edit roles/deactivate accounts never changed
    // _role/_status in the first place (their dropdowns render read-only —
    // see _DetailsForm), so these effectively no-op for that session but
    // stay here as a second guarantee against a stale/replayed save.
    final effectiveRole = session.canEditUserRoles ? _role : widget.user.role;
    final effectiveStatus = session.canDeactivateUsers
        ? _status
        : widget.user.status;
    final roleChanged = effectiveRole != widget.user.role;
    final confirmed = await showConfirmDialog(
      context,
      title: 'Save access changes?',
      message: roleChanged
          ? '${widget.user.name}\'s role will change to '
                '${effectiveRole.label} and their account status will be '
                'updated.'
          : '${widget.user.name}\'s account status will be updated.',
      confirmLabel: 'Save Changes',
      destructive: roleChanged,
    );
    if (!confirmed || !mounted) return;

    final updated = widget.user.copyWith(
      role: effectiveRole,
      status: effectiveStatus,
      adminTier: effectiveRole == AppRole.systemAdministrator
          ? (_tier ?? AdminTier.admin)
          : null,
      region: AdminUserItem.roleRequiresAssembly(effectiveRole, _tier)
          ? _region
          : null,
      assembly: AdminUserItem.roleRequiresAssembly(effectiveRole, _tier)
          ? _assembly
          : null,
    );
    try {
      await AdminUserDirectory.instance.saveOnServer(updated);
    } catch (_) {
      if (mounted) setState(() => _state = AdminUserDetailsViewState.error);
      return;
    }
    if (!mounted) return;
    widget.onSaveChanges?.call(updated);
    final returnToUsers = widget.onNavigateToUsers;
    if (returnToUsers != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changes to ${widget.user.name} were saved.')),
      );
      returnToUsers();
      return;
    }
    setState(() => _showSuccess = true);
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.users,
      headerTitle: 'User Details',
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) {
          widget.onNavigateToMaintenanceTeams?.call();
        }
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onNavigateToMaintenanceTeams,
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminUserDetailsViewState.loading => const _LoadingSkeleton(),
        AdminUserDetailsViewState.loaded => _DetailsForm(
          user: widget.user,
          role: _role,
          status: _status,
          tier: _tier,
          region: _region,
          assembly: _assembly,
          showSuccess: _showSuccess,
          canEditRole: AdminSession.instance.canEditUserRoles,
          canEditStatus: AdminSession.instance.canDeactivateUsers,
          onRoleChanged: (role) => setState(() {
            _role = role;
            _showSuccess = false;
            if (role == AppRole.systemAdministrator) {
              _tier ??= AdminTier.admin;
            } else {
              _tier = null;
            }
            if (!AdminUserItem.roleRequiresAssembly(role, _tier)) {
              _region = null;
              _assembly = null;
            }
          }),
          onStatusChanged: (status) => setState(() {
            _status = status;
            _showSuccess = false;
          }),
          onTierChanged: (tier) => setState(() {
            _tier = tier;
            _showSuccess = false;
            if (!AdminUserItem.roleRequiresAssembly(_role, tier)) {
              _region = null;
              _assembly = null;
            }
          }),
          onRegionChanged: (region) => setState(() {
            _region = region;
            _showSuccess = false;
          }),
          onAssemblyChanged: (assembly) => setState(() {
            _assembly = assembly;
            _showSuccess = false;
          }),
          onCancel: _handleCancel,
          onSave: _save,
        ),
        _ => Column(
          children: [
            SizedBox(height: AdminScaffold.contentPadding(context).top),
            Expanded(
              child: switch (_state) {
                AdminUserDetailsViewState.offline => AppStateMessage(
                  icon: AppIcons.offline,
                  badgeColor: AppColors.error,
                  title: 'You\'re offline',
                  message:
                      'Check your connection and retry loading user '
                      'details.',
                  primaryActionLabel: 'Retry connection',
                  onPrimaryAction: _retry,
                  primaryActionColor: AppColors.error,
                  bordered: true,
                ),
                AdminUserDetailsViewState.error => AppStateMessage(
                  icon: AppIcons.warning,
                  badgeColor: AppColors.error,
                  title: 'Something went wrong',
                  message: 'Unable to load user details right now.',
                  primaryActionLabel: 'Retry',
                  onPrimaryAction: _retry,
                  primaryActionColor: AppColors.error,
                  bordered: true,
                ),
                AdminUserDetailsViewState.unauthorized => const AppStateMessage(
                  icon: AppIcons.permissionDenied,
                  badgeColor: AppColors.error,
                  title: 'Unauthorized Access',
                  message:
                      'Administrative privileges are required to view '
                      'user details.',
                  bordered: true,
                ),
                _ => const SizedBox.shrink(),
              },
            ),
          ],
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Form
// ---------------------------------------------------------------------------

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({
    required this.user,
    required this.role,
    required this.status,
    required this.tier,
    required this.region,
    required this.assembly,
    required this.showSuccess,
    required this.canEditRole,
    required this.canEditStatus,
    required this.onRoleChanged,
    required this.onStatusChanged,
    required this.onTierChanged,
    required this.onRegionChanged,
    required this.onAssemblyChanged,
    required this.onSave,
    this.onCancel,
  });

  final AdminUserItem user;
  final AppRole role;
  final AdminUserStatus status;
  final AdminTier? tier;
  final Region? region;
  final Assembly? assembly;
  final bool showSuccess;

  /// [AdminSession.canEditUserRoles] — an assembly Admin sees Assigned Role
  /// and Admin Tier as read-only text instead of dropdowns.
  final bool canEditRole;

  /// [AdminSession.canDeactivateUsers] — an assembly Admin sees Account
  /// Status as read-only text instead of a dropdown.
  final bool canEditStatus;
  final ValueChanged<AppRole> onRoleChanged;
  final ValueChanged<AdminUserStatus> onStatusChanged;
  final ValueChanged<AdminTier> onTierChanged;
  final ValueChanged<Region?> onRegionChanged;
  final ValueChanged<Assembly?> onAssemblyChanged;
  final VoidCallback? onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final chromeInset = AdminScaffold.contentPadding(context);
    final isAdmin = role == AppRole.systemAdministrator;
    final needsAssembly = AdminUserItem.roleRequiresAssembly(role, tier);
    final preview = user.copyWith(
      role: role,
      status: status,
      adminTier: isAdmin ? (tier ?? AdminTier.admin) : null,
      region: needsAssembly ? region : null,
      assembly: needsAssembly ? assembly : null,
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        if (showSuccess) ...[
          const _SuccessBanner(),
          const SizedBox(height: AppSpacing.sm),
        ],
        _ProfileCard(user: user, previewRole: role, previewStatus: status),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.email,
          title: 'User Information',
          child: Column(
            children: [
              _ReadOnlyField(label: 'Full Name', value: user.name),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(label: 'Phone Number', value: user.phone),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(
                label: 'Email',
                value: user.email ?? 'Not provided',
              ),
              const SizedBox(height: AppSpacing.sm),
              _ReadOnlyField(label: 'User ID', value: user.userId),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.shield,
          title: 'Access Management',
          child: Column(
            children: [
              if (canEditRole)
                _LabeledDropdown<AppRole>(
                  label: 'Assigned Role',
                  value: role,
                  items: AppRole.values,
                  itemLabel: (r) => r.label,
                  onChanged: onRoleChanged,
                )
              else
                _ReadOnlyField(label: 'Assigned Role', value: role.label),
              if (isAdmin) ...[
                const SizedBox(height: AppSpacing.sm),
                if (canEditRole)
                  _LabeledDropdown<AdminTier>(
                    label: 'Admin Tier',
                    value: tier ?? AdminTier.admin,
                    items: AdminTier.values,
                    itemLabel: (t) => t.label,
                    onChanged: onTierChanged,
                  )
                else
                  _ReadOnlyField(
                    label: 'Admin Tier',
                    value: (tier ?? AdminTier.admin).label,
                  ),
              ],
              if (needsAssembly) ...[
                const SizedBox(height: AppSpacing.sm),
                RegionAssemblyPicker(
                  region: region,
                  assembly: assembly,
                  onRegionChanged: onRegionChanged,
                  onAssemblyChanged: onAssemblyChanged,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (canEditStatus)
                _LabeledDropdown<AdminUserStatus>(
                  label: 'Account Status',
                  value: status,
                  items: AdminUserStatus.values,
                  itemLabel: (s) => s.label,
                  onChanged: onStatusChanged,
                )
              else
                _ReadOnlyField(label: 'Account Status', value: status.label),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.shield,
          title: 'Permissions Summary',
          child: preview.permissionSummary.isEmpty
              ? Text(
                  'No permissions granted.',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final label in preview.permissionSummary)
                      _TagChip(label),
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.task,
          title: 'Account Activity',
          child: Column(
            children: [
              _ActivityRow(
                label: 'Last sign-in',
                value: _formatSignIn(user.lastSignIn),
              ),
              const Divider(height: AppSpacing.lg),
              _ActivityRow(
                label: 'Account created',
                value: _formatDate(user.accountCreated),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: onSave,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.previewRole,
    required this.previewStatus,
  });

  final AdminUserItem user;
  final AppRole previewRole;
  final AdminUserStatus previewStatus;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.profile,
              size: AppIconSize.xl,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            user.name,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          Text(
            user.phone,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _Pill(
                icon: previewRole.icon,
                label: previewRole.label,
                color: AppColors.primary,
              ),
              _Pill(label: previewStatus.label, color: previewStatus.color),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: AppFontWeight.semiBold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
          ),
          child: Text(
            value,
            style: textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppComponentRadius.inputField,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                borderRadius: AppComponentRadius.inputField,
                icon: Icon(
                  AppIcons.chevronDown,
                  size: AppIconSize.sm,
                  color: colorScheme.onSurfaceVariant,
                ),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
                items: [
                  for (final item in items)
                    DropdownMenuItem(value: item, child: Text(itemLabel(item))),
                ],
                onChanged: (selected) {
                  if (selected != null) onChanged(selected);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: AppFontWeight.semiBold,
            ),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusResolved.withValues(alpha: 0.1),
        borderRadius: AppComponentRadius.card,
        border: Border.all(
          color: AppColors.statusResolved.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.success,
            color: AppColors.statusResolved,
            size: AppIconSize.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Changes saved',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.statusResolved,
                  ),
                ),
                Text(
                  'The user role and account status were updated '
                  'successfully.',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton
// ---------------------------------------------------------------------------

class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainer;
    final highlight = Theme.of(context).colorScheme.surfaceContainerLow;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final chromeInset = AdminScaffold.contentPadding(context);

    Widget block({double? width, double height = 16, double? radius}) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Color.lerp(
                base,
                highlight,
                reduceMotion ? 0.5 : _controller.value,
              ),
              borderRadius: BorderRadius.circular(radius ?? 4),
            ),
          );
        },
      );
    }

    Widget sectionBlock({double height = 96}) => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(height: 12, width: 100),
          const SizedBox(height: AppSpacing.sm),
          block(height: height),
        ],
      ),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: AppComponentRadius.card,
          ),
          child: Column(
            children: [
              block(width: 96, height: 96, radius: 48),
              const SizedBox(height: AppSpacing.md),
              block(height: 16, width: 160),
              const SizedBox(height: AppSpacing.xs),
              block(height: 12, width: 200),
              const SizedBox(height: AppSpacing.sm),
              block(height: 24, width: 140, radius: 20),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 130),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 100),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 60),
        const SizedBox(height: AppSpacing.lg),
        sectionBlock(height: 60),
      ],
    );
  }
}
