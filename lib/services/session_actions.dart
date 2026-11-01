import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app_cache_service.dart';
import 'auth_transitions.dart';
import 'idle_session_timer.dart';
import 'api_client.dart';
import 'mock_auth_service.dart';
import 'session_data_service.dart';

/// Mirrors `AppRoutes.login` in main.dart — the same duplication every
/// screen's own `routeName` constant already uses, so this file doesn't
/// need to import main.dart (which imports every screen, including the
/// ones that call [signOut]) just for one route string.
const String _loginRoute = '/login';

/// Ends the current session and returns to Login. Shared by every module's
/// Log Out action and Citizen's bottom-nav Profile tab route so both get
/// the exact same teardown (idle timer, Firebase, MockAuthService,
/// keepSignedIn) instead of two copies drifting apart.
Future<void> signOut(BuildContext context) async {
  await endSession();
  if (!context.mounted) return;
  // A device that's already had an account signed in on it should never
  // see the onboarding carousel again on sign-out.
  Navigator.of(context).pushNamedAndRemoveUntil(_loginRoute, (_) => false);
}

Future<void> endSession() => AuthTransitions.instance.close(_performEndSession);

/// Called before an unsuccessful pipeline releases its exclusive ownership.
Future<void> clearFailedAuthTransition(AuthTransitionLease lease) async {
  final transitions = AuthTransitions.instance;
  if (!transitions.owns(lease) ||
      transitions.isClosing ||
      lease.cleanupUid == null) {
    return;
  }
  if (Firebase.apps.isEmpty) {
    if (AppCacheService.instance.activeAccountId != lease.cleanupUid) return;
  } else {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid != lease.cleanupUid) return;
  }
  try {
    if (lease.endSdkOnFailure) {
      await _performEndSession();
    } else if (AppCacheService.instance.activeAccountId == lease.cleanupUid) {
      // Reusing a Guest must not destroy its only credential when local
      // publication fails. Its persisted UID-owned drafts remain recoverable.
      try {
        await MockAuthService().clearUser();
      } finally {
        SessionDataService.clear();
      }
    }
  } finally {
    lease.cleanedOwned = true;
  }
}

Future<void> _performEndSession() async {
  try {
    await AppCacheService.instance.setKeepSignedIn(false);
  } catch (_) {
    // Preference storage failure must not prevent local account teardown.
  }
  IdleSessionTimer.instance.cancel();
  if (Firebase.apps.isNotEmpty) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      if (idToken != null) {
        try {
          await ApiClient.instance.reportSignOut(idToken: idToken);
        } catch (_) {
          // An unavailable audit service must never prevent local logout.
        }
      }
      if (idToken != null) {
        final pushToken = await FirebaseMessaging.instance.getToken();
        if (pushToken != null) {
          await ApiClient.instance.unregisterPushToken(
            idToken: idToken,
            token: pushToken,
          );
        }
      }
    } catch (_) {
      // Logout must still complete when the device is offline.
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Local teardown must not be blocked by a platform sign-out failure.
    }
  }
  try {
    await MockAuthService().clearUser();
  } finally {
    SessionDataService.clear();
  }
}
