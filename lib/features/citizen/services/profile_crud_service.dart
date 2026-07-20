import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/citizen_profile.dart';
import 'citizen_data_repository.dart';
import '../../../services/api_client.dart';

class ProfileCrudService implements ProfileRepository {
  ProfileCrudService._();

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
    _publishProfile(
      CitizenProfile(
        id: user.id,
        fullName: user.fullName,
        email: '',
        phone: user.phone ?? '',
        primaryLocation: '',
        photoPath: user.avatarUrl == null
            ? null
            : ApiClient.assetUrl(user.avatarUrl!),
        twoStepEnabled: false,
        isGuest: user.isGuest,
      ),
    );
  }

  @override
  Future<CitizenProfile> createProfile(CitizenProfile newProfile) async {
    _publishProfile(newProfile);
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateProfile(CitizenProfile updatedProfile) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      await ApiClient.instance.updateProfile(
        idToken: token,
        fullName: updatedProfile.fullName,
      );
    }
    _publishProfile(updatedProfile);
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateProfilePhoto(String? photoPath) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token != null) {
      await ApiClient.instance.updateProfile(
        idToken: token,
        avatarPath: photoPath,
        removeAvatar: photoPath == null,
      );
    }
    _publishProfile(
      profile.value.copyWith(
        photoPath: photoPath,
        clearPhoto: photoPath == null,
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
