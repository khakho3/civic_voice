import 'package:flutter/foundation.dart';

import '../models/maintenance_profile.dart';

class MaintenanceSession {
  MaintenanceSession._();

  static final MaintenanceSession instance = MaintenanceSession._();

  final ValueNotifier<MaintenanceProfile> profile = ValueNotifier(
    MaintenanceProfile.mock,
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
    String? avatarUrl,
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
      avatarUrl: avatarUrl,
    );
  }

  void updateProfile({required String fullName, String? avatarUrl}) {
    profile.value = profile.value.copyWith(
      fullName: fullName,
      avatarUrl: avatarUrl,
    );
  }
}
