import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_client.dart';

/// Safe auth feedback; a transport failure does not establish device offline.
String authFailureMessage(
  Object error, {
  String fallback = 'The request could not be completed. Please try again.',
}) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is FirebaseAuthException &&
          error.code == 'network-request-failed' ||
      error is ApiException &&
          (error.statusCode == 0 || error.statusCode == 408)) {
    return 'Could not reach CivicVoice. Check your connection or try again shortly.';
  }
  if (error is ApiException && error.statusCode == 429 ||
      error is FirebaseAuthException && error.code == 'too-many-requests') {
    return 'Too many attempts. Please wait before trying again.';
  }
  if (error is ApiException &&
      (error.statusCode == 401 || error.statusCode == 403)) {
    return 'This request could not be authorized. Sign in again or request a new code.';
  }
  if (error is ApiException && error.statusCode >= 500) {
    return 'The service is unavailable. Please try again shortly.';
  }
  return fallback;
}
