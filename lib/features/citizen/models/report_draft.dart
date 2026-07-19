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
    this.assembly,
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
  final String? assembly;
  final List<String> photoPaths;

  int get photoCount => photoPaths.length;

  ReportDraft copyWith({
    String? title,
    String? description,
    String? category,
    String? location,
    String? community,
    double? latitude,
    double? longitude,
    Region? region,
    String? assembly,
    List<String>? photoPaths,
  }) {
    return ReportDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      community: community ?? this.community,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      assembly: assembly ?? this.assembly,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  factory ReportDraft.fromMap(Map<String, dynamic> map) {
    final regionName = map['region'] as String?;
    return ReportDraft(
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      location: map['location'] as String? ?? '',
      community: map['community'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      region: regionName == null
          ? null
          : Region.values.cast<Region?>().firstWhere(
              (region) => region?.name == regionName,
              orElse: () => null,
            ),
      assembly: map['assembly'] as String?,
      photoPaths:
          (map['photoPaths'] as List<dynamic>?)?.whereType<String>().toList() ??
          const <String>[],
    );
  }

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
      'assembly': assembly,
      'photoPaths': photoPaths,
      'photoCount': photoCount,
    };
  }
}
