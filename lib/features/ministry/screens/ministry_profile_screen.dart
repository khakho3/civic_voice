import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_state_message.dart';
import '../../../widgets/detail_header.dart';
import '../../../widgets/glass_card.dart';
import '../models/ministry_profile_data.dart';

/// MIN-006 — Ministry Profile.
///
/// Approved states (Figma "06/profile" export): Default, Loading, Edit,
/// Validation ("Full name is required."), Success, Error, Offline,
/// Unauthorized.
///
/// Per the spec ("17 CivicVoice - Ministry Supervisor Screen
/// Specifications", MIN-006), entry and exit are both Ministry Dashboard —
/// the same drill-down shape as MIN-005 Report Insights, reached here via
/// the header's profile avatar rather than a tab. The approved frame shows
/// the same persistent 4-tab bottom nav (with mismatched "Directory"/
/// "Settings" labels and "Profile" highlighted) as every other screen's
/// copy/paste-from-Dashboard slip, and its own header shows a hamburger
/// menu rather than a title — both corrected the same way as MIN-005: a
/// [DetailHeader] with a back arrow, no bottom nav.
///
/// Unlike every other screen this session, Error/Offline/Unauthorized here
/// are a floating dialog over a dimmed, disabled backdrop of the profile
/// shell (not a full-page replacement) — confirmed against the approved
/// frames, which consistently show this treatment across all three states
/// with a matching "Back to Safety" action, not a one-off copy/paste
/// artifact the way the header/nav mismatches are.
///
/// The frame has no visible entry point into Edit mode (no pencil icon, no
/// menu) — tapping the "Personal Information" card itself is the way in,
/// the only interactive-looking affordance the frame actually draws. Once
/// editing, the header's leading icon becomes a close (X) that cancels
/// rather than navigating away — Municipal Officer's own profile screen
/// (MUN-009) already establishes this exact pattern for the identical
/// problem (a back arrow mid-edit would silently discard changes), so this
/// reuses that precedent rather than inventing a new one.
///
/// The spec lists a "Logout Button" component and a "Logout" user action,
/// but no exported frame shows one anywhere. Added as its own row after
/// Account Metadata (with a confirmation step) since the spec requires the
/// action to exist somewhere and that's the most discoverable place for it
/// — not shown in any frame, so there was nothing to be faithful to.
///
/// The "Personal Information" card is a plain opaque surface, not
/// [GlassCard] — per [GlassCard]'s own doc comment, glass is prohibited on
/// input-heavy forms (§19.10), and this card contains real text fields once
/// editing.
enum MinistryProfileViewState {
  loading,
  view,
  edit,
  validation,
  success,
  error,
  offline,
  unauthorized,
}

class MinistryProfileScreen extends StatefulWidget {
  const MinistryProfileScreen({
    super.key,
    this.initialState = MinistryProfileViewState.view,
    this.onBack,
    this.onNotificationsTap,
    this.onLogOut,
  });

  final MinistryProfileViewState initialState;

  /// Returns to Ministry Dashboard — the spec's only entry and exit point.
  /// Also wired to the header's leading icon when not editing; during
  /// Edit/Validation that slot becomes a close (X) that cancels instead
  /// (see the class doc comment).
  final VoidCallback? onBack;

  final VoidCallback? onNotificationsTap;

  /// No account/session workflow is specified yet — placeholder pending
  /// spec, matching this module's other unwired forward-references. Wired
  /// to a confirmation dialog rather than firing directly, since logging
  /// out isn't reversible.
  final VoidCallback? onLogOut;

  @override
  State<MinistryProfileScreen> createState() => _MinistryProfileScreenState();
}

class _MinistryProfileScreenState extends State<MinistryProfileScreen> {
  late MinistryProfileViewState _state = widget.initialState;
  MinistryProfileData _profile = MinistryProfileData.mock();
  late final TextEditingController _nameController = TextEditingController(
    text: _profile.name,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: _profile.email,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: _profile.phone,
  );
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    // The approved Validation frame shows a specific pre-filled failure
    // (an empty Full Name) rather than a blank-slate form — reproduce it so
    // `initialState: .validation` previews the actual frame.
    if (widget.initialState == MinistryProfileViewState.validation) {
      _nameController.text = '';
      _fieldErrors = {'name': 'Full name is required.'};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _fieldErrors = {};
      _state = MinistryProfileViewState.edit;
    });
  }

  void _cancelEdit() {
    _nameController.text = _profile.name;
    _emailController.text = _profile.email;
    _phoneController.text = _profile.phone;
    setState(() {
      _fieldErrors = {};
      _state = MinistryProfileViewState.view;
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required.';
    if (email.isEmpty) {
      errors['email'] = 'Email is required.';
    } else if (!email.contains('@') || !email.contains('.')) {
      errors['email'] = 'Enter a valid email address.';
    }
    if (phone.isEmpty) errors['phone'] = 'Phone number is required.';

    setState(() {
      _fieldErrors = errors;
      _state = MinistryProfileViewState.edit;
    });
    if (errors.isNotEmpty) return;

    setState(() => _state = MinistryProfileViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _profile = _profile.copyWith(name: name, email: email, phone: phone);
        _state = MinistryProfileViewState.success;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _state == MinistryProfileViewState.success) {
          setState(() => _state = MinistryProfileViewState.view);
        }
      });
    });
  }

  void _retry() {
    setState(() => _state = MinistryProfileViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _state = MinistryProfileViewState.view);
    });
  }

  Future<void> _confirmLogOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) widget.onLogOut?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        _state == MinistryProfileViewState.edit ||
        _state == MinistryProfileViewState.validation;
    final showDialog =
        _state == MinistryProfileViewState.error ||
        _state == MinistryProfileViewState.offline ||
        _state == MinistryProfileViewState.unauthorized;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: DetailHeader.topInset(context)),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: showDialog,
                      child: Column(
                        children: [
                          Expanded(
                            child: switch (_state) {
                              MinistryProfileViewState.loading =>
                                const _LoadingSkeleton(),
                              MinistryProfileViewState.edit ||
                              MinistryProfileViewState.validation =>
                                _ProfileBody(
                                  profile: _profile,
                                  editing: true,
                                  nameController: _nameController,
                                  emailController: _emailController,
                                  phoneController: _phoneController,
                                  fieldErrors: _fieldErrors,
                                  onLogOut: _confirmLogOut,
                                ),
                              _ => _ProfileBody(
                                profile: _profile,
                                editing: false,
                                showSuccessBanner:
                                    _state == MinistryProfileViewState.success,
                                onEditPersonalInfo: _startEditing,
                                onLogOut: _confirmLogOut,
                              ),
                            },
                          ),
                          if (isEditing)
                            _EditActionBar(
                              onSave: _save,
                              onCancel: _cancelEdit,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (showDialog) ...[
                    const Positioned.fill(
                      child: ColoredBox(color: Color(0x80000000)),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: switch (_state) {
                          MinistryProfileViewState.error => AppStateMessage(
                            icon: AppIcons.warning,
                            badgeColor: AppColors.error,
                            title: 'Something went wrong',
                            message:
                                'Unable to load profile data. This could be '
                                'due to a temporary network issue or server '
                                'maintenance.',
                            primaryActionLabel: 'Retry',
                            onPrimaryAction: _retry,
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                          MinistryProfileViewState.offline => AppStateMessage(
                            icon: AppIcons.offline,
                            badgeColor: AppColors.error,
                            title: 'You\'re offline',
                            message:
                                'Check your connection and retry loading '
                                'profile data.',
                            primaryActionLabel: 'Retry connection',
                            onPrimaryAction: _retry,
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                          _ => AppStateMessage(
                            icon: AppIcons.permissionDenied,
                            badgeColor: AppColors.error,
                            title: 'Unauthorized Access',
                            message:
                                'You can only view and edit your own '
                                'ministry profile.',
                            secondaryActionLabel: 'Back to Safety',
                            onSecondaryAction: widget.onBack,
                            bordered: true,
                          ),
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: DetailHeader(
              title: 'My Profile',
              leadingIcon: isEditing ? AppIcons.close : AppIcons.back,
              onBack: isEditing ? _cancelEdit : widget.onBack,
              trailing: isEditing
                  ? TextButton(onPressed: _save, child: const Text('Save'))
                  : SizedBox(
                      width: AppDimensions.controlHeightStandard,
                      height: AppDimensions.controlHeightStandard,
                      child: Material(
                        color: Colors.transparent,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppComponentRadius.card,
                        ),
                        child: InkWell(
                          borderRadius: AppComponentRadius.card,
                          onTap: widget.onNotificationsTap,
                          child: Icon(
                            AppIcons.notifications,
                            size: AppIconSize.md,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile body — shared shape for View/Success/Editing/dialog-backdrop
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.editing,
    this.showSuccessBanner = false,
    this.nameController,
    this.emailController,
    this.phoneController,
    this.fieldErrors = const {},
    this.onEditPersonalInfo,
    this.onLogOut,
  });

  final MinistryProfileData profile;
  final bool editing;
  final bool showSuccessBanner;
  final TextEditingController? nameController;
  final TextEditingController? emailController;
  final TextEditingController? phoneController;
  final Map<String, String> fieldErrors;
  final VoidCallback? onEditPersonalInfo;
  final VoidCallback? onLogOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        _ProfileHeaderCard(profile: profile),
        if (showSuccessBanner) ...[
          const SizedBox(height: AppSpacing.md),
          const _SuccessBanner(),
        ],
        const SizedBox(height: AppSpacing.lg),
        Text('Personal Information', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        editing
            ? _PersonalInfoForm(
                nameController: nameController!,
                emailController: emailController!,
                phoneController: phoneController!,
                fieldErrors: fieldErrors,
              )
            : _PersonalInfoDisplay(profile: profile, onTap: onEditPersonalInfo),
        const SizedBox(height: AppSpacing.lg),
        Text('Security', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            children: [
              _ActionRow(
                icon: AppIcons.security,
                label: 'Change Password',
                // No password-change workflow is specified yet —
                // placeholder pending spec.
                onTap: () {},
              ),
              const Divider(height: AppSpacing.lg),
              _ActionRow(
                icon: AppIcons.verify,
                label: 'Two-factor authentication',
                trailingLabel: profile.twoFactorEnabled
                    ? 'Enabled'
                    : 'Disabled',
                // No 2FA management workflow is specified yet —
                // placeholder pending spec.
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Preferences', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            children: [
              _ActionRow(
                icon: AppIcons.settings,
                label: 'Dark Theme',
                trailingLabel: 'System',
                // Theme switching isn't wired to a persisted preference
                // yet — placeholder pending spec.
                onTap: () {},
              ),
              const Divider(height: AppSpacing.lg),
              _ActionRow(
                icon: AppIcons.language,
                label: 'Language',
                trailingLabel: 'English',
                // No localization workflow is specified yet — placeholder
                // pending spec.
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Account Metadata', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permissions are managed by administrators. This screen '
                'only allows editing your own profile.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final badge in profile.metadataBadges)
                    _MetadataBadge(label: badge),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        GlassCard(
          onTap: onLogOut,
          child: Row(
            children: [
              const Icon(
                AppIcons.logOut,
                size: AppIconSize.md,
                color: AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log Out',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final MinistryProfileData profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
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
            profile.name,
            style: textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            profile.ministry,
            style: textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
              profile.role,
              style: textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _ContactRow(
            icon: AppIcons.email,
            label: 'Email',
            value: profile.email,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ContactRow(
            icon: AppIcons.phone,
            label: 'Phone',
            value: profile.phone,
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: textTheme.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.statusResolved.withValues(alpha: 0.12),
        borderRadius: AppComponentRadius.card,
        border: Border.all(
          color: AppColors.statusResolved.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.success,
            size: AppIconSize.md,
            color: AppColors.statusResolved,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile updated', style: textTheme.titleSmall),
                Text(
                  'Your profile changes were saved successfully.',
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
// Personal Information — read-only display vs. editable form
// ---------------------------------------------------------------------------

/// A plain opaque surface, not [GlassCard] — per §19.10, glass is
/// prohibited on input-heavy forms. Tapping anywhere on the card is the
/// frame's only visible entry point into Edit mode (see the class doc
/// comment on [MinistryProfileScreen]).
class _PersonalInfoDisplay extends StatelessWidget {
  const _PersonalInfoDisplay({required this.profile, this.onTap});

  final MinistryProfileData profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      borderRadius: AppComponentRadius.card,
      child: InkWell(
        borderRadius: AppComponentRadius.card,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppComponentRadius.card,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReadOnlyField(label: 'Full Name', value: profile.name),
              const SizedBox(height: AppSpacing.md),
              _ReadOnlyField(label: 'Email', value: profile.email),
              const SizedBox(height: AppSpacing.md),
              _ReadOnlyField(label: 'Phone', value: profile.phone),
            ],
          ),
        ),
      ),
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

class _PersonalInfoForm extends StatelessWidget {
  const _PersonalInfoForm({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.fieldErrors,
  });

  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Map<String, String> fieldErrors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppComponentRadius.card,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditableField(
            label: 'Full Name',
            controller: nameController,
            errorText: fieldErrors['name'],
          ),
          const SizedBox(height: AppSpacing.md),
          _EditableField(
            label: 'Email',
            controller: emailController,
            errorText: fieldErrors['email'],
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          _EditableField(
            label: 'Phone',
            controller: phoneController,
            errorText: fieldErrors['phone'],
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.errorText,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;

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
        Material(
          color: colorScheme.surfaceContainer,
          borderRadius: AppComponentRadius.inputField,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
              border: hasError
                  ? OutlineInputBorder(
                      borderRadius: AppComponentRadius.inputField,
                      borderSide: const BorderSide(color: AppColors.error),
                    )
                  : InputBorder.none,
              enabledBorder: hasError
                  ? OutlineInputBorder(
                      borderRadius: AppComponentRadius.inputField,
                      borderSide: const BorderSide(color: AppColors.error),
                    )
                  : InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Text(
            errorText!,
            style: textTheme.labelSmall?.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row/badge pieces
// ---------------------------------------------------------------------------

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    this.trailingLabel,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: AppIconSize.md, color: AppColors.primary),
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
            Text(trailingLabel!, style: textTheme.bodyMedium),
            const SizedBox(width: AppSpacing.xs),
          ],
          Icon(
            AppIcons.chevronRight,
            size: AppIconSize.sm,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _MetadataBadge extends StatelessWidget {
  const _MetadataBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: AppRadius.allXl,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit action bar
// ---------------------------------------------------------------------------

class _EditActionBar extends StatelessWidget {
  const _EditActionBar({this.onSave, this.onCancel});

  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        bottomInset + AppSpacing.sm,
      ),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(AppIcons.save, size: AppIconSize.sm),
              label: const Text('Save changes'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.xl,
      ),
      children: [
        Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: base, shape: BoxShape.circle),
            ),
            const SizedBox(height: AppSpacing.md),
            block(width: 160, height: 20),
            const SizedBox(height: AppSpacing.sm),
            block(width: 120, height: 16, radius: 20),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 140),
        const SizedBox(height: AppSpacing.sm),
        block(height: 180, radius: 12),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 80),
        const SizedBox(height: AppSpacing.sm),
        block(height: 120, radius: 12),
        const SizedBox(height: AppSpacing.lg),
        block(height: 16, width: 100),
        const SizedBox(height: AppSpacing.sm),
        block(height: 120, radius: 12),
      ],
    );
  }
}
