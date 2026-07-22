class CitizenProfile {
  const CitizenProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.primaryLocation,
    this.twoStepEnabled = true,
    this.isGuest = false,
  });

  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String primaryLocation;
  final bool twoStepEnabled;
  /// True for a "Continue as Guest" session (Firebase Anonymous Auth, no
  /// phone/password of their own yet) — see ApiClient.SyncedUser.isGuest.
  /// Drives the guest-mode messaging on Dashboard/Profile; never true for
  /// an account that's registered for real.
  final bool isGuest;

  factory CitizenProfile.fromMap(Map<String, Object?> map) {
    return CitizenProfile(
      id: map['id'] as String? ?? 'citizen-profile',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      primaryLocation: map['primaryLocation'] as String? ?? '',
      twoStepEnabled: map['twoStepEnabled'] as bool? ?? true,
      isGuest: map['isGuest'] as bool? ?? false,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'primaryLocation': primaryLocation,
      'twoStepEnabled': twoStepEnabled,
      'isGuest': isGuest,
    };
  }

  CitizenProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? primaryLocation,
    bool? twoStepEnabled,
    bool? isGuest,
  }) {
    return CitizenProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      primaryLocation: primaryLocation ?? this.primaryLocation,
      twoStepEnabled: twoStepEnabled ?? this.twoStepEnabled,
      isGuest: isGuest ?? this.isGuest,
    );
  }
}
