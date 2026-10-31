import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_client.dart';

import '../models/maintenance_profile.dart';

class MaintenanceSession {
  MaintenanceSession._({
    bool Function()? available,
    String? Function()? owner,
    Future<SyncedUser> Function()? read,
  }) : _available = available ?? (() => Firebase.apps.isNotEmpty),
       _owner =
           owner ??
           (() => Firebase.apps.isEmpty
               ? null
               : FirebaseAuth.instance.currentUser?.uid),
       _read = read ?? _readCurrent;

  @visibleForTesting
  factory MaintenanceSession.forTesting({
    required String? Function() owner,
    required Future<SyncedUser> Function() read,
  }) => MaintenanceSession._(available: () => true, owner: owner, read: read);

  final bool Function() _available;
  final String? Function() _owner;
  final Future<SyncedUser> Function() _read;
  int _generation = 0, _refreshRequest = 0, _nameRevision = 0;
  String? _verifiedOwner;
  String? get verifiedOwner => _verifiedOwner;

  static Future<SyncedUser> _readCurrent() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) throw StateError('A signed-in technician is required');
    return ApiClient.instance.syncUser(idToken: token);
  }

  static final MaintenanceSession instance = MaintenanceSession._();

  final ValueNotifier<MaintenanceProfile> profile = ValueNotifier(
    Firebase.apps.isEmpty
        ? MaintenanceProfile.mock
        : const MaintenanceProfile(
            publicId: '',
            fullName: '',
            phone: '',
            region: '',
            assembly: '',
          ),
  );
  bool authenticated = false;

  void setAuthenticatedUser({
    required String publicId,
    required String fullName,
    required String phone,
    required String region,
    required String assembly,
    String? teamId,
    String? teamName,
    String? teamLeadUserId,
  }) {
    ++_generation;
    ++_refreshRequest;
    _verifiedOwner = _owner();
    authenticated = true;
    profile.value = MaintenanceProfile(
      publicId: publicId,
      fullName: fullName,
      phone: phone,
      region: region,
      assembly: assembly,
      teamId: teamId,
      teamName: teamName,
      teamLeadUserId: teamLeadUserId,
    );
  }

  Future<void> refresh() async {
    if (!_available()) return;
    final owner = _owner();
    final generation = _generation, request = ++_refreshRequest;
    final nameRevision = _nameRevision;
    bool owns() => generation == _generation && owner == _owner();
    if (owner == null) {
      clearSession();
      throw StateError('A signed-in technician is required');
    }
    late SyncedUser user;
    try {
      user = await _read();
    } on ApiException catch (error) {
      if (owns() &&
          request == _refreshRequest &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        clearSession();
      }
      rethrow;
    }
    if (!owns()) throw StateError('Your session changed');
    if (request != _refreshRequest) return;
    if (user.firebaseUid != owner) {
      throw StateError('Profile identity could not be verified');
    }
    if (user.role != 'MAINTENANCE' || !user.active || user.isGuest) {
      clearSession();
      throw StateError('Your Maintenance access changed');
    }
    authenticated = true;
    _verifiedOwner = owner;
    profile.value = MaintenanceProfile(
      publicId: user.publicId,
      fullName: nameRevision == _nameRevision
          ? user.fullName
          : profile.value.fullName,
      phone: user.phone ?? '',
      region: user.region ?? '',
      assembly: user.assembly ?? '',
      teamId: user.maintenanceTeamId,
      teamName: user.maintenanceTeamName,
      teamLeadUserId: user.maintenanceTeamLeadUserId,
    );
  }

  void updateProfile({required String fullName}) {
    ++_nameRevision;
    profile.value = profile.value.copyWith(fullName: fullName);
  }

  void clearSession() {
    ++_generation;
    ++_refreshRequest;
    _verifiedOwner = null;
    authenticated = false;
    profile.value = const MaintenanceProfile(
      publicId: '',
      fullName: '',
      phone: '',
      region: '',
      assembly: '',
    );
  }

  @visibleForTesting
  void dispose() {
    ++_generation;
    profile.dispose();
  }
}
