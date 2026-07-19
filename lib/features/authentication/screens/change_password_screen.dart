import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';
import 'package:civic_voice/services/api_client.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.phoneNumber,
    required this.onSaved,
    this.onBack,
  });

  final String phoneNumber;
  /// Fires only after the password has actually been changed for real.
  final VoidCallback onSaved;
  final VoidCallback? onBack;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _verified = false;

  Future<bool> _handleSave(String newPassword) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return false;
    try {
      await ApiClient.instance.changePassword(
        idToken: idToken,
        newPassword: newPassword,
      );
    } on ApiException {
      return false;
    }
    widget.onSaved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_verified) {
      // TODO(auth): send change-password OTP via WittiFlow/backend once it exists.
      return OtpVerificationScreen(
        phoneNumber: widget.phoneNumber,
        purpose: OtpPurpose.changePassword,
        onBack: widget.onBack,
        onVerify: (_) async {
          setState(() => _verified = true);
          return true;
        },
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
          onSaved: _handleSave,
        ),
        footer: Text(
          'Use at least 8 characters.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
