import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

class SetNewPasswordForm extends StatefulWidget {
  const SetNewPasswordForm({
    super.key,
    required this.submitLabel,
    required this.onSaved,
    this.disabled = false,
  });

  final String submitLabel;
  final VoidCallback onSaved;
  final bool disabled;

  @override
  State<SetNewPasswordForm> createState() => _SetNewPasswordFormState();
}

class _SetNewPasswordFormState extends State<SetNewPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _saving = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.disabled || _saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    await Future<void>.delayed(AppMotionDuration.moderate);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = widget.disabled || _saving;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New Password', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _passwordController,
            enabled: !disabled,
            obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            decoration: authInputDecoration(
              context,
              hintText: 'Enter a new password',
              prefixIcon: AppIcons.password,
              suffixIcon: IconButton(
                onPressed: disabled
                    ? null
                    : () => setState(() => _hidePassword = !_hidePassword),
                tooltip: _hidePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _hidePassword
                      ? AppIcons.visibilityOn
                      : AppIcons.visibilityOff,
                ),
              ),
            ),
            validator: validateNewPassword,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Confirm New Password', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !disabled,
            obscureText: _hideConfirmPassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) => _submit(),
            decoration: authInputDecoration(
              context,
              hintText: 'Confirm your new password',
              prefixIcon: AppIcons.password,
              suffixIcon: IconButton(
                onPressed: disabled
                    ? null
                    : () => setState(
                        () => _hideConfirmPassword = !_hideConfirmPassword,
                      ),
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
            validator: (value) =>
                validateConfirmPassword(value, _passwordController.text),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: disabled ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: AppIconSize.md,
                      height: AppIconSize.md,
                      child: CircularProgressIndicator(
                        strokeWidth: AppSpacing.xs / 2,
                      ),
                    )
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a new password.';
  }
  if (value.length < 8) {
    return 'Password must contain at least 8 characters.';
  }
  return null;
}

String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your new password.';
  }
  if (value != password) {
    return 'Passwords do not match.';
  }
  return null;
}
