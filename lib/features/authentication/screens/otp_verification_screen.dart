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
    required this.expiresAt,
    this.onResend,
    this.onBack,
    this.resendCooldownDuration = _defaultResendCooldown,
  });

  static const _defaultResendCooldown = Duration(minutes: 2);

  final String phoneNumber;
  final OtpPurpose purpose;
  final DateTime? expiresAt;

  /// Returns true on a correct code, false on a wrong/expired one — the
  /// screen shows an inline error for false rather than the caller
  /// silently proceeding.
  final Future<bool> Function(String code) onVerify;
  final Future<DateTime?> Function()? onResend;
  final VoidCallback? onBack;
  final Duration resendCooldownDuration;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeController = TextEditingController();
  Timer? _timer;
  late DateTime? _expiresAt = widget.expiresAt;
  late Duration? _timeToExpiry = _remainingUntil(_expiresAt);
  late Duration _resendCooldown = widget.resendCooldownDuration;
  bool _verifying = false;
  bool _resending = false;
  bool _resent = false;
  bool _invalidCode = false;
  String? _resendError;

  bool get _expired => _timeToExpiry != null && _timeToExpiry!.inSeconds <= 0;
  bool get _canResend =>
      widget.onResend != null && !_resending && _resendCooldown.inSeconds <= 0;
  bool get _canVerify =>
      !_expired && !_verifying && _codeController.text.trim().length == 4;

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
      _timeToExpiry = _remainingUntil(_expiresAt);
      if (_resendCooldown.inSeconds > 0) {
        _resendCooldown -= const Duration(seconds: 1);
      }
    });
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    setState(() {
      _resending = true;
      _resendError = null;
    });
    try {
      final expiresAt = await widget.onResend!.call();
      if (!mounted) return;
      setState(() {
        _expiresAt = expiresAt;
        _timeToExpiry = _remainingUntil(expiresAt);
        _resending = false;
        _resent = true;
        _invalidCode = false;
        _codeController.clear();
        _resendCooldown = widget.resendCooldownDuration;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _resending = false;
        _resendError = error.toString();
      });
    }
  }

  Future<void> _verify() async {
    if (!_canVerify) return;
    setState(() {
      _verifying = true;
      _invalidCode = false;
    });
    final verified = await widget.onVerify(_codeController.text.trim());
    if (!mounted) return;
    setState(() {
      _verifying = false;
      _invalidCode = !verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic =
        theme.extension<AppSemanticColors>() ??
        (theme.brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);

    return AuthScreenLayout(
      onBack: widget.onBack,
      title: _title,
      supportingText: 'We sent a code to ${widget.phoneNumber}.',
      useRecoveryGlass: true,
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
            maxLength: 4,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              letterSpacing: AppSpacing.xs,
              fontWeight: AppFontWeight.bold,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onSubmitted: (_) => _verify(),
            decoration: authInputDecoration(
              context,
              hintText: '0000',
              prefixIcon: AppIcons.sms,
            ).copyWith(counterText: ''),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (_timeToExpiry case final timeToExpiry?)
            _TimerLine(
              icon: AppIcons.eta,
              text: _expired
                  ? 'Code expired'
                  : 'Code expires in ${_formatDuration(timeToExpiry)}',
              color: _expired ? semantic.error : semantic.info,
            )
          else
            _TimerLine(
              icon: AppIcons.info,
              text: 'Use the latest code sent to your phone.',
              color: semantic.info,
            ),
          const SizedBox(height: AppSpacing.md),
          const _UssdFallbackNotice(),
          const SizedBox(height: AppSpacing.md),
          if (_expired)
            AuthStatusAlert(
              title: 'Code Expired',
              message: 'Request a new code before verifying.',
              icon: AppIcons.warning,
              statusColor: semantic.warning,
            )
          else if (_invalidCode)
            AuthStatusAlert(
              title: 'Incorrect Code',
              message: 'That code is wrong or has expired. Try again.',
              icon: AppIcons.error,
              statusColor: semantic.error,
            )
          else if (_resendError != null)
            AuthStatusAlert(
              title: 'Could Not Resend',
              message: _resendError!,
              icon: AppIcons.error,
              statusColor: semantic.error,
            )
          else if (_resent)
            AuthStatusAlert(
              title: 'Code Resent',
              message: 'Check your messages for the latest code.',
              icon: AppIcons.success,
              statusColor: semantic.success,
            ),
          if (_expired || _invalidCode || _resendError != null || _resent)
            const SizedBox(height: AppSpacing.md),
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
                _resending
                    ? 'Resending...'
                    : _canResend
                    ? 'Resend Code'
                    : 'Resend code in ${_formatDuration(_resendCooldown)}',
              ),
            ),
          ),
        ],
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

Duration? _remainingUntil(DateTime? expiresAt) {
  if (expiresAt == null) return null;
  final remaining = expiresAt.difference(DateTime.now());
  return remaining.isNegative ? Duration.zero : remaining;
}

class _UssdFallbackNotice extends StatelessWidget {
  const _UssdFallbackNotice();

  static const message =
      'SMS delayed? Dial *920*331# from your phone to view your code instantly.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>()!;

    return Container(
      key: const ValueKey('otp-ussd-fallback'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: AppComponentRadius.inputField,
        border: Border.all(
          color: semantic.glassBorder,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.info, size: AppIconSize.sm, color: semantic.info),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
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
