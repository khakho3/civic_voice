import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';

enum SetNewPasswordPurpose { forgotPassword, changePassword, firstLogin }

class SetNewPasswordScreen extends StatelessWidget {
  const SetNewPasswordScreen({
    super.key,
    required this.purpose,
    required this.onSaved,
    this.onBack,
  });

  final SetNewPasswordPurpose purpose;
  final Future<bool> Function(String newPassword) onSaved;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScreenLayout(
      onBack: purpose == SetNewPasswordPurpose.firstLogin ? null : onBack,
      title: _title,
      supportingText: _supportingText,
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (purpose == SetNewPasswordPurpose.firstLogin) ...[
            AuthStatusAlert(
              title: 'Temporary Password Used',
              message:
                  'You must set a new password before continuing to your dashboard.',
              icon: AppIcons.warning,
              statusColor:
                  theme.extension<AppSemanticColors>()?.warning ??
                  AppColors.warning,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          SetNewPasswordForm(submitLabel: _buttonLabel, onSaved: onSaved),
        ],
      ),
      footer: Text(
        purpose == SetNewPasswordPurpose.firstLogin
            ? 'This step cannot be skipped.'
            : 'Use at least 8 characters.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  String get _title {
    return switch (purpose) {
      SetNewPasswordPurpose.forgotPassword => 'Set New Password',
      SetNewPasswordPurpose.changePassword => 'Change Password',
      SetNewPasswordPurpose.firstLogin => 'Create Your Password',
    };
  }

  String get _supportingText {
    return switch (purpose) {
      SetNewPasswordPurpose.forgotPassword =>
        'Choose a new password for your account.',
      SetNewPasswordPurpose.changePassword =>
        'Choose a new password for future sign-ins.',
      SetNewPasswordPurpose.firstLogin =>
        'You are signing in with a temporary password. Set a new one to continue.',
    };
  }

  String get _buttonLabel {
    return switch (purpose) {
      SetNewPasswordPurpose.forgotPassword => 'Save New Password',
      SetNewPasswordPurpose.changePassword => 'Save Password',
      SetNewPasswordPurpose.firstLogin => 'Continue',
    };
  }
}
