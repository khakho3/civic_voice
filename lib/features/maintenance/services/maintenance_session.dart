import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/api_client.dart';

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

  Future<void> refresh() async {
    if (Firebase.apps.isEmpty) return;
    final identity = FirebaseAuth.instance.currentUser;
    final token = await identity?.getIdToken();
    if (identity == null || token == null) {
      throw StateError('A signed-in technician is required');
    }
    final user = await ApiClient.instance.syncUser(idToken: token);
    if (FirebaseAuth.instance.currentUser?.uid != identity.uid ||
        user.role != 'MAINTENANCE') {
      throw StateError('Your session changed');
    }
    setAuthenticatedUser(
      publicId: user.publicId,
      fullName: user.fullName,
      phone: user.phone ?? '',
      region: user.region ?? '',
      assembly: user.assembly ?? '',
      teamId: user.maintenanceTeamId,
      teamName: user.maintenanceTeamName,
      teamLeadUserId: user.maintenanceTeamLeadUserId,
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
