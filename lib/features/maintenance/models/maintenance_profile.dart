class MaintenanceProfile {
  const MaintenanceProfile({
    required this.publicId,
    required this.fullName,
    required this.phone,
    required this.region,
    required this.assembly,
    this.teamId,
    this.teamName,
    this.teamLeadUserId,
  });

  final String publicId;
  final String fullName;
  final String phone;
  final String region;
  final String assembly;
  final String? teamId;
  final String? teamName;
  final String? teamLeadUserId;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  MaintenanceProfile copyWith({String? fullName}) {
    return MaintenanceProfile(
      publicId: publicId,
      fullName: fullName ?? this.fullName,
      phone: phone,
      region: region,
      assembly: assembly,
      teamId: teamId,
      teamName: teamName,
      teamLeadUserId: teamLeadUserId,
    );
  }

  static const mock = MaintenanceProfile(
    publicId: 'MNT-000004',
    fullName: 'Yaw Asare',
    phone: '+233 20 000 0000',
    region: 'Ashanti Region',
    assembly: 'Kumasi Metropolitan Assembly',
  );
}
