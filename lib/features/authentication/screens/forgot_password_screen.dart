import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

/// Approved states for AUTH-005 Forgot Password Screen.
enum ForgotPasswordViewState {
  ready,
  disabled,
  emailNotFound,
  passwordResetSuccess,
  recoveryError,
  loading,
  validationError,
  resetLinkSent,
  offline,
}

/// AUTH-005 — CivicVoice Forgot Password Screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.state = ForgotPasswordViewState.ready,
    this.onBack,
    this.onSendResetLink,
    this.onBackToLogin,
  });

  final ForgotPasswordViewState state;
  final VoidCallback? onBack;
  final ValueChanged<String>? onSendResetLink;
  final VoidCallback? onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool get _isLoading => widget.state == ForgotPasswordViewState.loading;

  bool get _isDisabled =>
      widget.state == ForgotPasswordViewState.disabled ||
      widget.state == ForgotPasswordViewState.offline ||
      widget.state == ForgotPasswordViewState.loading ||
      widget.state == ForgotPasswordViewState.passwordResetSuccess ||
      widget.state == ForgotPasswordViewState.resetLinkSent;

  bool get _showEmailNotFound =>
      widget.state == ForgotPasswordViewState.emailNotFound;

  bool get _showValidationError =>
      widget.state == ForgotPasswordViewState.validationError;

  bool get _showStatusPanel =>
      widget.state == ForgotPasswordViewState.emailNotFound ||
      widget.state == ForgotPasswordViewState.passwordResetSuccess ||
      widget.state == ForgotPasswordViewState.recoveryError ||
      widget.state == ForgotPasswordViewState.loading ||
      widget.state == ForgotPasswordViewState.validationError ||
      widget.state == ForgotPasswordViewState.resetLinkSent ||
      widget.state == ForgotPasswordViewState.offline;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isDisabled) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (isValid) {
      widget.onSendResetLink?.call(_emailController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthScreenLayout(
        onBack: widget.onBack,
        title: 'Forgot Password',
        supportingText:
            'Enter your email address and we will send '
            'a secure password reset link.',
        form: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email Address', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _emailController,
                enabled: !_isDisabled,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.email],
                onFieldSubmitted: (_) => _submitForm(),
                decoration: authInputDecoration(
                  context,
                  hintText: 'e.g. name@example.com',
                  prefixIcon: AppIcons.email,
                  errorText: _emailErrorText,
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isDisabled ? null : _submitForm,
                  child: _isLoading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: AppIconSize.md,
                              height: AppIconSize.md,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSpacing.xs / 2,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Sending...'),
                          ],
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Send Reset Link'),
                            SizedBox(width: AppSpacing.sm),
                            Icon(AppIcons.chevronRight, size: AppIconSize.md),
                          ],
                        ),
                ),
              ),
              if (_showStatusPanel) ...[
                const SizedBox(height: AppSpacing.md),
                _ForgotPasswordStatusPanel(state: widget.state),
              ],
            ],
          ),
        ),
        footer: Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: widget.onBackToLogin,
            child: const Text('Back to Login'),
          ),
        ),
      ),
    );
  }

  String? get _emailErrorText {
    if (_showEmailNotFound) {
      return 'No account matches this email.';
    }

    if (_showValidationError) {
      return 'Enter a valid email address.';
    }

    return null;
  }
}

/// Status panel displayed below the Send Reset Link button.
class _ForgotPasswordStatusPanel extends StatelessWidget {
  const _ForgotPasswordStatusPanel({required this.state});

  final ForgotPasswordViewState state;

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

    if (state == ForgotPasswordViewState.emailNotFound) {
      title = 'Email Not Found';
      message = 'We could not find an account with this email.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    } else if (state == ForgotPasswordViewState.passwordResetSuccess) {
      title = 'Password Reset Success';
      message = 'Your password has been reset successfully.';
      icon = AppIcons.success;
      statusColor = semanticColors.success;
    } else if (state == ForgotPasswordViewState.recoveryError) {
      title = 'Recovery Error';
      message = 'Something went wrong. Please try again.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    } else if (state == ForgotPasswordViewState.loading) {
      title = 'Sending reset link';
      message = 'Please wait while we send your password reset email.';
      icon = AppIcons.info;
      statusColor = semanticColors.info;
    } else if (state == ForgotPasswordViewState.validationError) {
      title = 'Validation Error';
      message = 'Enter a valid email address to continue.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    } else if (state == ForgotPasswordViewState.resetLinkSent) {
      title = 'Reset Link Sent';
      message = 'Check your inbox for password reset instructions.';
      icon = AppIcons.success;
      statusColor = semanticColors.success;
    } else if (state == ForgotPasswordViewState.offline) {
      title = 'You are Offline';
      message = 'Reconnect before requesting a reset link.';
      icon = AppIcons.offline;
      statusColor = semanticColors.warning;
    } else {
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
