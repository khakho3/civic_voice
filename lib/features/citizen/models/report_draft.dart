import '../../../models/region.dart';

class ReportDraft {
  const ReportDraft({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.community,
    this.latitude,
    this.longitude,
    this.region,
    this.photoPaths = const <String>[],
  });

  final String title;
  final String description;
  final String category;
  final String location;
  final String community;
  final double? latitude;
  final double? longitude;
  final Region? region;
  final List<String> photoPaths;

  int get photoCount => photoPaths.length;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'community': community,
      'latitude': latitude,
      'longitude': longitude,
      'region': region?.name,
      'photoPaths': photoPaths,
      'photoCount': photoCount,
    };
  }
}
