import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/kebab_menu_button.dart';
import '../../../widgets/language_preference_row.dart';
import '../../../widgets/profile_action_row.dart';
import '../../../widgets/profile_edit_action_bar.dart';
import '../../../widgets/profile_field_row.dart';
import '../../../widgets/profile_header_card.dart';
import '../../../widgets/profile_section.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/theme_preference_row.dart';
import '../models/officer_profile.dart';
import '../widgets/municipal_detail_header.dart';

/// MUN-009 — Municipal Profile.
///
/// Approved states (Figma "09 - Profile" section): Default, Editing,
/// Loading, Success, Error, Offline.
///
/// "Error" in the approved frame is specifically the *edit form* rejecting
/// invalid input on Save — not a failure to load the profile in the first
/// place, so unlike every other screen's "Error" state it isn't a
/// full-page replacement with a "Try again" action. It's kept as its own
/// enum value (matching the approved frame, and this module's existing
/// precedent of giving every named Figma state its own case, e.g. Report
/// Progress's `missingEvidence`) purely as an entry point for previewing
/// that scenario — real interactive validation failures stay on [editing]
/// and surface through [_fieldErrors] instead of switching enum values, so
/// the field the user is actively correcting doesn't get swapped out from
/// under them. Email/Phone are no longer editable here (an
/// admin-provisioned account's contact credentials are admin-only — see
/// [_ProfileEditForm]'s own doc comment), so Full Name is the only field
/// that can still fail validation; the preview reproduces a blank-name
/// error rather than the export's original invalid-email scenario.
enum MunicipalProfileViewState {
  loading,
  loaded,
  editing,
  error,
  success,
  offline,
}

class MunicipalProfileScreen extends StatefulWidget {
  const MunicipalProfileScreen({
    super.key,
    this.initialState = MunicipalProfileViewState.loaded,
    this.onBack,
    this.onChangePassword,
    this.onLogOut,
    this.initialProfile,
    this.onSaveProfile,
  });

  final MunicipalProfileViewState initialState;

  /// Pops one level — wired to the header's back arrow (Default/Loading/
  /// Success/Offline) only; the same slot shows a close (X) icon during
  /// Editing/Error, which cancels the edit instead (see [_cancel]).
  final VoidCallback? onBack;

  /// Opens the shared Change Password screen (AppRoutes.changePassword).
  final VoidCallback? onChangePassword;

  /// Fired after the log-out confirmation dialog is accepted. Nullable:
  /// there's no real authentication flow to sign out of yet.
  final VoidCallback? onLogOut;
  final OfficerProfile? initialProfile;
  final Future<bool> Function(String fullName)? onSaveProfile;

  @override
  State<MunicipalProfileScreen> createState() => _MunicipalProfileScreenState();
}

class _MunicipalProfileScreenState extends State<MunicipalProfileScreen> {
  late MunicipalProfileViewState _state = widget.initialState;
  late OfficerProfile _profile = widget.initialProfile ?? OfficerProfile.mock();
  late final _nameController = TextEditingController(text: _profile.name);
  Map<String, String> _fieldErrors = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The approved Error frame shows a pre-filled failure scenario rather
    // than a blank form — reproduce it (via the one field still editable)
    // so `initialState: .error` previews something instead of nothing.
    if (widget.initialState == MunicipalProfileViewState.error) {
      _nameController.text = '';
      _fieldErrors = {'name': 'Full name is required'};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _fieldErrors = {};
      _state = MunicipalProfileViewState.editing;
    });
  }

  void _cancel() {
    _nameController.text = _profile.name;
    setState(() {
      _fieldErrors = {};
      _state = MunicipalProfileViewState.loaded;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required';

    setState(() {
      _fieldErrors = errors;
      _state = MunicipalProfileViewState.editing;
    });
    if (errors.isNotEmpty) return;

    // The form and its Save/Cancel controls stay on screen through the
    // save attempt (ProfileEditActionBar's own `saving` shows the button
    // spinner) instead of swapping to the full-page loading skeleton —
    // that skeleton is reserved for the initial profile fetch, not for
    // save, which previously made the whole form (and its buttons) vanish
    // mid-save with nothing left to show progress.
    setState(() => _saving = true);
    final saved = await widget.onSaveProfile?.call(name) ?? true;
    if (!mounted) return;
    if (!saved) {
      setState(() {
        _saving = false;
        _state = MunicipalProfileViewState.error;
      });
      return;
    }
    setState(() {
      _saving = false;
      _profile = _profile.copyWith(name: name);
      _state = MunicipalProfileViewState.success;
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: "You'll need to sign back in to access the municipal console.",
      confirmLabel: 'Log Out',
      destructive: true,
    );
    if (confirmed) widget.onLogOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        _state == MunicipalProfileViewState.editing ||
        _state == MunicipalProfileViewState.error;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  SizedBox(height: MunicipalDetailHeader.topInset(context)),
                  if (_state == MunicipalProfileViewState.offline)
                    const _OfflineBanner(),
                  if (_state == MunicipalProfileViewState.success)
                    const _SuccessBanner(),
                  Expanded(
                    child: switch (_state) {
                      MunicipalProfileViewState.loading =>
                        const _LoadingSkeleton(),
                      MunicipalProfileViewState.loaded => _ProfileView(
                        profile: _profile,
                        onChangePassword: widget.onChangePassword,
                      ),
                      MunicipalProfileViewState.success => _ProfileView(
                        profile: _profile,
                        onChangePassword: widget.onChangePassword,
                      ),
                      MunicipalProfileViewState.offline => _ProfileView(
                        profile: _profile,
                        onChangePassword: widget.onChangePassword,
                      ),
                      MunicipalProfileViewState.editing ||
                      MunicipalProfileViewState.error => _ProfileEditForm(
                        profile: _profile,
                        nameController: _nameController,
                        fieldErrors: _fieldErrors,
                      ),
                    },
                  ),
                  if (isEditing)
                    ProfileEditActionBar(
                      onCancel: _cancel,
                      onSave: _save,
                      saving: _saving,
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: MunicipalDetailHeader(
              title: isEditing ? 'Edit Profile' : 'Municipal Profile',
              referenceId: _profile.employeeId,
              subtitlePrefix: 'ID ',
              leadingIcon: isEditing ? AppIcons.close : AppIcons.back,
              onBack: isEditing ? (_saving ? null : _cancel) : widget.onBack,
              trailing: isEditing
                  ? TextButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: AppIconSize.sm,
                              height: AppIconSize.sm,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    )
                  : KebabMenuButton<void>(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: _startEditing,
                          child: const Text('Edit Profile'),
                        ),
                        PopupMenuItem(
                          onTap: _confirmLogOut,
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Offline / success banners
// ---------------------------------------------------------------------------

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            AppIcons.offline,
            size: AppIconSize.sm,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Offline Mode — Profile changes will sync when reconnected',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.success.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(
            AppIcons.success,
            size: AppIconSize.sm,
            color: AppColors.success,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Profile saved successfully',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View mode — Default / Success / Offline share this
// ---------------------------------------------------------------------------

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile, this.onChangePassword});

  final OfficerProfile profile;
  final VoidCallback? onChangePassword;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        ProfileHeaderCard(
          name: profile.name,
          subtitle: profile.role,
          pills: [
            if (profile.verifiedOfficial)
              const TintedBadge(
                icon: AppIcons.verify,
                label: 'Verified Official',
                color: AppColors.primary,
                textColor: AppColors.primary,
              ),
            TintedBadge(
              label: 'ID #${profile.employeeId}',
              color: colorScheme.onSurfaceVariant,
              textColor: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.profile,
          title: 'Contact Information',
          children: [
            ProfileFieldRow(label: 'Phone', value: profile.phone),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(label: 'Assembly', value: profile.department),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(label: 'Region', value: profile.region),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.systemTheme,
          title: 'System Preferences',
          children: const [
            ThemePreferenceRow(),
            Divider(height: AppSpacing.lg),
            LanguagePreferenceRow(),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Editing mode — Editing / Error share this
// ---------------------------------------------------------------------------

/// Email and Phone render locked (no [TextFormField], just a caption), same
/// treatment Department already gets — an admin-provisioned account's
/// contact credentials are set by whoever provisioned it, not
/// self-editable. Changing either means a real identity change (a
/// different sign-in email, a different verified number), so it goes
/// through an administrator instead of a self-service field. Full Name is
/// the only field a Municipal Officer can change here.
class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.profile,
    required this.nameController,
    required this.fieldErrors,
  });

  final OfficerProfile profile;
  final TextEditingController nameController;
  final Map<String, String> fieldErrors;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        ProfileHeaderCard(name: profile.name, subtitle: profile.role),
        const SizedBox(height: AppSpacing.lg),
        ProfileSection(
          icon: AppIcons.profile,
          title: 'Personal Information',
          children: [
            ProfileFieldRow(
              label: 'Full Name',
              controller: nameController,
              editable: true,
              errorText: fieldErrors['name'],
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Phone Number',
              value: profile.phone,
              caption: 'Contact your administrator to change this',
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(
              label: 'Assembly',
              value: profile.department,
              caption: 'Set by your administrator',
            ),
            const SizedBox(height: AppSpacing.sm),
            ProfileFieldRow(label: 'Region', value: profile.region),
          ],
        ),
      ],
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Center(child: block(width: 80, height: 80, radius: 40)),
        const SizedBox(height: AppSpacing.md),
        Center(child: block(width: 160, height: 20)),
        const SizedBox(height: AppSpacing.sm),
        Center(child: block(width: 200, height: 14)),
        const SizedBox(height: AppSpacing.xl),
        block(height: 160, radius: 12),
        const SizedBox(height: AppSpacing.md),
        block(height: 120, radius: 12),
      ],
    );
  }
}
