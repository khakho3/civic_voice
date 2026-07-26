import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_dropdown_field.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/coming_soon_badge.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/settings_section.dart';
import '../models/admin_system_settings_data.dart';
import '../services/admin_system_settings_directory.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-007 — System Settings.
///
/// Approved states (Figma "06/Settings" export): Default, Loading,
/// Offline, Error ("Something went wrong"), Unauthorized — the screen's
/// own load state, [AdminSystemSettingsViewState] — plus Saving, Saved,
/// Failed, which are outcomes of the in-place "Save Changes" action and
/// kept out of that enum entirely; see [SystemSettingsSaveState]'s own
/// doc comment for why, and why [failed] specifically is preview-only via
/// [initialSaveState].
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
/// The approved export's "Platform Name" field was dropped entirely — see
/// [SystemSettingsData]'s doc comment for why. A later pass dropped
/// "Default Language" down to a frozen, badge-only row (no multi-language
/// content anywhere in the app), removed "Enforce two-factor
/// authentication" entirely (out of scope for this system), removed the
/// whole "Data Retention" section (no real storage/backup process to
/// govern), and — the one real bug fix in that pass — made "Maintenance
/// Mode" and "Public status page" genuinely inert (`Switch.onChanged:
/// null`) rather than a live switch sitting next to a "Coming Soon" badge
/// that implied it wasn't.
///
/// Backed by [AdminSystemSettingsDirectory] rather than screen-local
/// state — "Save Changes" used to silently reset back to
/// [mockSystemSettings] every time this screen was left and reopened,
/// which also meant nothing else in the app could ever observe a real
/// saved value. [AdminSystemActivityScreen]'s audit-logging gate and
/// [IdleSessionTimer]'s session-timeout duration both read the same
/// directory this screen writes to.
///
/// "Reset Changes"/"Save Changes" only appear once the draft differs from
/// the last-saved snapshot — matching the export's own Default frame
/// (no button row) versus its Saving/Failed frames (button row visible).
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
    this.onNavigateToActivity,
    this.onNavigateToMaintenanceTeams,
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

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;

  /// Forwarded to [AdminScaffold]'s drawer.
  final VoidCallback? onOpenProfile;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  late AdminSystemSettingsViewState _state = widget.initialState;
  late SystemSettingsSaveState _saveState = widget.initialSaveState;
  SystemSettingsData _original =
      AdminSystemSettingsDirectory.instance.settings.value;
  late SystemSettingsData _draft = _original;

  @override
  void initState() {
    super.initState();
    AdminSystemSettingsDirectory.instance.settings.addListener(
      _syncSavedSettings,
    );
    if (Firebase.apps.isNotEmpty &&
        widget.initialState == AdminSystemSettingsViewState.loaded &&
        !AdminSystemSettingsDirectory.instance.hasLiveSnapshot) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    AdminSystemSettingsDirectory.instance.settings.removeListener(
      _syncSavedSettings,
    );
    super.dispose();
  }

  void _syncSavedSettings() {
    if (!mounted || _draft != _original) return;
    setState(() {
      _original = AdminSystemSettingsDirectory.instance.settings.value;
      _draft = _original;
    });
  }

  Future<void> _load() async {
    setState(() => _state = AdminSystemSettingsViewState.loading);
    try {
      await AdminSystemSettingsDirectory.instance.refresh();
      if (mounted) {
        setState(() => _state = AdminSystemSettingsViewState.loaded);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _state = AdminSystemSettingsViewState.error);
      }
    }
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
    try {
      await AdminSystemSettingsDirectory.instance.save(_draft);
      if (!mounted) return;
      setState(() {
        _original = _draft;
        _saveState = SystemSettingsSaveState.saved;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saveState = SystemSettingsSaveState.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: AdminTab.settings,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.maintenance) {
          widget.onNavigateToMaintenanceTeams?.call();
        }
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
      onOpenMaintenanceTeams: widget.onNavigateToMaintenanceTeams,
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
                onPrimaryAction: _load,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              AdminSystemSettingsViewState.error => AppStateMessage(
                icon: AppIcons.warning,
                badgeColor: AppColors.error,
                title: 'Something went wrong',
                message: 'Unable to load system settings right now.',
                primaryActionLabel: 'Retry',
                onPrimaryAction: _load,
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
          _ => const SizedBox.shrink(),
        },
        SettingsSection(
          icon: AppIcons.filter,
          title: 'General Configuration',
          children: [
            SettingsRow(
              label: 'Default Language',
              badge: const ComingSoonBadge(),
              trailing: Text(
                'English',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SettingsRow(
              label: 'Maintenance Mode',
              badge: const ComingSoonBadge(),
              description:
                  'Restricts platform access during approved maintenance.',
              trailing: const Switch(value: false, onChanged: null),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          icon: AppIcons.shield,
          title: 'Security & Access',
          children: [
            SettingsRow(
              label: 'Session timeout',
              description: 'Signs out an idle session automatically.',
              trailing: _InlineDropdown(
                value: draft.sessionTimeout,
                options: kSessionTimeoutOptions,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(sessionTimeout: v)),
              ),
            ),
            SettingsRow(
              label: 'Audit logging',
              description: 'Retains administrative activity records.',
              trailing: Switch(
                value: draft.auditLogging,
                onChanged: (v) => onUpdate((d) => d.copyWith(auditLogging: v)),
              ),
            ),
            SettingsRow(
              label: 'Allow new account creation',
              description: 'Turn off to freeze provisioning platform-wide.',
              trailing: Switch(
                value: draft.allowNewAccountCreation,
                onChanged: (v) =>
                    onUpdate((d) => d.copyWith(allowNewAccountCreation: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SettingsSection(
          icon: AppIcons.globe,
          title: 'Service Preferences',
          children: [
            SettingsRow(
              label: 'Public status page',
              badge: const ComingSoonBadge(),
              description: 'Shows approved system availability updates.',
              trailing: const Switch(value: true, onChanged: null),
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
    // expanded: false — hugs whatever the selected value actually needs
    // ("English", "Daily") instead of stretching to fill the row, which
    // used to turn every short value into an oversized pill with dead
    // space before the chevron.
    return AppDropdownField<String>(
      hint: '',
      value: value,
      expanded: false,
      items: [
        for (final option in options)
          AppDropdownItem(value: option, label: option),
      ],
      onChanged: onChanged == null
          ? null
          : (selected) {
              if (selected != null) onChanged!(selected);
            },
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
      ],
    );
  }
}
