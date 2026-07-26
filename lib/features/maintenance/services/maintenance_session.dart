import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/maintenance_profile.dart';

class MaintenanceSession {
  MaintenanceSession._();

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

  void updateProfile({required String fullName}) {
    profile.value = profile.value.copyWith(fullName: fullName);
  }

  void clearSession() {
    authenticated = false;
    profile.value = const MaintenanceProfile(
      publicId: '',
      fullName: '',
      phone: '',
      region: '',
      assembly: '',
    );
  }
}
