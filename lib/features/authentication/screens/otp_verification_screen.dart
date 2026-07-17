import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:civic_voice/core/theme/app_theme.dart';
import 'package:civic_voice/features/authentication/widgets/auth_presentation.dart';

enum OtpPurpose { registration, forgotPassword, changePassword }

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.purpose,
    required this.onVerify,
    this.onResend,
    this.onBack,
    this.codeExpiryDuration = _defaultCodeExpiry,
    this.resendCooldownDuration = _defaultResendCooldown,
  });

  static const _defaultCodeExpiry = Duration(minutes: 15);
  static const _defaultResendCooldown = Duration(minutes: 2);

  final String phoneNumber;
  final OtpPurpose purpose;
  final VoidCallback onVerify;
  final VoidCallback? onResend;
  final VoidCallback? onBack;
  final Duration codeExpiryDuration;
  final Duration resendCooldownDuration;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  late Duration _timeToExpiry = widget.codeExpiryDuration;
  late Duration _resendCooldown = widget.resendCooldownDuration;
  bool _verifying = false;
  bool _resent = false;

  bool get _expired => _timeToExpiry.inSeconds <= 0;
  bool get _canResend => _resendCooldown.inSeconds <= 0;
  bool get _canVerify =>
      !_expired && !_verifying && _codeController.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {
      if (_timeToExpiry.inSeconds > 0) {
        _timeToExpiry -= const Duration(seconds: 1);
      }
      if (_resendCooldown.inSeconds > 0) {
        _resendCooldown -= const Duration(seconds: 1);
      }
    });
  }

  void _resend() {
    if (!_canResend) return;
    // TODO(auth): request a new OTP via WittiFlow/backend once it exists.
    widget.onResend?.call();
    setState(() {
      _resent = true;
      _codeController.clear();
      _timeToExpiry = widget.codeExpiryDuration;
      _resendCooldown = widget.resendCooldownDuration;
    });
  }

  Future<void> _verify() async {
    if (!_canVerify) return;
    setState(() => _verifying = true);
    // TODO(auth): verify OTP against WittiFlow/backend once it exists.
    await Future<void>.delayed(AppMotionDuration.moderate);
    if (!mounted) return;
    setState(() => _verifying = false);
    widget.onVerify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    return Scaffold(
      body: AuthScreenLayout(
        onBack: widget.onBack,
        title: _title,
        supportingText: 'We sent a code to ${widget.phoneNumber}.',
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verification Code', style: theme.textTheme.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _codeController,
              enabled: !_verifying && !_expired,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: AppSpacing.xs,
                fontWeight: AppFontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => _verify(),
              decoration: authInputDecoration(
                context,
                hintText: '000000',
                prefixIcon: AppIcons.sms,
              ).copyWith(counterText: ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TimerLine(
              icon: AppIcons.eta,
              text: _expired
                  ? 'Code expired'
                  : 'Code expires in ${_formatDuration(_timeToExpiry)}',
              color: _expired ? semantic.error : semantic.info,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_expired)
              AuthStatusAlert(
                title: 'Code Expired',
                message: 'Request a new code before verifying.',
                icon: AppIcons.warning,
                statusColor: semantic.warning,
              )
            else if (_resent)
              AuthStatusAlert(
                title: 'Code Resent',
                message: 'Check your messages for the latest code.',
                icon: AppIcons.success,
                statusColor: semantic.success,
              ),
            if (_expired || _resent) const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canVerify ? _verify : null,
                child: _verifying
                    ? const SizedBox(
                        width: AppIconSize.md,
                        height: AppIconSize.md,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSpacing.xs / 2,
                        ),
                      )
                    : const Text('Verify Code'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: _canResend ? _resend : null,
                child: Text(
                  _canResend
                      ? 'Resend Code'
                      : 'Resend code in ${_formatDuration(_resendCooldown)}',
                ),
              ),
            ),
          ],
        ),
        footer: Text(
          'Codes expire after 15 minutes.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (widget.purpose) {
      OtpPurpose.registration => 'Verify Your Phone',
      OtpPurpose.forgotPassword => 'Verify Reset Code',
      OtpPurpose.changePassword => 'Verify Security Code',
    };
  }
}

class _TimerLine extends StatelessWidget {
  const _TimerLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppIconSize.sm, color: color),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final minutes = safeDuration.inMinutes;
  final seconds = safeDuration.inSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
