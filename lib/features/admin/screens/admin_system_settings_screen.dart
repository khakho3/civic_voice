import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../models/admin_system_settings_data.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-007 — System Settings.
///
/// Approved states (Figma "06/Settings" export): Default, Loading,
/// Offline, Error ("Something went wrong"), Unauthorized — the screen's
/// own load state, [AdminSystemSettingsViewState] — plus Saving, Saved,
/// Failed, Validation, which are outcomes of the in-place "Save Changes"
/// action and kept out of that enum entirely; see
/// [SystemSettingsSaveState]'s own doc comment for why, and why [failed]
/// specifically is preview-only via [initialSaveState].
///
/// Export quirks, resolved by content rather than folder/file name (the
/// same kind of split-across-two-folders slip seen throughout this app):
/// - "error" (light only) pairs with "errort" (a typo, dark only) as
///   Error's two theme variants; "unauthorized" (light only) pairs with
///   "dunauthorized" (dark only) the same way.
/// - The "empty" folder's dark frame is actually a duplicate of the
///   Saving frame, not a real Empty state — there's no genuine Empty
///   state for this screen anyway (it's a fixed settings form, not a
///   list, matching Dashboard's own lack of one), so this pairs with
///   Saving's light-only frame as its missing dark variant instead of
///   introducing an unneeded state.
///
/// "Platform Name" renders as a dropdown in the export, but it's a name,
/// not a choice from a fixed set — modeled as a text field instead (see
/// [SystemSettingsData]'s doc comment). This also makes the export's own
/// "Platform name is required" validation copy reachable: a dropdown,
/// always populated, could never actually be empty.
///
/// "Reset Changes"/"Save Changes" only appear once the draft differs from
/// the last-saved snapshot — matching the export's own Default frame
/// (no button row) versus its Saving/Failed/Validation frames (button row
/// visible).
enum AdminSystemSettingsViewState {
  loading,
  loaded,
  offline,
  error,
  unauthorized,
}

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({
    super.key,
    this.initialState = AdminSystemSettingsViewState.loaded,
    this.initialSaveState = SystemSettingsSaveState.idle,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onOpenSystemActivity,
    this.onOpenProfile,
    this.onNotificationsTap,
  });

  final AdminSystemSettingsViewState initialState;

  /// Preview/test hook for [SystemSettingsSaveState.failed] — see that
  /// enum's own doc comment for why it has no other way to be reached.
  final SystemSettingsSaveState initialSaveState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;
  final VoidCallback? onNavigateToRoles;

  final VoidCallback? onOpenSystemActivity;

  /// Forwarded to [AdminScaffold]'s drawer. Nullable: ADM-008 isn't built
  /// yet.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  late AdminSystemSettingsViewState _state = widget.initialState;
  late SystemSettingsSaveState _saveState = widget.initialSaveState;
  SystemSettingsData _original = mockSystemSettings();
  late SystemSettingsData _draft = _original;

  void _retry() {
    setState(() => _state = AdminSystemSettingsViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _state = AdminSystemSettingsViewState.loaded);
      }
    });
  }

  void _update(SystemSettingsData Function(SystemSettingsData) update) {
    setState(() {
      _draft = update(_draft);
      _saveState = SystemSettingsSaveState.idle;
    });
  }

  void _resetChanges() {
    setState(() {
      _draft = _original;
      _saveState = SystemSettingsSaveState.idle;
    });
  }

  Future<void> _saveChanges() async {
    if (_draft.platformName.trim().isEmpty) {
      setState(() => _saveState = SystemSettingsSaveState.validationError);
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      title: 'Save system settings?',
      message:
          'These changes apply platform-wide and take effect '
          'immediately for every account.',
      confirmLabel: 'Save Changes',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saveState = SystemSettingsSaveState.saving);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _original = _draft;
        _saveState = SystemSettingsSaveState.saved;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.settings,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.roles) widget.onNavigateToRoles?.call();
      },
      onOpenSystemActivity: widget.onOpenSystemActivity,
      onOpenProfile: widget.onOpenProfile,
      body: switch (_state) {
        AdminSystemSettingsViewState.loading => const _LoadingSkeleton(),
        AdminSystemSettingsViewState.loaded => _SettingsForm(
          original: _original,
          draft: _draft,
          saveState: _saveState,
          onUpdate: _update,
          onReset: _resetChanges,
          onSave: _saveChanges,
        ),
        _ => Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: AdminScaffold.contentPadding(context).top,
              bottom: AdminScaffold.contentPadding(context).bottom,
              left: AppSpacing.md,
              right: AppSpacing.md,
            ),
            child: switch (_state) {
              AdminSystemSettingsViewState.offline => AppStateMessage(
                icon: AppIcons.offline,
                badgeColor: AppColors.error,
                title: 'You\'re offline',
                message:
                    'Check your connection and retry loading system '
                    'settings.',
                primaryActionLabel: 'Retry connection',
                onPrimaryAction: _retry,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              AdminSystemSettingsViewState.error => AppStateMessage(
                icon: AppIcons.warning,
                badgeColor: AppColors.error,
                title: 'Something went wrong',
                message: 'Unable to load system settings right now.',
                primaryActionLabel: 'Retry',
                onPrimaryAction: _retry,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              _ => const AppStateMessage(
                icon: AppIcons.permissionDenied,
                badgeColor: AppColors.error,
                title: 'Unauthorized Access',
                message:
                    'Administrative privileges are required to manage '
                    'system settings.',
                bordered: true,
              ),
            },
          ),
        ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Form
// ---------------------------------------------------------------------------

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.original,
    required this.draft,
    required this.saveState,
    required this.onUpdate,
    required this.onReset,
    required this.onSave,
  });

  final SystemSettingsData original;
  final SystemSettingsData draft;
  final SystemSettingsSaveState saveState;
  final void Function(SystemSettingsData Function(SystemSettingsData)) onUpdate;
  final VoidCallback onReset;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final chromeInset = AdminScaffold.contentPadding(context);
    final dirty = draft != original;
    final showPlatformNameError =
        saveState == SystemSettingsSaveState.validationError &&
        draft.platformName.trim().isEmpty;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        switch (saveState) {
          SystemSettingsSaveState.saved => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Banner(
              icon: AppIcons.success,
              color: AppColors.statusResolved,
              title: 'Configuration saved',
              message: 'System settings were updated successfully.',
            ),
          ),
          SystemSettingsSaveState.failed => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Banner(
              icon: AppIcons.warning,
              color: AppColors.error,
              title: 'Update Failed',
              message:
                  'System settings could not be saved. No changes were '
                  'applied.',
            ),
          ),
          SystemSettingsSaveState.validationError => const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _Banner(
              icon: AppIcons.warning,
              color: AppColors.error,
              title: 'Validation Error',
              message: 'Review the highlighted configuration before saving.',
            ),
          ),
          _ => const SizedBox.shrink(),
        },
        _SettingsSection(
          icon: AppIcons.filter,
          title: 'General Configuration',
          children: [
            _SettingsRow(
              label: 'Platform Name',
              errorText: showPlatformNameError
                  ? 'Platform name is required.'
                  : null,
              trailing: _InlineTextField(
                value: draft.platformName,
                hasError: showPlatformNameError,
                onChanged: (v) => onUpdate((d) => d.copyWith(platformName: v)),
              ),
            ),
            _SettingsRow(
              label: 'Default Language',
              trailing: _InlineDropdown(
                value: draft.defaultLanguage,
                options: kLanguageOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(defaultLanguage: v)),
              ),
            ),
            _SettingsRow(
              label: 'Maintenance Mode',
              description:
                  'Restricts platform access during approved maintenance.',
              trailing: Switch(
                value: draft.maintenanceMode,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(maintenanceMode: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          icon: AppIcons.shield,
          title: 'Security & Access',
          children: [
            _SettingsRow(
              label: 'Enforce two-factor authentication',
              description: 'Required for administrator accounts.',
              trailing: Switch(
                value: draft.enforceTwoFactor,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(enforceTwoFactor: v)),
              ),
            ),
            _SettingsRow(
              label: 'Session timeout',
              trailing: _InlineDropdown(
                value: draft.sessionTimeout,
                options: kSessionTimeoutOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(sessionTimeout: v)),
              ),
            ),
            _SettingsRow(
              label: 'Audit logging',
              description: 'Retains administrative activity records.',
              trailing: Switch(
                value: draft.auditLogging,
                onChanged: (v) => onUpdate((d) => d.copyWith(auditLogging: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          icon: AppIcons.database,
          title: 'Data Retention',
          children: [
            _SettingsRow(
              label: 'Audit log retention',
              trailing: _InlineDropdown(
                value: draft.auditLogRetention,
                options: kAuditLogRetentionOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(auditLogRetention: v)),
              ),
            ),
            _SettingsRow(
              label: 'Backup schedule',
              trailing: _InlineDropdown(
                value: draft.backupSchedule,
                options: kBackupScheduleOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(backupSchedule: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _SettingsSection(
          icon: AppIcons.globe,
          title: 'Service Preferences',
          children: [
            _SettingsRow(
              label: 'Public status page',
              description: 'Shows approved system availability updates.',
              trailing: Switch(
                value: draft.publicStatusPage,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(publicStatusPage: v)),
              ),
            ),
            _SettingsRow(
              label: 'Regional data routing',
              trailing: _InlineDropdown(
                value: draft.regionalDataRouting,
                options: kRegionOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(regionalDataRouting: v)),
              ),
            ),
          ],
        ),
        if (dirty) ...[
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: const Text('Reset Changes'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: saveState == SystemSettingsSaveState.saving
                      ? null
                      : onSave,
                  child: saveState == SystemSettingsSaveState.saving
                      ? const SizedBox(
                          width: AppIconSize.sm,
                          height: AppIconSize.sm,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(color: color),
                ),
                Text(message, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

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
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: children[i],
                ),
                if (i != children.length - 1)
                  Divider(height: 1, color: colorScheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.trailing,
    this.description,
    this.errorText,
  });

  final String label;
  final Widget trailing;
  final String? description;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: description == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyLarge),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            trailing,
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

class _InlineDropdown extends StatelessWidget {
  const _InlineDropdown({
    required this.value,
    required this.options,
    this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Deliberately not `isExpanded` — that forces the control to always
    // fill its parent's full available width (`mainAxisSize.max`), which
    // is exactly what stretched every short value ("English", "Daily")
    // into an oversized pill with dead space before the chevron. Natural
    // (`mainAxisSize.min`) sizing hugs whatever the selected value
    // actually needs.
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: AppRadius.allXl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            icon: Icon(
              AppIcons.chevronDown,
              size: AppIconSize.sm,
              color: colorScheme.onSurfaceVariant,
            ),
            borderRadius: AppComponentRadius.inputField,
            items: [
              for (final option in options)
                DropdownMenuItem(value: option, child: Text(option)),
            ],
            onChanged: onChanged == null
                ? null
                : (selected) {
                    if (selected != null) onChanged!(selected);
                  },
          ),
        ),
      ),
    );
  }
}

class _InlineTextField extends StatelessWidget {
  const _InlineTextField({
    required this.value,
    this.hasError = false,
    this.onChanged,
  });

  final String value;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 140,
      child: Material(
        color: hasError
            ? AppColors.error.withValues(alpha: 0.08)
            : colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
        child: TextFormField(
          initialValue: value,
          textAlign: TextAlign.right,
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
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

    Widget rowBlock() => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(height: 14, width: 140),
                const SizedBox(height: AppSpacing.xs),
                block(height: 12, width: 200),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          block(width: 70, height: 28, radius: 14),
        ],
      ),
    );

    Widget sectionBlock() => Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(children: [rowBlock(), rowBlock()]),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        block(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        sectionBlock(),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        sectionBlock(),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        sectionBlock(),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 180),
        const SizedBox(height: AppSpacing.sm),
        sectionBlock(),
      ],
    );
  }
}
