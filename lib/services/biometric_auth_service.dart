import 'package:local_auth/local_auth.dart';

/// Drives both the Settings toggle (never offered as if it works when it
/// can't) and the lock screen's defensive re-check on every load.
enum BiometricAvailability {
  /// Hardware present, at least one biometric enrolled — ready to use.
  available,

  /// Hardware present, nothing enrolled. Fixed in OS Settings, not here.
  notEnrolled,

  /// No usable biometric path at all — also what a plain `flutter test`
  /// widget test always resolves to, since local_auth's platform channel
  /// is unmocked there and every call throws, caught below.
  noHardware,
}

/// Collapses local_auth's 13 [LocalAuthExceptionCode] values down to the
/// 4 distinctions that change what the lock screen says or does.
enum BiometricAuthFailureReason {
  /// User backed out, or a real device-level cancel/timeout/interruption.
  /// Not an error — just "not this time."
  canceled,

  /// Too many failed attempts; OS-enforced cooldown.
  lockedOut,

  /// No longer usable on this device (enrollment removed, hardware
  /// fault) — the lock screen reacts by clearing the stored preference
  /// and letting the user through, not offering a Retry that can't work.
  unavailable,

  /// Anything else — no actionable distinction worth surfacing.
  other,
}

class BiometricAuthResult {
  const BiometricAuthResult.success() : successful = true, failureReason = null;
  const BiometricAuthResult.failure(BiometricAuthFailureReason reason)
    : successful = false,
      failureReason = reason;

  final bool successful;
  final BiometricAuthFailureReason? failureReason;
}

/// `biometricOnly: true` — the lock screen's own Logout, not the device's
/// PIN/pattern, is the fallback.
class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _localizedReason =
      "Verify it's you to continue using CivicVoice.";

  /// Never throws — any plugin/channel failure (including the
  /// MissingPluginException a plain widget test raises) collapses to
  /// [BiometricAvailability.noHardware].
  Future<BiometricAvailability> checkAvailability() async {
    try {
      if (!await _localAuth.isDeviceSupported()) {
        return BiometricAvailability.noHardware;
      }
      if (!await _localAuth.canCheckBiometrics) {
        return BiometricAvailability.noHardware;
      }
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.available;
    } catch (_) {
      return BiometricAvailability.noHardware;
    }
  }

  /// Never throws — see [_mapFailureReason].
  Future<BiometricAuthResult> authenticate() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: _localizedReason,
        biometricOnly: true,
      );
      return didAuthenticate
          ? const BiometricAuthResult.success()
          : const BiometricAuthResult.failure(
              BiometricAuthFailureReason.canceled,
            );
    } on LocalAuthException catch (error) {
      return BiometricAuthResult.failure(_mapFailureReason(error.code));
    } catch (_) {
      return const BiometricAuthResult.failure(
        BiometricAuthFailureReason.other,
      );
    }
  }

  BiometricAuthFailureReason _mapFailureReason(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.authInProgress:
        return BiometricAuthFailureReason.canceled;
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return BiometricAuthFailureReason.lockedOut;
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return BiometricAuthFailureReason.unavailable;
      case LocalAuthExceptionCode.uiUnavailable:
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return BiometricAuthFailureReason.other;
      // New enum values may be added by local_auth without a breaking release.
      // ignore: unreachable_switch_default
      default:
        return BiometricAuthFailureReason.other;
    }
  }
}
