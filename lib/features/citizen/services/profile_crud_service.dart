import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/citizen_profile.dart';
import 'citizen_data_repository.dart';

class ProfileCrudService implements ProfileRepository {
  ProfileCrudService._();

  static final ProfileCrudService instance = ProfileCrudService._();

  static const CitizenProfile _defaultProfile = CitizenProfile(
    id: 'citizen-profile',
    fullName: 'Amina Mensah',
    email: 'amina.mensah@gmail.com',
    phone: '+233 24 555 0198',
    primaryLocation: 'Main Road, Ward 4',
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

  @override
  Future<CitizenProfile> createProfile(CitizenProfile newProfile) async {
    _publishProfile(newProfile);
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateProfile(CitizenProfile updatedProfile) async {
    _publishProfile(updatedProfile);
    return profile.value;
  }

  @override
  Future<CitizenProfile> updateProfilePhoto(String? photoPath) async {
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
