import 'package:civic_voice/widgets/validation_attention.dart';
import 'package:flutter/material.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/screens/otp_verification_screen.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';
import 'package:civic_voice/features/authentication/widgets/set_new_password_form.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:civic_voice/services/auth_failure_message.dart';
import 'package:civic_voice/services/password_change_session.dart';

enum _ChangePasswordStep { phone, otp, password }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
    required this.onSaved,
    this.onBack,
    this.session,
  });

  /// Fires after the password has changed so the app can end the session.
  final Future<void> Function() onSaved;
  final VoidCallback? onBack;
  final PasswordChangeSession? session;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  _ChangePasswordStep _step = _ChangePasswordStep.phone;
  String _phone = '';
  DateTime? _otpExpiresAt;
  String? _resetToken;
  String? _phoneError;
  bool _sending = false;
  late final PasswordChangeSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session ?? PasswordChangeSession();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_sending || !(ValidationAttention.validate(_formKey))) return;
    setState(() {
      _sending = true;
      _phoneError = null;
    });
    final phone = _phoneController.text.trim();
    try {
      _otpExpiresAt = await _session.sendCode(phone);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _phoneError = authFailureMessage(
          error,
          fallback: 'Check your phone number and try again.',
        );
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
      final token = await _session.verifyCode(code);
      if (!mounted) return false;
      setState(() {
        _resetToken = token;
        _step = _ChangePasswordStep.password;
      });
      return true;
    } on ApiException catch (error) {
      if (error.statusCode == 400) return false;
      rethrow;
    }
  }

  Future<bool> _savePassword(String newPassword) async {
    final token = _resetToken;
    if (token == null) return false;
    final ownsCompletion = await _session.savePassword(
      phone: _phone,
      resetToken: token,
      newPassword: newPassword,
    );
    if (ownsCompletion && mounted && _session.isCurrent) await widget.onSaved();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _ChangePasswordStep.otp) {
      return OtpVerificationScreen(
        groupHeadingWithForm: true,
        phoneNumber: _phone,
        purpose: OtpPurpose.changePassword,
        expiresAt: _otpExpiresAt,
        onBack: () => setState(() => _step = _ChangePasswordStep.phone),
        onResend: () => _session.sendCode(_phone),
        onVerify: _verifyCode,
      );
    }
    if (_step == _ChangePasswordStep.password) {
      return AuthScreenLayout(
        groupHeadingWithForm: true,
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
      groupHeadingWithForm: true,
      onBack: widget.onBack,
      title: 'Change Password',
      supportingText:
          'Enter your account phone number and we will send a verification code.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFieldLabel('Phone Number'),
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
