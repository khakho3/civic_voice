class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.community,
    this.latitude,
    this.longitude,
    this.photoCount = 0,
  });

  final String title;
  final String description;
  final String category;
  final String location;
  final String community;
  final double? latitude;
  final double? longitude;
  final int photoCount;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'community': community,
      'latitude': latitude,
      'longitude': longitude,
      'photoCount': photoCount,
    };
  }
}
