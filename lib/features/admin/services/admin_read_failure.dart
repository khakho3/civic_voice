import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../services/api_client.dart';

/// Availability of the requested service, never a claim about device internet.
enum AdminReadFailure { unreachable, service, unauthorized, unverified }

AdminReadFailure classifyAdminReadFailure(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException) {
    return AdminReadFailure.unreachable;
  }
  if (error is ApiException) {
    if (error.statusCode == 0 || error.statusCode == 408) {
      return AdminReadFailure.unreachable;
    }
    if (error.statusCode == 401 || error.statusCode == 403) {
      return AdminReadFailure.unauthorized;
    }
    if (error.statusCode >= 500) return AdminReadFailure.service;
  }
  return AdminReadFailure.unverified;
}

bool adminServiceOffline(AdminReadFailure? failure) =>
    failure == AdminReadFailure.unreachable ||
    failure == AdminReadFailure.service;

// Local completion ordering, not backend data or a persisted health snapshot.
int _readSequence = 0;
int nextAdminReadSequence() => ++_readSequence;
