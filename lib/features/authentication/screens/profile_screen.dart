import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';

/// Approved states for AUTH-006 Profile Screen.
enum ProfileViewState {
  ready,
  loading,
  validationError,
  offline,
  permissionRequired,
  editing,
  disabled,
  success,
  error,
  empty,
}

/// Callback used when the user saves edited profile information.
typedef ProfileSaveCallback =
    void Function(String fullName, String emailAddress, String phoneNumber);

/// AUTH-006 — CivicVoice Profile Screen.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.state = ProfileViewState.ready,
    this.fullName = 'Kingsben Amoako',
    this.emailAddress = 'kingsben@example.com',
    this.phoneNumber = '+233 XX XXX XXXX',
    this.onEditProfile,
    this.onSaveProfile,
    this.onCompleteProfile,
    this.onLogout,
  });

  final ProfileViewState state;

  final String fullName;
  final String emailAddress;
  final String phoneNumber;

  final VoidCallback? onEditProfile;
  final ProfileSaveCallback? onSaveProfile;
  final VoidCallback? onCompleteProfile;
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool get _isEditing =>
      widget.state == ProfileViewState.editing ||
      widget.state == ProfileViewState.validationError;

  bool get _isLoading => widget.state == ProfileViewState.loading;

  bool get _isEmpty => widget.state == ProfileViewState.empty;

  bool get _editingDisabled =>
      widget.state == ProfileViewState.loading ||
      widget.state == ProfileViewState.offline ||
      widget.state == ProfileViewState.permissionRequired ||
      widget.state == ProfileViewState.disabled;

  bool get _showStatusPanel =>
      widget.state == ProfileViewState.loading ||
      widget.state == ProfileViewState.validationError ||
      widget.state == ProfileViewState.offline ||
      widget.state == ProfileViewState.permissionRequired ||
      widget.state == ProfileViewState.success ||
      widget.state == ProfileViewState.error;

  bool get _showValidationErrors =>
      widget.state == ProfileViewState.validationError;

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController(text: widget.fullName);

    _emailController = TextEditingController(text: widget.emailAddress);

    _phoneController = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_isEditing) {
      if (oldWidget.fullName != widget.fullName) {
        _fullNameController.text = widget.fullName;
      }

      if (oldWidget.emailAddress != widget.emailAddress) {
        _emailController.text = widget.emailAddress;
      }

      if (oldWidget.phoneNumber != widget.phoneNumber) {
        _phoneController.text = widget.phoneNumber;
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!formIsValid) {
      return;
    }

    widget.onSaveProfile?.call(
      _fullNameController.text.trim(),
      _emailController.text.trim(),
      _phoneController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppBreakpoints.standardMobile,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),

                      _ProfileHeader(
                        fullName: widget.fullName,
                        emailAddress: widget.emailAddress,
                        showEditBadge: _isEditing,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      if (_showStatusPanel) ...[
                        _ProfileStatusPanel(state: widget.state),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      if (_isEmpty)
                        _EmptyProfileCard(
                          onCompleteProfile:
                              widget.onCompleteProfile ?? widget.onEditProfile,
                        )
                      else if (_isEditing)
                        Form(
                          key: _formKey,
                          child: _ProfileEditForm(
                            fullNameController: _fullNameController,
                            emailController: _emailController,
                            phoneController: _phoneController,
                            showValidationErrors: _showValidationErrors,
                          ),
                        )
                      else
                        _ProfileInformationCard(
                          fullName: widget.fullName,
                          emailAddress: widget.emailAddress,
                          phoneNumber: widget.phoneNumber,
                        ),

                      const SizedBox(height: AppSpacing.md),

                      SizedBox(
                        width: double.infinity,
                        child: _buildPrimaryButton(),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onLogout,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          icon: const Icon(
                            AppIcons.logOut,
                            size: AppIconSize.md,
                          ),
                          label: const Text('Log Out'),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      Text(
                        'You can only edit your own profile.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      Text(
                        'VERSION 1.0',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall,
                      ),

                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    if (_isLoading) {
      return const FilledButton(
        onPressed: null,
        child: SizedBox(
          width: AppIconSize.md,
          height: AppIconSize.md,
          child: CircularProgressIndicator(strokeWidth: AppSpacing.xs / 2),
        ),
      );
    }

    if (_isEditing) {
      return FilledButton.icon(
        onPressed: _saveProfile,
        icon: const Icon(AppIcons.edit, size: AppIconSize.md),
        label: const Text('Save Changes'),
      );
    }

    if (_isEmpty) {
      return FilledButton.icon(
        onPressed: widget.onCompleteProfile ?? widget.onEditProfile,
        icon: const Icon(AppIcons.edit, size: AppIconSize.md),
        label: const Text('Complete Profile'),
      );
    }

    return FilledButton.icon(
      onPressed: _editingDisabled ? null : widget.onEditProfile,
      icon: const Icon(AppIcons.edit, size: AppIconSize.md),
      label: const Text('Edit Profile'),
    );
  }
}

/// Profile image, user name, email address and role badge.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.emailAddress,
    required this.showEditBadge,
  });

  final String fullName;
  final String emailAddress;
  final bool showEditBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final semanticColors =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: AppSpacing.xxxxl,
              height: AppSpacing.xxxxl,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondaryContainer,
              ),
              child: Icon(
                AppIcons.profile,
                size: AppIconSize.lg,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),

            if (showEditBadge)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: Icon(
                    AppIcons.edit,
                    size: AppIconSize.sm,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        Text(
          fullName,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: AppFontWeight.bold,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        Text(
          emailAddress,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),

        const SizedBox(height: AppSpacing.sm),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: semanticColors.success.withValues(alpha: 0.12),
            borderRadius: AppRadius.allXl,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.badgeVerified,
                size: AppIconSize.sm,
                color: semanticColors.success,
              ),

              const SizedBox(width: AppSpacing.xs),

              Text(
                'CITIZEN',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: semanticColors.success,
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays the saved profile information.
class _ProfileInformationCard extends StatelessWidget {
  const _ProfileInformationCard({
    required this.fullName,
    required this.emailAddress,
    required this.phoneNumber,
  });

  final String fullName;
  final String emailAddress;
  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        children: [
          _ProfileInformationRow(
            icon: AppIcons.profile,
            label: 'FULL NAME',
            value: fullName,
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          _ProfileInformationRow(
            icon: AppIcons.email,
            label: 'EMAIL ADDRESS',
            value: emailAddress,
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),

          _ProfileInformationRow(
            icon: AppIcons.phone,
            label: 'PHONE NUMBER',
            value: phoneNumber,
          ),
        ],
      ),
    );
  }
}

class _ProfileInformationRow extends StatelessWidget {
  const _ProfileInformationRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: AppRadius.allXs,
          ),
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: theme.colorScheme.primary,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),

              const SizedBox(height: AppSpacing.xs),

              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: AppFontWeight.semiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Editable profile fields.
class _ProfileEditForm extends StatelessWidget {
  const _ProfileEditForm({
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.showValidationErrors,
  });

  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final bool showValidationErrors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileFieldLabel(text: 'Full Name'),

        const SizedBox(height: AppSpacing.sm),

        TextFormField(
          controller: fullNameController,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          decoration: InputDecoration(
            hintText: 'Enter your full name',
            prefixIcon: const Icon(AppIcons.profile),
            errorText: showValidationErrors ? 'This field is required.' : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name.';
            }

            return null;
          },
        ),

        const SizedBox(height: AppSpacing.md),

        const _ProfileFieldLabel(text: 'Email Address'),

        const SizedBox(height: AppSpacing.sm),

        TextFormField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'Enter your email address',
            prefixIcon: Icon(AppIcons.email),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email address.';
            }

            final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

            if (!emailPattern.hasMatch(value.trim())) {
              return 'Please enter a valid email address.';
            }

            return null;
          },
        ),

        const SizedBox(height: AppSpacing.md),

        const _ProfileFieldLabel(text: 'Phone Number'),

        const SizedBox(height: AppSpacing.sm),

        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumber],
          decoration: InputDecoration(
            hintText: 'Enter your phone number',
            prefixIcon: const Icon(AppIcons.phone),
            errorText: showValidationErrors ? 'This field is required.' : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number.';
            }

            return null;
          },
        ),
      ],
    );
  }
}

class _ProfileFieldLabel extends StatelessWidget {
  const _ProfileFieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelMedium);
  }
}

/// Empty profile message.
class _EmptyProfileCard extends StatelessWidget {
  const _EmptyProfileCard({required this.onCompleteProfile});

  final VoidCallback? onCompleteProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: AppComponentRadius.card,
      ),
      child: Column(
        children: [
          Icon(
            AppIcons.empty,
            size: AppIconSize.xl,
            color: theme.colorScheme.primary,
          ),

          const SizedBox(height: AppSpacing.md),

          Text(
            'No Profile Information',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: AppFontWeight.bold,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'Your profile information is not available yet. '
            'Complete your profile to continue using CivicVoice.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),

          const SizedBox(height: AppSpacing.md),

          FilledButton(
            onPressed: onCompleteProfile,
            child: const Text('Complete Profile'),
          ),
        ],
      ),
    );
  }
}

/// Status message for loading, validation, offline, permission, success or error.
class _ProfileStatusPanel extends StatelessWidget {
  const _ProfileStatusPanel({required this.state});

  final ProfileViewState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final semanticColors =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    late final String title;
    late final String message;
    late final IconData icon;
    late final Color statusColor;

    bool showLoadingIndicator = false;

    if (state == ProfileViewState.loading) {
      title = 'Loading Profile';
      message = 'Fetching the latest profile information.';
      icon = AppIcons.refresh;
      statusColor = semanticColors.info;
      showLoadingIndicator = true;
    } else if (state == ProfileViewState.validationError) {
      title = 'Validation Error';
      message = 'Review highlighted fields before saving.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    } else if (state == ProfileViewState.offline) {
      title = 'You are Offline';
      message = 'Reconnect before updating your profile.';
      icon = AppIcons.offline;
      statusColor = semanticColors.warning;
    } else if (state == ProfileViewState.permissionRequired) {
      title = 'Permission Required';
      message = 'You can only edit your own profile.';
      icon = AppIcons.permissionDenied;
      statusColor = semanticColors.warning;
    } else if (state == ProfileViewState.success) {
      title = 'Profile Updated';
      message = 'Your profile changes were saved successfully.';
      icon = AppIcons.success;
      statusColor = semanticColors.success;
    } else {
      title = 'Profile Error';
      message = 'Something went wrong. Please try again.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    }

    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: AppComponentRadius.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLoadingIndicator)
              SizedBox(
                width: AppIconSize.standard,
                height: AppIconSize.standard,
                child: CircularProgressIndicator(
                  strokeWidth: AppSpacing.xs / 2,
                  color: statusColor,
                ),
              )
            else
              Icon(icon, size: AppIconSize.standard, color: statusColor),

            const SizedBox(width: AppSpacing.sm),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: AppFontWeight.semiBold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
