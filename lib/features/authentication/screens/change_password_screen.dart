import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.phoneNumber,
    required this.onSaved,
    this.onBack,
  });

  final String phoneNumber;
  final VoidCallback onSaved;
  final VoidCallback? onBack;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _verified = false;

  @override
  Widget build(BuildContext context) {
    if (!_verified) {
      // TODO(auth): send change-password OTP via WittiFlow/backend once it exists.
      return OtpVerificationScreen(
        phoneNumber: widget.phoneNumber,
        purpose: OtpPurpose.changePassword,
        onBack: widget.onBack,
        onVerify: () => setState(() => _verified = true),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: AuthScreenLayout(
        onBack: widget.onBack,
        title: 'Change Password',
        supportingText: 'Choose a new password for future sign-ins.',
        form: SetNewPasswordForm(
          submitLabel: 'Save Password',
          onSaved: widget.onSaved,
        ),
        footer: Text(
          'Your password will update after backend auth is connected.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
