import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app_cache_service.dart';
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

Future<void> endSession() async {
  await AppCacheService.instance.setKeepSignedIn(false);
  IdleSessionTimer.instance.cancel();
  if (Firebase.apps.isNotEmpty) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final idToken = await user?.getIdToken();
      final pushToken = await FirebaseMessaging.instance.getToken();
      if (idToken != null && pushToken != null) {
        await ApiClient.instance.unregisterPushToken(
          idToken: idToken,
          token: pushToken,
        );
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
  await MockAuthService().clearUser();
  SessionDataService.clear();
}
