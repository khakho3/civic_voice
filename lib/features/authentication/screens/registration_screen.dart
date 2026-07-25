import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

/// Approved states for AUTH-004 Registration Screen.
enum RegistrationViewState {
  ready,
  disabled,
  phoneAlreadyRegistered,
  passwordMismatch,
  offline,
  loading,
  validationError,
  weakPassword,
  success,
  error,
}

/// AUTH-004 — CivicVoice Citizen Registration Screen.
class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    this.state = RegistrationViewState.ready,
    this.onBack,
    this.onCreateAccount,
    this.onLogin,
  });

  final RegistrationViewState state;
  final VoidCallback? onBack;
  final void Function(String fullName, String phone, String password)?
  onCreateAccount;
  final VoidCallback? onLogin;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _acceptedPolicy = false;

  bool get _isLoading => widget.state == RegistrationViewState.loading;

  bool get _isDisabled =>
      widget.state == RegistrationViewState.disabled ||
      widget.state == RegistrationViewState.offline ||
      _isLoading;

  bool get _showValidationErrors =>
      widget.state == RegistrationViewState.validationError;

  bool get _showPhoneError =>
      widget.state == RegistrationViewState.phoneAlreadyRegistered;

  bool get _showPasswordMismatch =>
      widget.state == RegistrationViewState.passwordMismatch;

  bool get _showWeakPassword =>
      widget.state == RegistrationViewState.weakPassword;

  bool get _showStatusPanel =>
      widget.state == RegistrationViewState.phoneAlreadyRegistered ||
      widget.state == RegistrationViewState.passwordMismatch ||
      widget.state == RegistrationViewState.offline ||
      widget.state == RegistrationViewState.weakPassword ||
      widget.state == RegistrationViewState.success ||
      widget.state == RegistrationViewState.error;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isDisabled) {
      return;
    }

    final formIsValid = _formKey.currentState?.validate() ?? false;

    if (!_acceptedPolicy) {
      setState(() {});
      return;
    }

    if (formIsValid) {
      widget.onCreateAccount?.call(
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text,
      );
    }
  }

  Future<void> _showPrivacyPolicy() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        // Opaque, not the theme's glass default — this is a long,
        // multi-paragraph scrollable policy, exactly the "long-form
        // content" §19.10 prohibits glass on.
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Privacy & Data Use'),
        content: const SingleChildScrollView(
          child: Text(
            'Civic Voice uses your phone number to secure your account and may use your location, photos, and report details to route and investigate civic issues.\n\n'
            'The app may temporarily cache report drafts, photos, permission choices, and guest submissions on this device so your work is not lost. Guest reports made on this phone will be linked to your account when you register.\n\n'
            'Your information is protected and is used only to operate Civic Voice and handle submitted reports. We do not sell your information or share it with unrelated organizations. Authorized civic teams may access the report information required to investigate and resolve an issue.\n\n'
            'You can review or change location, camera, photo, and notification permissions at any time in your device settings.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScreenLayout(
      onBack: widget.onBack,
      title: 'Create Account',
      supportingText:
          'Create your Citizen account to report and track civic issues.',
      showIllustrationHero: true,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel(text: 'Full Name'),

            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _fullNameController,
              enabled: !_isDisabled,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: authInputDecoration(
                context,
                hintText: 'Genny Amadapah',
                prefixIcon: AppIcons.profile,
                errorText: _showValidationErrors
                    ? 'Full name is required.'
                    : null,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name.';
                }

                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            const _FieldLabel(text: 'Phone Number'),

            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _phoneController,
              enabled: !_isDisabled,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: authInputDecoration(
                context,
                hintText: '024 000 0000',
                prefixIcon: AppIcons.phone,
                errorText: _phoneErrorText,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your phone number.';
                }

                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            const _FieldLabel(text: 'Password'),

            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _passwordController,
              enabled: !_isDisabled,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              decoration: authInputDecoration(
                context,
                hintText: 'Enter your password',
                prefixIcon: AppIcons.password,
                errorText: _passwordErrorText,
                suffixIcon: IconButton(
                  onPressed: _isDisabled
                      ? null
                      : () {
                          setState(() {
                            _hidePassword = !_hidePassword;
                          });
                        },
                  tooltip: _hidePassword ? 'Show password' : 'Hide password',
                  icon: Icon(
                    _hidePassword
                        ? AppIcons.visibilityOn
                        : AppIcons.visibilityOff,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password.';
                }

                if (value.length < 8) {
                  return 'Password must contain at least 8 characters.';
                }

                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            const _FieldLabel(text: 'Confirm Password'),

            const SizedBox(height: AppSpacing.sm),

            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isDisabled,
              obscureText: _hideConfirmPassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onFieldSubmitted: (_) => _submitForm(),
              decoration: authInputDecoration(
                context,
                hintText: 'Confirm your password',
                prefixIcon: AppIcons.password,
                errorText: _confirmPasswordErrorText,
                suffixIcon: IconButton(
                  onPressed: _isDisabled
                      ? null
                      : () {
                          setState(() {
                            _hideConfirmPassword = !_hideConfirmPassword;
                          });
                        },
                  tooltip: _hideConfirmPassword
                      ? 'Show password'
                      : 'Hide password',
                  icon: Icon(
                    _hideConfirmPassword
                        ? AppIcons.visibilityOn
                        : AppIcons.visibilityOff,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password.';
                }

                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }

                return null;
              },
            ),

            const SizedBox(height: AppSpacing.md),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: AppComponentRadius.card,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptedPolicy,
                    onChanged: _isDisabled
                        ? null
                        : (value) {
                            setState(() {
                              _acceptedPolicy = value ?? false;
                            });
                          },
                  ),

                  const SizedBox(width: AppSpacing.xs),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'I agree to the ',
                            style: theme.textTheme.bodySmall,
                          ),
                          TextButton(
                            onPressed: _isDisabled ? null : _showPrivacyPolicy,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Privacy & Data Use Policy'),
                          ),
                          Text('.', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (!_acceptedPolicy && _showValidationErrors) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You must accept the policy to continue.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isDisabled || !_acceptedPolicy ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        width: AppIconSize.md,
                        height: AppIconSize.md,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xs / 2,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),

            if (_showStatusPanel) ...[
              const SizedBox(height: AppSpacing.md),
              _RegistrationStatusPanel(state: widget.state),
            ],
          ],
        ),
      ),
      footer: Center(
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Already have an account?', style: theme.textTheme.bodySmall),
            TextButton(
              onPressed: _isDisabled ? null : widget.onLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  String? get _phoneErrorText {
    if (_showPhoneError) {
      return 'This phone number is already registered.';
    }

    if (_showValidationErrors) {
      return 'Phone number is required.';
    }

    return null;
  }

  String? get _passwordErrorText {
    if (_showWeakPassword) {
      return 'Password is too weak.';
    }

    if (_showValidationErrors) {
      return 'Password is required.';
    }

    return null;
  }

  String? get _confirmPasswordErrorText {
    if (_showPasswordMismatch) {
      return 'Passwords do not match.';
    }

    if (_showValidationErrors) {
      return 'Confirm your password.';
    }

    return null;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelMedium);
  }
}

/// Status panel displayed below the Create Account button.
class _RegistrationStatusPanel extends StatelessWidget {
  const _RegistrationStatusPanel({required this.state});

  final RegistrationViewState state;

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

    switch (state) {
      case RegistrationViewState.phoneAlreadyRegistered:
        title = 'Phone Already Registered';
        message =
            'Use another phone number or sign in to your existing account.';
        icon = AppIcons.error;
        statusColor = semanticColors.error;

      case RegistrationViewState.passwordMismatch:
        title = 'Passwords Do Not Match';
        message = 'Make sure both password fields contain the same password.';
        icon = AppIcons.error;
        statusColor = semanticColors.error;

      case RegistrationViewState.offline:
        title = 'You are Offline';
        message = 'Check your connection and try again.';
        icon = AppIcons.offline;
        statusColor = semanticColors.warning;

      case RegistrationViewState.weakPassword:
        title = 'Weak Password';
        message = 'Create a stronger password and try again.';
        icon = AppIcons.warning;
        statusColor = semanticColors.error;

      case RegistrationViewState.success:
        title = 'Account Created';
        message = 'Your Citizen account was created. Verify your phone next.';
        icon = AppIcons.success;
        statusColor = semanticColors.success;

      case RegistrationViewState.error:
        title = 'Registration Error';
        message = 'Something went wrong. Please try again.';
        icon = AppIcons.error;
        statusColor = semanticColors.error;

      default:
        title = '';
        message = '';
        icon = AppIcons.info;
        statusColor = semanticColors.info;
    }

    return AuthStatusAlert(
      title: title,
      message: message,
      icon: icon,
      statusColor: statusColor,
    );
  }
}
