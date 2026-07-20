import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';
import 'package:civic_voice/services/api_client.dart';

enum _ChangePasswordStep { phone, otp, password }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.onSaved, this.onBack});

  /// Fires after the password has changed so the app can end the session.
  final Future<void> Function() onSaved;
  final VoidCallback? onBack;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  _ChangePasswordStep _step = _ChangePasswordStep.phone;
  String _phone = '';
  String? _resetToken;
  String? _phoneError;
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _sending = true;
      _phoneError = null;
    });
    final phone = _phoneController.text.trim();
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) {
        throw const ApiException(
          statusCode: 401,
          message: 'Your session has expired. Please sign in again.',
        );
      }
      await ApiClient.instance.sendAuthenticatedPasswordChangeOtp(
        idToken: idToken,
        phone: phone,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _phoneError = error.message;
      });
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _phoneError =
            'Could not send the code. Check your connection and try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _phone = phone;
      _sending = false;
      _step = _ChangePasswordStep.otp;
    });
  }

  Future<bool> _verifyCode(String code) async {
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken == null) return false;
      final token = await ApiClient.instance
          .verifyAuthenticatedPasswordChangeOtp(idToken: idToken, otp: code);
      if (!mounted) return false;
      setState(() {
        _resetToken = token;
        _step = _ChangePasswordStep.password;
      });
      return true;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _savePassword(String newPassword) async {
    final token = _resetToken;
    if (token == null) return false;
    try {
      await ApiClient.instance.resetPassword(
        phone: _phone,
        resetToken: token,
        newPassword: newPassword,
      );
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
    await widget.onSaved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _ChangePasswordStep.otp) {
      return OtpVerificationScreen(
        phoneNumber: _phone,
        purpose: OtpPurpose.changePassword,
        onBack: () => setState(() => _step = _ChangePasswordStep.phone),
        onResend: () async {
          final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
          if (idToken == null) return;
          await ApiClient.instance.sendAuthenticatedPasswordChangeOtp(
            idToken: idToken,
            phone: _phone,
          );
        },
        onVerify: _verifyCode,
      );
    }
    if (_step == _ChangePasswordStep.password) {
      return AuthScreenLayout(
        onBack: () => setState(() => _step = _ChangePasswordStep.otp),
        title: 'Change Password',
        supportingText: 'Choose a new password for future sign-ins.',
        form: SetNewPasswordForm(
          submitLabel: 'Save Password',
          onSaved: _savePassword,
        ),
        footer: Text(
          'You will be signed out after your password is changed.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return AuthScreenLayout(
      onBack: widget.onBack,
      title: 'Change Password',
      supportingText:
          'Enter your account phone number and we will send a verification code.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phone Number',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _phoneController,
              enabled: !_sending,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              onFieldSubmitted: (_) => _sendCode(),
              decoration: authInputDecoration(
                context,
                hintText: 'Enter your phone number',
                prefixIcon: AppIcons.phone,
                errorText: _phoneError,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Please enter your phone number.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sending ? null : _sendCode,
                child: Text(_sending ? 'Sending...' : 'Send Code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
