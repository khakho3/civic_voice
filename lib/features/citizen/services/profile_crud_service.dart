import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/citizen_profile.dart';
import 'citizen_data_repository.dart';
import '../../../services/api_client.dart';

class ProfileCrudService implements ProfileRepository {
  ProfileCrudService._()
    : this._withDependencies(
        () => Firebase.apps.isEmpty
            ? null
            : FirebaseAuth.instance.currentUser?.uid,
        () async => Firebase.apps.isEmpty
            ? null
            : FirebaseAuth.instance.currentUser?.getIdToken(),
        (token) => ApiClient.instance.syncUser(idToken: token),
      );

  ProfileCrudService._withDependencies(
    this._account,
    this._credential,
    this._sync,
  );

  @visibleForTesting
  ProfileCrudService.forTesting({
    required String? Function() account,
    required Future<String?> Function() credential,
    required Future<SyncedUser> Function(String) sync,
  }) : this._withDependencies(account, credential, sync);

  final String? Function() _account;
  final Future<String?> Function() _credential;
  final Future<SyncedUser> Function(String) _sync;
  String? _sessionUid;
  int _generation = 0, _standingRead = 0;

  static final ProfileCrudService instance = ProfileCrudService._();

  static const CitizenProfile _defaultProfile = CitizenProfile(
    id: 'citizen-profile',
    fullName: '',
    email: '',
    phone: '',
    primaryLocation: '',
  );

  final StreamController<CitizenProfile> _profileController =
      StreamController<CitizenProfile>.broadcast();

  @override
  final ValueNotifier<CitizenProfile> profile = ValueNotifier<CitizenProfile>(
    _defaultProfile,
  );

  @override
  Stream<CitizenProfile> watchProfile() async* {
    yield profile.value;
    yield* _profileController.stream;
  }

  @override
  Future<CitizenProfile> readProfile() async {
    return profile.value;
  }

  void loadSignedInUser(SyncedUser user) {
    if (user.role != 'CITIZEN') {
      clearSession();
      return;
    }
    ++_generation;
    ++_standingRead;
    _sessionUid = user.firebaseUid;
    _publishProfile(
      CitizenProfile(
        id: user.id,
        fullName: user.fullName,
        email: '',
        phone: user.phone ?? '',
        primaryLocation: '',
        twoStepEnabled: false,
        isGuest: user.isGuest,
        trustRating: user.isGuest || !user.active ? null : user.trustRating,
      ),
    );
  }

  void clearSession() {
    ++_generation;
    ++_standingRead;
    _sessionUid = null;
    _publishProfile(_defaultProfile);
  }

  /// Refresh only standing; never replace a newer name edit or account session.
  Future<void> refreshStanding() async {
    final uid = _account(), before = profile.value;
    if (uid == null || before.isGuest || _sessionUid == null) return;
    if (_sessionUid != uid) {
      _publishProfile(before.copyWith(clearTrustRating: true));
      return;
    }
    final generation = _generation, read = ++_standingRead;
    bool ownsRead() =>
        generation == _generation &&
        read == _standingRead &&
        _sessionUid == uid &&
        _account() == uid &&
        profile.value.id == before.id;
    void hideChangedOwner() {
      if (generation == _generation &&
          _sessionUid == uid &&
          _account() != uid) {
        _publishProfile(profile.value.copyWith(clearTrustRating: true));
      }
    }

    try {
      final token = await _credential();
      if (!ownsRead()) {
        hideChangedOwner();
        return;
      }
      if (token == null) {
        throw StateError('Standing requires a verified session');
      }
      final user = await _sync(token);
      if (!ownsRead()) {
        hideChangedOwner();
        return;
      }
      final valid =
          user.firebaseUid == uid &&
          user.id == before.id &&
          user.role == 'CITIZEN' &&
          user.active &&
          !user.isGuest;
      _publishProfile(
        profile.value.copyWith(
          trustRating: valid ? user.trustRating : null,
          clearTrustRating: !valid || user.trustRating == null,
        ),
      );
    } catch (_) {
      if (ownsRead()) {
        _publishProfile(profile.value.copyWith(clearTrustRating: true));
      } else {
        hideChangedOwner();
      }
    }
  }

  @override
  Future<CitizenProfile> createProfile(CitizenProfile newProfile) async {
    _publishProfile(newProfile);
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateProfile(CitizenProfile updatedProfile) async {
    final generation = _generation, id = profile.value.id, uid = _sessionUid;
    bool current() =>
        generation == _generation &&
        profile.value.id == id &&
        updatedProfile.id == id &&
        _sessionUid == uid &&
        (uid == null || _account() == uid);
    final token = await _credential();
    if (token == null) {
      throw StateError('A verified profile session is required');
    }
    if (!current()) throw StateError('Profile session changed');
    await ApiClient.instance.updateProfile(
      idToken: token,
      fullName: updatedProfile.fullName,
    );
    if (!current()) throw StateError('Profile session changed');
    // A standing refresh may finish while the name save is in flight.
    _publishProfile(
      updatedProfile.copyWith(
        trustRating: profile.value.trustRating,
        clearTrustRating: profile.value.trustRating == null,
      ),
    );
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateTwoStep(bool enabled) async {
    _publishProfile(profile.value.copyWith(twoStepEnabled: enabled));
    return profile.value;
  }

  @override
  Future<void> deleteProfile() async {
    _publishProfile(_defaultProfile);
  }

  void _publishProfile(CitizenProfile updatedProfile) {
    profile.value = updatedProfile;
    _profileController.add(updatedProfile);
  }
}
