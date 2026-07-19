import 'package:flutter/foundation.dart';

import '../models/ministry_profile_data.dart';

class MinistrySession {
  MinistrySession._();

  static final instance = MinistrySession._();

  final ValueNotifier<MinistryProfileData> profile = ValueNotifier(
    MinistryProfileData.mock(),
  );

  void setAuthenticatedUser({
    required String publicId,
    required String fullName,
    required String phone,
    String? avatarUrl,
  }) {
    profile.value = MinistryProfileData(
      name: fullName,
      role: 'National supervisor',
      ministry: 'CivicVoice National Oversight',
      email: '',
      phone: phone,
      publicId: publicId,
      avatarUrl: avatarUrl,
      metadataBadges: const [
        'Ministry Supervisor',
        'National visibility',
        'Read-only oversight',
      ],
    );
  }

  void updateProfile({required String fullName, String? avatarUrl}) {
    profile.value = profile.value.copyWith(name: fullName);
  }
}
