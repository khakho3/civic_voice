import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/api_client.dart';
import '../widgets/nearby_seconding_card.dart';
import 'location_service.dart';

/// Each discovery/confirmation obtains its own bounded, recent device fix.
/// The selected report pin is never used as proof of the citizen's presence.
class NearbyReportsService {
  NearbyReportsService({
    this.locationService = const LocationService(),
    Future<String?> Function()? token,
    String? Function()? account,
    Future<List<Map<String, dynamic>>> Function(String, Position)? discover,
    Future<void> Function(String, String, Position)? confirm,
    DateTime Function()? now,
  }) : _token =
           token ??
           (() =>
               FirebaseAuth.instance.currentUser?.getIdToken() ??
               Future.value()),
       _account = account ?? (() => FirebaseAuth.instance.currentUser?.uid),
       _discover = discover ?? _discoverApi,
       _confirm = confirm ?? _confirmApi,
       _now = now ?? DateTime.now;

  final LocationService locationService;
  final Future<String?> Function() _token;
  final String? Function() _account;
  final Future<List<Map<String, dynamic>>> Function(String, Position) _discover;
  final Future<void> Function(String, String, Position) _confirm;
  final DateTime Function() _now;

  Future<Position> currentPosition() async {
    final result = await locationService.requestCurrentPosition();
    final p = result.position;
    if (result.status != LocationAccessStatus.ready || p == null) {
      throw ApiException(
        statusCode: 400,
        message: result.message ?? 'Allow phone location and try again.',
      );
    }
    _validatePosition(p);
    return p;
  }

  void _validatePosition(Position p) {
    final age = _now().toUtc().difference(p.timestamp.toUtc()).inMilliseconds;
    if (!p.latitude.isFinite ||
        p.latitude.abs() > 90 ||
        !p.longitude.isFinite ||
        p.longitude.abs() > 180 ||
        !p.accuracy.isFinite ||
        p.accuracy < 0 ||
        p.accuracy > 100 ||
        age > 60000 ||
        age < -10000) {
      throw const ApiException(
        statusCode: 400,
        message: 'Get a fresh, accurate phone location and try again.',
      );
    }
  }

  void _checkAccount(String? account) {
    if (account == null || account != _account()) {
      throw const ApiException(
        statusCode: 401,
        message: 'Sign in again to check nearby reports.',
      );
    }
  }

  Future<List<NearbySecondingReport>> discover() async {
    final account = _account();
    _checkAccount(account);
    final position = await currentPosition();
    _checkAccount(account);
    final token = await _token();
    _checkAccount(account);
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    _validatePosition(position);
    final raw = await _discover(token, position);
    _checkAccount(account);
    return raw.map(NearbySecondingReport.fromApi).toList();
  }

  Future<void> confirm(NearbySecondingReport report) async {
    final account = _account();
    _checkAccount(account);
    final position = await currentPosition();
    _checkAccount(account);
    final lat = report.latitude, lng = report.longitude;
    if (lat == null ||
        lng == null ||
        !lat.isFinite ||
        !lng.isFinite ||
        lat.abs() > 90 ||
        lng.abs() > 180 ||
        Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              lat,
              lng,
            ) >
            300) {
      throw const ApiException(
        statusCode: 400,
        message: 'Move within 300 metres of the report to confirm it.',
      );
    }
    final token = await _token();
    _checkAccount(account);
    if (token == null) {
      throw const ApiException(statusCode: 401, message: 'Sign in required');
    }
    _validatePosition(position);
    await _confirm(token, report.id, position);
    _checkAccount(account);
  }

  static Future<List<Map<String, dynamic>>> _discoverApi(
    String token,
    Position p,
  ) => ApiClient.instance.fetchNearbySeconding(
    idToken: token,
    latitude: p.latitude,
    longitude: p.longitude,
    accuracy: p.accuracy,
    capturedAt: p.timestamp,
  );
  static Future<void> _confirmApi(String token, String id, Position p) =>
      ApiClient.instance.secondReport(
        id,
        idToken: token,
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        capturedAt: p.timestamp,
      );
}
