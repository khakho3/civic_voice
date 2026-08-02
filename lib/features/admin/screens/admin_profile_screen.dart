import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/biometric_lock_preference_row.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_edit_button.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_info_button.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/profile_session_section.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/admin_profile_data.dart';
import '../services/admin_session.dart';
import '../widgets/admin_scaffold.dart';

/// ADM-008 — Admin Profile.
///
/// Approved states (Figma "03/Profile" export): Default, Edit, Loading,
/// Offline, Error ("Something went wrong"), Unauthorized, Validation,
/// Success ("Profile updated") — Saving has no dedicated frame of its own
/// in the export (Edit's own frame is reused for it), matching how the
/// Save button shows a brief spinner here the same way System Settings'
/// does. There's no Failed frame either — [AdminProfileSaveState.failed]
/// exists anyway for architectural parity with `SystemSettingsSaveState`,
/// preview-only via [initialSaveState] for the same reason: no backend to
/// actually fail a save against.
///
/// Super Admin reaches this screen from [AdminScaffold]'s drawer and retains
/// the tab shell with no selected tab. An assembly-level Admin reaches it
/// from the header profile shortcut; for that role it behaves as a drill-down
/// with a leading back button and no bottom navigation.
///
/// The export's Retry/Retry connection buttons render primary-blue rather
/// than the error-red every other screen's Offline/Error state uses, and
/// its Error/Unauthorized titles render in plain text instead of red —
/// both normalized away here for consistency, the same call already made
/// for every other floating-card-over-dimmed-content export in this
/// module ([AppStateMessage] already tints the title from [badgeColor],
/// so reusing it here doesn't take any extra work to get right).
///
/// Editing: the export's Edit frame swaps the header's bell for a "Save"
/// link — dropped in favor of a single Cancel/Save Changes bar at the
/// bottom (the same shape System Settings already uses for its own
/// dirty-state bar), rather than two controls doing the same job. Only
/// "Administrator Information" (Full Name/Email/Department) is ever
/// editable — Admin ID, Security, Administrative Scope, and Session are all
/// read-only, matching what the export's own Edit/
/// Validation frames actually show changing.
///
/// "Change Password" opens the shared, cross-module Change Password screen
/// (see that screen's own doc comment). Session contains only the explicit
/// Log Out action rather than read-only activity metadata.
enum AdminProfileViewState { loading, loaded, offline, error, unauthorized }

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({
    super.key,
    this.initialState = AdminProfileViewState.loaded,
    this.initialSaveState = AdminProfileSaveState.idle,
    this.onNavigateToDashboard,
    this.onNavigateToUsers,
    this.onNavigateToRoles,
    this.onNavigateToSettings,
    this.onNavigateToActivity,
    this.onChangePassword,
    this.onAbout,
    this.onNavigateToMaintenanceTeams,
    this.onSignOut,
    this.onNotificationsTap,
    this.initialData,
    this.onSaveProfile,
    this.onRetry,
    this.onBack,
  });

  final AdminProfileViewState initialState;

  /// Preview/test hook for [AdminProfileSaveState.failed] — see that
  /// enum's own doc comment for why it has no other way to be reached.
  final AdminProfileSaveState initialSaveState;

  /// Wired by the app shell so Super Admin's bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;
  final VoidCallback? onNavigateToMaintenanceTeams;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;

  /// Fired by the "Log Out" button. Nullable: there's no real
  /// authentication flow to sign out of yet.
  final VoidCallback? onSignOut;

  final VoidCallback? onNotificationsTap;
  final AdminProfileData? initialData;
  final Future<bool> Function(String fullName)? onSaveProfile;
  final Future<void> Function()? onRetry;

  /// Returns an assembly-level Admin to the screen that opened Profile.
  /// Super Admin keeps its existing drawer and tab-shell navigation.
  final VoidCallback? onBack;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late AdminProfileViewState _state = widget.initialState;
  late AdminProfileSaveState _saveState = widget.initialSaveState;
  bool _editing = false;
  late AdminProfileData _original;
  late AdminProfileData _draft;

  @override
  void initState() {
    super.initState();
    _original = widget.initialData ?? mockAdminProfile();
    _draft = _original;
  }

  @override
  void didUpdateWidget(covariant AdminProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing &&
        widget.initialData != null &&
        widget.initialData != oldWidget.initialData) {
      _original = widget.initialData!;
      _draft = _original;
    }
    if (widget.initialState != oldWidget.initialState) {
      _state = widget.initialState;
    }
  }

  Future<void> _retry() async {
    setState(() => _state = AdminProfileViewState.loading);
    try {
      await widget.onRetry?.call();
      if (mounted) {
        setState(() {
          _state = widget.initialData == null
              ? AdminProfileViewState.error
              : AdminProfileViewState.loaded;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _state = AdminProfileViewState.error);
    }
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _saveState = AdminProfileSaveState.idle;
    });
  }

  Future<void> _cancelEdit() async {
    if (_draft != _original) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Discard changes?',
        message: 'Your unsaved profile changes will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!confirmed || !mounted) return;
    }
    setState(() {
      _editing = false;
      _draft = _original;
      _saveState = AdminProfileSaveState.idle;
    });
  }

  void _updateDraft(AdminProfileData Function(AdminProfileData) update) {
    setState(() {
      _draft = update(_draft);
      _saveState = AdminProfileSaveState.idle;
    });
  }

  Future<void> _saveChanges() async {
    if (_draft.fullName.trim().isEmpty) {
      setState(() => _saveState = AdminProfileSaveState.validationError);
      return;
    }
    setState(() => _saveState = AdminProfileSaveState.saving);
    final save = widget.onSaveProfile;
    final success = save == null
        ? await Future<bool>.delayed(
            const Duration(milliseconds: 500),
            () => true,
          )
        : await save(_draft.fullName.trim());
    if (!mounted) return;
    setState(() {
      if (success) {
        _original = _draft;
        _saveState = AdminProfileSaveState.saved;
        _editing = false;
      } else {
        _saveState = AdminProfileSaveState.failed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = AdminSession.instance.isSuperAdmin;
    return AdminScaffold(
      selectedTab: null,
      headerTitle: 'Admin Profile',
      hideBottomNav: _editing || !isSuperAdmin,
      onBack: isSuperAdmin ? null : widget.onBack,
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
      body: switch (_state) {
        AdminProfileViewState.loading => const _LoadingSkeleton(),
        AdminProfileViewState.loaded => _ProfileBody(
          original: _original,
          draft: _draft,
          editing: _editing,
          saveState: _saveState,
          onStartEdit: _startEdit,
          onUpdate: _updateDraft,
          onCancel: _cancelEdit,
          onSave: _saveChanges,
          onChangePassword: widget.onChangePassword,
          onAbout: widget.onAbout,
          onSignOut: widget.onSignOut,
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
              AdminProfileViewState.offline => AppStateMessage(
                icon: AppIcons.offline,
                badgeColor: AppColors.error,
                title: 'You\'re offline',
                message:
                    'Check your connection and retry loading '
                    'administrator profile.',
                primaryActionLabel: 'Retry connection',
                onPrimaryAction: _retry,
                primaryActionColor: AppColors.error,
                bordered: true,
              ),
              AdminProfileViewState.error => AppStateMessage(
                icon: AppIcons.warning,
                badgeColor: AppColors.error,
                title: 'Something went wrong',
                message: 'Unable to load administrator profile data right now.',
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
                    'Administrative privileges are required to access '
                    'this profile.',
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
// Body
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.original,
    required this.draft,
    required this.editing,
    required this.saveState,
    required this.onStartEdit,
    required this.onUpdate,
    required this.onCancel,
    required this.onSave,
    this.onChangePassword,
    this.onAbout,
    this.onSignOut,
  });

  final AdminProfileData original;
  final AdminProfileData draft;
  final bool editing;
  final AdminProfileSaveState saveState;
  final VoidCallback onStartEdit;
  final void Function(AdminProfileData Function(AdminProfileData)) onUpdate;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback? onChangePassword;
  final VoidCallback? onAbout;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final chromeInset = AdminScaffold.contentPadding(context);
    final showNameError =
        saveState == AdminProfileSaveState.validationError &&
        draft.fullName.trim().isEmpty;

    return Column(
      children: [
        Expanded(child: _buildList(context, chromeInset, showNameError)),
        // A sticky bar, not the last item in the scrollable list — on a
        // screen this long, a Save button that only appears after
        // scrolling all the way down is easy to miss entirely.
        if (editing)
          ProfileEditActionBar(
            onCancel: onCancel,
            onSave: onSave,
            saving: saveState == AdminProfileSaveState.saving,
          ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    EdgeInsets chromeInset,
    bool showNameError,
  ) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        chromeInset.top + AppSpacing.md,
        AppSpacing.md,
        editing ? AppSpacing.md : chromeInset.bottom + AppSpacing.xl,
      ),
      children: [
        ProfileHeaderCard(
          name: draft.fullName,
          subtitle: 'Administrator account · Governance approved',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (saveState == AdminProfileSaveState.saved) ...[
          const _Banner(
            icon: AppIcons.success,
            color: AppColors.statusResolved,
            title: 'Profile updated',
            message: 'Administrator profile changes were saved successfully.',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (saveState == AdminProfileSaveState.failed) ...[
          const _Banner(
            icon: AppIcons.warning,
            color: AppColors.error,
            title: 'Update Failed',
            message:
                'Administrator profile changes could not be saved. No '
                'changes were applied.',
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        ProfileSection(
          icon: AppIcons.roleManagement,
          title: 'Administrator Information',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileInfoButton(
                title: 'Administrative Scope',
                message: 'This account can access these administrative areas:',
                items: draft.administrativeScope,
              ),
              if (!editing) ...[
                const SizedBox(width: AppSpacing.xs),
                ProfileEditButton(onPressed: onStartEdit),
              ],
            ],
          ),
          children: [
            ProfileFieldRow(
              label: 'Full Name',
              value: draft.fullName,
              editable: editing,
              errorText: showNameError ? 'Full name is required.' : null,
              onChanged: (v) => onUpdate((d) => d.copyWith(fullName: v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Phone Number',
              value: draft.phone,
              caption: editing
                  ? 'Contact your administrator to change this'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Department',
              value: draft.department,
              locked: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Admin ID',
              value: draft.adminId,
              locked: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Governance Level',
              value: draft.governanceLevel,
              locked: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const ProfileSection(
          icon: AppIcons.systemTheme,
          title: 'System Preferences',
          children: [
            ThemePreferenceRow(),
            Divider(height: AppSpacing.lg),
            LanguagePreferenceRow(),
            Divider(height: AppSpacing.lg),
            BiometricLockPreferenceRow(),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.info,
          title: 'About',
          children: [
            ProfileActionRow(
              icon: AppIcons.info,
              label: 'About CivicVoice',
              onTap: onAbout,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.shield,
          title: 'Security',
          children: [
            ProfileActionRow(
              icon: AppIcons.password,
              label: 'Change Password',
              onTap: onChangePassword,
            ),
          ],
        ),
        if (!editing) ...[
          const SizedBox(height: AppSpacing.lg),
          ProfileSessionSection(
            onLogOut: onSignOut == null
                ? null
                : () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Log out?',
                      message:
                          'You\'ll need to sign back in to access the admin '
                          'console.',
                      confirmLabel: 'Log Out',
                      destructive: true,
                    );
                    if (confirmed) onSignOut!();
                  },
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

    Widget cardBlock({double height = 100}) => Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: AppComponentRadius.card,
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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 220),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 130),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 140),
        const SizedBox(height: AppSpacing.lg),
        cardBlock(height: 140),
      ],
    );
  }
}
