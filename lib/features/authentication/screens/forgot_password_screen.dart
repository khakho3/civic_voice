import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

/// Approved states for AUTH-005 Forgot Password Screen.
enum ForgotPasswordViewState {
  ready,
  disabled,
  phoneNotFound,
  passwordResetSuccess,
  recoveryError,
  loading,
  validationError,
  codeSent,
  offline,
}

/// AUTH-005 — CivicVoice Forgot Password Screen.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.state = ForgotPasswordViewState.ready,
    this.onBack,
    this.onSendCode,
    this.onBackToLogin,
  });

  final ForgotPasswordViewState state;
  final VoidCallback? onBack;
  final ValueChanged<String>? onSendCode;
  final VoidCallback? onBackToLogin;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool get _isLoading => widget.state == ForgotPasswordViewState.loading;

  bool get _isDisabled =>
      widget.state == ForgotPasswordViewState.disabled ||
      widget.state == ForgotPasswordViewState.offline ||
      widget.state == ForgotPasswordViewState.loading ||
      widget.state == ForgotPasswordViewState.passwordResetSuccess ||
      widget.state == ForgotPasswordViewState.codeSent;

  bool get _showPhoneNotFound =>
      widget.state == ForgotPasswordViewState.phoneNotFound;

  bool get _showValidationError =>
      widget.state == ForgotPasswordViewState.validationError;

  bool get _showStatusPanel =>
      widget.state == ForgotPasswordViewState.phoneNotFound ||
      widget.state == ForgotPasswordViewState.passwordResetSuccess ||
      widget.state == ForgotPasswordViewState.recoveryError ||
      widget.state == ForgotPasswordViewState.loading ||
      widget.state == ForgotPasswordViewState.validationError ||
      widget.state == ForgotPasswordViewState.codeSent ||
      widget.state == ForgotPasswordViewState.offline;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isDisabled) {
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;

    if (isValid) {
      widget.onSendCode?.call(_phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AuthScreenLayout(
      onBack: widget.onBack,
      title: 'Forgot Password',
      supportingText:
          'Enter your phone number and we will send a verification code.',
      useRecoveryGlass: true,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone Number', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _phoneController,
              enabled: !_isDisabled,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              onFieldSubmitted: (_) => _submitForm(),
              decoration: authInputDecoration(
                context,
                hintText: 'Enter your phone number',
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
                          Text('Send Code'),
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
    );
  }

  String? get _phoneErrorText {
    if (_showPhoneNotFound) {
      return 'No account matches this phone number.';
    }

    if (_showValidationError) {
      return 'Enter a phone number to continue.';
    }

    return null;
  }
}

/// Status panel displayed below the Send Code button.
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

    if (state == ForgotPasswordViewState.phoneNotFound) {
      title = 'Phone Not Found';
      message = 'No account matches this phone number.';
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
      title = 'Sending Code';
      message = 'Please wait while we send your verification code.';
      icon = AppIcons.info;
      statusColor = semanticColors.info;
    } else if (state == ForgotPasswordViewState.validationError) {
      title = 'Validation Error';
      message = 'Enter a phone number to continue.';
      icon = AppIcons.error;
      statusColor = semanticColors.error;
    } else if (state == ForgotPasswordViewState.codeSent) {
      title = 'Code Sent';
      message = 'Check your messages for a verification code.';
      icon = AppIcons.success;
      statusColor = semanticColors.success;
    } else if (state == ForgotPasswordViewState.offline) {
      title = 'You are Offline';
      message = 'Reconnect before requesting a code.';
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
