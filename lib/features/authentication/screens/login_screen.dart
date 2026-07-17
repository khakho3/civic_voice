import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

/// Approved states for AUTH-003 Login Screen.
enum LoginViewState {
  ready,
  disabled,
  sessionExpired,
  error,
  loading,
  invalidCredentials,
  offline,
}

/// AUTH-003 — CivicVoice Login Screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.state = LoginViewState.ready,
    this.onBack,
    this.onSignIn,
    this.onForgotPassword,
    this.onRegister,
  });

  final LoginViewState state;
  final VoidCallback? onBack;
  final VoidCallback? onSignIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onRegister;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  bool get _isLoading => widget.state == LoginViewState.loading;

  bool get _isDisabled =>
      widget.state == LoginViewState.disabled ||
      widget.state == LoginViewState.offline ||
      _isLoading;

  bool get _showFieldErrors =>
      widget.state == LoginViewState.invalidCredentials;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (isValid) {
      widget.onSignIn?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AuthScreenLayout(
        onBack: widget.onBack,
        title: 'Welcome Back',
        supportingText: 'Sign in to continue to CivicVoice.',
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
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                decoration: authInputDecoration(
                  context,
                  hintText: 'Enter your phone number',
                  prefixIcon: AppIcons.phone,
                  errorText: _showFieldErrors
                      ? 'Please check this field.'
                      : null,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your phone number.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Password', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _passwordController,
                enabled: !_isDisabled,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) {
                  if (!_isDisabled) {
                    _submitForm();
                  }
                },
                decoration: authInputDecoration(
                  context,
                  hintText: 'Enter your password',
                  prefixIcon: AppIcons.password,
                  errorText: _showFieldErrors
                      ? 'Please check this field.'
                      : null,
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
                    return 'Please enter your password.';
                  }

                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isDisabled ? null : widget.onForgotPassword,
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isDisabled ? null : _submitForm,
                  child: _isLoading
                      ? const SizedBox(
                          width: AppIconSize.md,
                          height: AppIconSize.md,
                          child: CircularProgressIndicator(
                            strokeWidth: AppSpacing.xs / 2,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              if (_shouldShowStatusPanel) ...[
                const SizedBox(height: AppSpacing.md),
                _LoginStatusPanel(state: widget.state),
              ],
            ],
          ),
        ),
        footer: Center(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text("Don't have an account?", style: theme.textTheme.bodySmall),
              TextButton(
                onPressed: _isDisabled ? null : widget.onRegister,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _shouldShowStatusPanel {
    return widget.state == LoginViewState.sessionExpired ||
        widget.state == LoginViewState.error ||
        widget.state == LoginViewState.invalidCredentials ||
        widget.state == LoginViewState.offline;
  }
}

/// Message panel shown below the Sign In button.
class _LoginStatusPanel extends StatelessWidget {
  const _LoginStatusPanel({required this.state});

  final LoginViewState state;

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
      case LoginViewState.sessionExpired:
        title = 'Session Expired';
        message = 'Please sign in again to continue.';
        icon = AppIcons.warning;
        statusColor = semanticColors.warning;

      case LoginViewState.error:
        title = 'Login Error';
        message = 'Something went wrong. Try again.';
        icon = AppIcons.error;
        statusColor = semanticColors.error;

      case LoginViewState.invalidCredentials:
        title = 'Authentication Error';
        message = 'Invalid phone number or password.';
        icon = AppIcons.error;
        statusColor = semanticColors.error;

      case LoginViewState.offline:
        title = 'You are Offline';
        message = 'Check your connection and try again.';
        icon = AppIcons.offline;
        statusColor = semanticColors.warning;

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
