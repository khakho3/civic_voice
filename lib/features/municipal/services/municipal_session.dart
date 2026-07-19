import 'package:flutter/foundation.dart';

import '../models/officer_profile.dart';

/// Live identity and jurisdiction for the signed-in Municipal Officer.
class MunicipalSession {
  MunicipalSession._();

  static final MunicipalSession instance = MunicipalSession._();

  final ValueNotifier<OfficerProfile> profile = ValueNotifier(
    OfficerProfile.mock(),
  );

  void setAuthenticatedUser({
    required String publicId,
    required String fullName,
    required String phone,
    required String region,
    required String assembly,
    String? avatarUrl,
  }) {
    profile.value = OfficerProfile(
      name: fullName,
      role: 'Municipal Officer',
      employeeId: publicId,
      verifiedOfficial: true,
      phone: phone,
      department: assembly,
      region: region,
      avatarUrl: avatarUrl,
    );
  }

  void updateName(String name) {
    profile.value = profile.value.copyWith(name: name);
  }
}
