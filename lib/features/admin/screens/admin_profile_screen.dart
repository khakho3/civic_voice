import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/confirm_dialog.dart';
import '../models/admin_profile_data.dart';
import '../widgets/admin_scaffold.dart';

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

String _formatActivity(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (date.year == yesterday.year &&
      date.month == yesterday.month &&
      date.day == yesterday.day) {
    return 'Yesterday';
  }
  return _formatDate(date);
}

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
/// Reachable only from [AdminScaffold]'s drawer (see that class's own doc
/// comment) — there's no tab slot and no other screen links to it, so
/// [AdminScaffold.selectedTab] is null: the bottom nav shows no tab as
/// active rather than falsely implying this is any one of the four,
/// matching ADM-004 Role Management's own treatment.
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
/// editable — Admin ID, Security Settings, Administrative Scope, and
/// Session are all read-only, matching what the export's own Edit/
/// Validation frames actually show changing. "Change Password"/
/// "Two-factor authentication"/"Last activity" render as tappable rows
/// with no wired destination, matching Ministry Profile's own precedent
/// for placeholder account-settings rows with nothing spec'd yet.
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
    this.onSignOut,
    this.onNotificationsTap,
  });

  final AdminProfileViewState initialState;

  /// Preview/test hook for [AdminProfileSaveState.failed] — see that
  /// enum's own doc comment for why it has no other way to be reached.
  final AdminProfileSaveState initialSaveState;

  /// Wired by the app shell so the bottom nav can switch tabs.
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToUsers;

  /// Opens ADM-004 Role Management via [AdminScaffold]'s drawer.
  final VoidCallback? onNavigateToRoles;
  final VoidCallback? onNavigateToSettings;

  final VoidCallback? onNavigateToActivity;

  /// Fired by the "Sign Out" button. Nullable: there's no real
  /// authentication flow to sign out of yet.
  final VoidCallback? onSignOut;

  final VoidCallback? onNotificationsTap;

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late AdminProfileViewState _state = widget.initialState;
  late AdminProfileSaveState _saveState = widget.initialSaveState;
  bool _editing = false;
  AdminProfileData _original = mockAdminProfile();
  late AdminProfileData _draft = _original;

  void _retry() {
    setState(() => _state = AdminProfileViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = AdminProfileViewState.loaded);
    });
  }

  void _startEdit() {
    setState(() {
      _editing = true;
      _saveState = AdminProfileSaveState.idle;
    });
  }

  void _cancelEdit() {
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

  void _saveChanges() {
    if (_draft.fullName.trim().isEmpty) {
      setState(() => _saveState = AdminProfileSaveState.validationError);
      return;
    }
    setState(() => _saveState = AdminProfileSaveState.saving);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _original = _draft;
        _saveState = AdminProfileSaveState.saved;
        _editing = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      selectedTab: null,
      headerTitle: 'Admin Profile',
      hideBottomNav: _editing,
      onNotificationsTap: widget.onNotificationsTap,
      onTabSelected: (tab) {
        if (tab == AdminTab.dashboard) widget.onNavigateToDashboard?.call();
        if (tab == AdminTab.users) widget.onNavigateToUsers?.call();
        if (tab == AdminTab.activity) widget.onNavigateToActivity?.call();
        if (tab == AdminTab.settings) widget.onNavigateToSettings?.call();
      },
      onOpenRoleManagement: widget.onNavigateToRoles,
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
          _SaveBar(saveState: saveState, onCancel: onCancel, onSave: onSave),
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
        _ProfileCard(fullName: draft.fullName),
        const SizedBox(height: AppSpacing.lg),
        _AccessSummaryCard(percent: draft.governanceChecklistPercent),
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
        _Section(
          icon: AppIcons.roleManagement,
          title: 'Administrator Information',
          trailing: editing
              ? null
              : IconButton(
                  onPressed: onStartEdit,
                  icon: const Icon(AppIcons.edit, size: AppIconSize.sm),
                  tooltip: 'Edit',
                ),
          children: [
            _ProfileField(
              label: 'Full Name',
              value: draft.fullName,
              editable: editing,
              errorText: showNameError ? 'Full name is required.' : null,
              onChanged: (v) => onUpdate((d) => d.copyWith(fullName: v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: 'Email',
              value: draft.email,
              editable: false,
              caption: editing
                  ? 'Contact your administrator to change this'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: 'Phone Number',
              value: draft.phone,
              editable: false,
              caption: editing
                  ? 'Contact your administrator to change this'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: 'Department',
              value: draft.department,
              editable: editing,
              onChanged: (v) => onUpdate((d) => d.copyWith(department: v)),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ProfileField(
              label: 'Admin ID',
              value: draft.adminId,
              editable: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.shield,
          title: 'Security Settings',
          children: [
            const _NavRow(icon: AppIcons.password, label: 'Change Password'),
            const Divider(height: AppSpacing.lg),
            _NavRow(
              icon: AppIcons.security,
              label: 'Two-factor authentication',
              trailingLabel: draft.twoFactorEnabled ? 'Enabled' : 'Disabled',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.shieldAlert,
          title: 'Administrative Scope',
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final scope in draft.administrativeScope) _TagChip(scope),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileField(
              label: 'Governance Level',
              value: draft.governanceLevel,
              editable: false,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: AppIcons.activityPulse,
          title: 'Session',
          children: [
            _NavRow(
              icon: AppIcons.activityPulse,
              label: 'Last activity',
              trailingLabel: _formatActivity(draft.lastActivity),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onSignOut == null
                    ? null
                    : () async {
                        final confirmed = await showConfirmDialog(
                          context,
                          title: 'Sign out?',
                          message:
                              'You\'ll need to sign back in to access the '
                              'admin console.',
                          confirmLabel: 'Sign Out',
                          destructive: true,
                        );
                        if (confirmed) onSignOut!();
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: const Text('Sign Out'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sits at the bottom of the screen, below the scrollable list — not the
/// last item inside it — so Save/Cancel stay reachable without scrolling
/// all the way down a screen this long to find them. [AdminScaffold]'s
/// floating bottom nav is hidden while editing (via `hideBottomNav`), so
/// this only needs to clear the raw safe-area inset, not the nav's own
/// height on top of it.
class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saveState,
    required this.onCancel,
    required this.onSave,
  });

  final AdminProfileSaveState saveState;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        safeAreaBottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
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
              onPressed: saveState == AdminProfileSaveState.saving
                  ? null
                  : onSave,
              child: saveState == AdminProfileSaveState.saving
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
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.fullName});

  final String fullName;

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
              AppIcons.verify,
              size: AppIconSize.xl,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            fullName,
            style: textTheme.titleLarge,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'Administrator account · Governance approved',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.allXl,
            ),
            child: Text(
              'Administrative privileges',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: AppFontWeight.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessSummaryCard extends StatelessWidget {
  const _AccessSummaryCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Access Summary',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text('Full platform administration', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.allXl,
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$percent% governance checklist complete',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

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
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
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
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.editable,
    this.errorText,
    this.onChanged,
    this.caption,
  });

  final String label;
  final String value;
  final bool editable;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  /// Shown under a locked (`editable: false`) field to explain why it's
  /// disabled, e.g. "Contact your administrator to change this." Ignored
  /// when [errorText] is set.
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: hasError
                ? AppColors.error.withValues(alpha: 0.08)
                : colorScheme.surfaceContainer,
            borderRadius: AppComponentRadius.inputField,
            border: hasError ? Border.all(color: AppColors.error) : null,
          ),
          child: editable
              ? TextFormField(
                  initialValue: value,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Text(
                    value,
                    style: textTheme.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: textTheme.bodySmall?.copyWith(color: AppColors.error),
          ),
        ] else if (caption != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, this.trailingLabel});

  final IconData icon;
  final String label;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailingLabel != null) ...[
          Text(
            trailingLabel!,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Icon(
          AppIcons.chevronRight,
          size: AppIconSize.sm,
          color: colorScheme.onSurfaceVariant,
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
              const SizedBox(height: AppSpacing.sm),
              block(height: 24, width: 150, radius: 20),
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
