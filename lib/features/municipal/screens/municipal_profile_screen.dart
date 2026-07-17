import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/officer_profile.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/kebab_menu_button.dart';
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
    this.onSettingsTap,
    this.onChangePassword,
    this.onLogOut,
  });

  final MunicipalProfileViewState initialState;

  /// Pops one level — wired to the header's back arrow (Default/Loading/
  /// Success/Offline) only; the same slot shows a close (X) icon during
  /// Editing/Error, which cancels the edit instead (see [_cancel]).
  final VoidCallback? onBack;

  /// Settings isn't part of this module (Issue 03) or any other module —
  /// it isn't in the project's approved scope anywhere yet, so this is a
  /// placeholder pending a future spec, not a screen this module should
  /// build.
  final VoidCallback? onSettingsTap;
  final VoidCallback? onChangePassword;

  /// No account/session workflow is specified yet (Issue 03 §7) —
  /// placeholder pending spec, matching this module's other unwired
  /// actions (Dashboard's Quick Actions, Report Progress's Share Summary).
  final VoidCallback? onLogOut;

  @override
  State<MunicipalProfileScreen> createState() => _MunicipalProfileScreenState();
}

class _MunicipalProfileScreenState extends State<MunicipalProfileScreen> {
  late MunicipalProfileViewState _state = widget.initialState;
  OfficerProfile _profile = OfficerProfile.mock();
  late final _nameController = TextEditingController(text: _profile.name);
  late final _emailController = TextEditingController(text: _profile.email);
  late final _phoneController = TextEditingController(text: _profile.phone);
  Map<String, String> _fieldErrors = {};

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
    _emailController.dispose();
    _phoneController.dispose();
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
    _emailController.text = _profile.email;
    _phoneController.text = _profile.phone;
    setState(() {
      _fieldErrors = {};
      _state = MunicipalProfileViewState.loaded;
    });
  }

  void _save() {
    final name = _nameController.text.trim();

    final errors = <String, String>{};
    if (name.isEmpty) errors['name'] = 'Full name is required';

    setState(() {
      _fieldErrors = errors;
      _state = MunicipalProfileViewState.editing;
    });
    if (errors.isNotEmpty) return;

    setState(() => _state = MunicipalProfileViewState.loading);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _profile = _profile.copyWith(name: name);
        _state = MunicipalProfileViewState.success;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _state == MunicipalProfileViewState.success) {
          setState(() => _state = MunicipalProfileViewState.loaded);
        }
      });
    });
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
                        emailController: _emailController,
                        phoneController: _phoneController,
                        fieldErrors: _fieldErrors,
                      ),
                    },
                  ),
                  if (isEditing)
                    _EditActionBar(onSave: _save, onCancel: _cancel),
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
              onBack: isEditing ? _cancel : widget.onBack,
              trailing: isEditing
                  ? TextButton(onPressed: _save, child: const Text('Save'))
                  : KebabMenuButton<void>(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: _startEditing,
                          child: const Text('Edit Profile'),
                        ),
                        PopupMenuItem(
                          onTap: widget.onSettingsTap,
                          child: const Text('Settings'),
                        ),
                        PopupMenuItem(
                          onTap: widget.onLogOut,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _ProfileHeaderBlock(profile: profile),
        const SizedBox(height: AppSpacing.xl),
        _SectionCard(
          title: 'Contact Information',
          children: [
            _InfoRow(
              icon: AppIcons.email,
              label: 'EMAIL',
              value: profile.email,
            ),
            _InfoRow(
              icon: AppIcons.phone,
              label: 'PHONE',
              value: profile.phone,
            ),
            _InfoRow(
              icon: AppIcons.systemAdministrator,
              label: 'DEPARTMENT',
              value: profile.department,
            ),
            _InfoRow(
              icon: AppIcons.team,
              label: 'REPORTS TO',
              value: profile.reportsTo,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionCard(
          title: 'Security',
          children: [
            _ActionRow(
              icon: AppIcons.password,
              label: 'Change Password',
              caption: profile.passwordLastUpdatedLabel,
              onTap: onChangePassword,
            ),
            _ActionRow(
              icon: AppIcons.verify,
              label: 'Two-Factor Authentication',
              caption: profile.twoFactorEnabled ? 'Enabled' : 'Disabled',
              // No 2FA management workflow is specified yet — placeholder
              // pending spec.
              onTap: () {},
            ),
            _ActionRow(
              icon: AppIcons.idCard,
              label: 'Login Sessions',
              caption: '${profile.activeSessionCount} active devices',
              // No session-management workflow is specified yet —
              // placeholder pending spec.
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHeaderBlock extends StatelessWidget {
  const _ProfileHeaderBlock({required this.profile, this.editing = false});

  final OfficerProfile profile;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _ProfileAvatar(name: profile.name, editing: editing),
        const SizedBox(height: AppSpacing.md),
        Text(profile.name, style: textTheme.headlineSmall),
        const SizedBox(height: 2),
        Text(profile.role, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            if (profile.verifiedOfficial)
              const _Pill(
                icon: AppIcons.verify,
                label: 'Verified Official',
                color: AppColors.primary,
              ),
            _Pill(label: 'ID #${profile.employeeId}'),
          ],
        ),
      ],
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name, required this.editing});

  final String name;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .map((p) => p.isEmpty ? '' : p[0])
        .take(2)
        .join()
        .toUpperCase();
    return Stack(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initials,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
          ),
        ),
        if (editing)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary,
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: const Icon(
                AppIcons.camera,
                size: AppIconSize.sm,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({this.icon, required this.label, this.color});

  final IconData? icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = color ?? colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.12) ?? colorScheme.surfaceContainer,
        border: color != null
            ? Border.all(color: color!.withValues(alpha: 0.24))
            : null,
        borderRadius: AppRadius.allXl,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.sm, color: effectiveColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: effectiveColor,
              fontWeight: AppFontWeight.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppIconSize.md, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(letterSpacing: 0.96),
                ),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.caption,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppIconSize.md,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.bodyMedium),
                  Text(caption, style: textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: AppIconSize.sm,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editing mode — Editing / Error share this
// ---------------------------------------------------------------------------

/// Email and Phone render locked (`enabled: false`, same treatment
/// Department already gets) — an admin-provisioned account's contact
/// credentials are set by whoever provisioned it, not self-editable.
/// Changing either means a real identity change (a different sign-in
/// email, a different verified number), so it goes through an
/// administrator instead of a self-service field. Full Name is the only
/// field a Municipal Officer can change here.
class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.profile,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.fieldErrors,
  });

  final OfficerProfile profile;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final Map<String, String> fieldErrors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _ProfileHeaderBlock(profile: profile, editing: true),
        const SizedBox(height: AppSpacing.xl),
        GlassCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Information', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Full Name',
                required: true,
                icon: AppIcons.profile,
                controller: nameController,
                errorText: fieldErrors['name'],
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Email Address',
                required: false,
                icon: AppIcons.email,
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: false,
                caption: 'Contact your administrator to change this',
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Phone Number',
                required: false,
                icon: AppIcons.phone,
                controller: phoneController,
                keyboardType: TextInputType.phone,
                enabled: false,
                caption: 'Contact your administrator to change this',
              ),
              const SizedBox(height: AppSpacing.md),
              _FormField(
                label: 'Department',
                required: false,
                icon: AppIcons.permissionDenied,
                controller: TextEditingController(text: profile.department),
                enabled: false,
                caption: 'Set by your administrator',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.required,
    required this.icon,
    required this.controller,
    this.enabled = true,
    this.keyboardType,
    this.errorText,
    this.caption,
  });

  final String label;
  final bool required;
  final IconData icon;
  final TextEditingController controller;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? errorText;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: textTheme.titleSmall),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: textTheme.titleSmall?.copyWith(color: AppColors.error),
              ),
              const Spacer(),
              Text(
                'Required',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: AppIconSize.md),
            errorText: errorText,
          ),
        ),
        if (caption != null) ...[
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

class _EditActionBar extends StatelessWidget {
  const _EditActionBar({required this.onSave, required this.onCancel});

  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final semantic = Theme.of(context).extension<AppSemanticColors>()!;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: semantic.glassBorder)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              child: const Text('Save Changes'),
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
