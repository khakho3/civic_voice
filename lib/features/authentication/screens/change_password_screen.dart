import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

/// Outcome of a submit attempt — kept separate from the form's own inline
/// validators (required/length/match, checked client-side on submit) the
/// same way every other screen's save-state enum stays out of its own
/// load-state enum. No "current password incorrect" value: there's no
/// real credential store to check the typed current password against
/// yet, so a value like that would have no reachable trigger — same call
/// already made for [SystemSettingsSaveState] dropping `validationError`
/// once its only source, Platform Name, was removed.
enum ChangePasswordSubmitState { idle, saving, success }

/// Shared "Change Password" destination for every already-authenticated
/// role (Admin, Ministry, Municipal, and — as the rest of the app catches
/// up — Maintenance/Citizen). One implementation reached from each
/// module's own Profile screen via [AppRoutes.changePassword] rather than
/// a per-module reimplementation, so the flow reads identically no matter
/// which profile screen linked here.
///
/// Visually shares [AuthScreenLayout]/`authInputDecoration` with the
/// public Forgot Password screen (AUTH-005) — both are "prove who you
/// are, then touch a credential" flows, just from opposite sides of a
/// session boundary, so the same chrome fits without inventing a second
/// visual language for account-security forms.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hideCurrentPassword = true;
  bool _hideNewPassword = true;
  bool _hideConfirmPassword = true;
  ChangePasswordSubmitState _submitState = ChangePasswordSubmitState.idle;

  bool get _isSaving => _submitState == ChangePasswordSubmitState.saving;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSaving) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _submitState = ChangePasswordSubmitState.saving);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _submitState = ChangePasswordSubmitState.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticColors =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    return Scaffold(
      body: AuthScreenLayout(
        onBack: widget.onBack,
        title: 'Change Password',
        supportingText:
            'Enter your current password and choose a new one to keep '
            'your account secure.',
        form: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Password', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _currentPasswordController,
                enabled: !_isSaving,
                obscureText: _hideCurrentPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.password],
                decoration: authInputDecoration(
                  context,
                  hintText: 'Enter your current password',
                  prefixIcon: AppIcons.password,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _hideCurrentPassword = !_hideCurrentPassword,
                    ),
                    tooltip: _hideCurrentPassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _hideCurrentPassword
                          ? AppIcons.visibilityOff
                          : AppIcons.visibilityOn,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('New Password', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _newPasswordController,
                enabled: !_isSaving,
                obscureText: _hideNewPassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                decoration: authInputDecoration(
                  context,
                  hintText: 'Enter your new password',
                  prefixIcon: AppIcons.password,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _hideNewPassword = !_hideNewPassword,
                    ),
                    tooltip: _hideNewPassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _hideNewPassword
                          ? AppIcons.visibilityOff
                          : AppIcons.visibilityOn,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password.';
                  }
                  if (value.length < 8) {
                    return 'Password must contain at least 8 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Confirm New Password', style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isSaving,
                obscureText: _hideConfirmPassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: authInputDecoration(
                  context,
                  hintText: 'Re-enter your new password',
                  prefixIcon: AppIcons.password,
                  suffixIcon: IconButton(
                    onPressed: () => setState(
                      () => _hideConfirmPassword = !_hideConfirmPassword,
                    ),
                    tooltip: _hideConfirmPassword
                        ? 'Show password'
                        : 'Hide password',
                    icon: Icon(
                      _hideConfirmPassword
                          ? AppIcons.visibilityOff
                          : AppIcons.visibilityOn,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: _isSaving
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: AppIconSize.md,
                              height: AppIconSize.md,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSpacing.xs / 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: AppSpacing.sm),
                            Text('Updating...'),
                          ],
                        )
                      : const Text('Update Password'),
                ),
              ),
              if (_submitState == ChangePasswordSubmitState.success) ...[
                const SizedBox(height: AppSpacing.md),
                AuthStatusAlert(
                  title: 'Password Updated',
                  message: 'Your password has been changed successfully.',
                  icon: AppIcons.success,
                  statusColor: semanticColors.success,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
