import '../../../models/region.dart';
import '../../../models/report_status.dart';

export '../../../models/report_status.dart';

class CivicReport {
  const CivicReport({
    this.id = '',
    this.referenceNumber = '',
    required this.title,
    this.description = '',
    this.category = '',
    required this.location,
    this.community = '',
    this.latitude,
    this.longitude,
    this.region,
    this.photoCount = 0,
    this.photoPaths = const <String>[],
    this.submittedAt,
    required this.timeLabel,
    required this.status,
  });

  final String id;
  final String referenceNumber;
  final String title;
  final String description;
  final String category;
  final String location;
  final String community;
  final double? latitude;
  final double? longitude;

  /// The region this report was filed in, derived from reverse-geocoding
  /// the report's location — determines which municipal/district/
  /// metropolitan assembly it should route to. Null if the geocoder
  /// couldn't resolve a recognized region.
  final Region? region;
  final int photoCount;

  /// Local file paths for the photos attached to this report. There's no
  /// backend upload yet, so these point at on-device files rather than
  /// remote URLs — [photoCount] should always equal `photoPaths.length`.
  final List<String> photoPaths;
  final DateTime? submittedAt;
  final String timeLabel;
  final ReportStatus status;

  factory CivicReport.fromMap(Map<String, Object?> map) {
    final statusName = map['status'] as String?;
    final submittedAtValue = map['submittedAt'] as String?;

    return CivicReport(
      id: map['id'] as String? ?? '',
      referenceNumber: map['referenceNumber'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      location: map['location'] as String? ?? '',
      community: map['community'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      region: _regionFromName(map['region'] as String?),
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      photoPaths:
          (map['photoPaths'] as List<Object?>?)?.cast<String>() ??
          const <String>[],
      submittedAt: submittedAtValue == null
          ? null
          : DateTime.tryParse(submittedAtValue),
      timeLabel: map['timeLabel'] as String? ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ReportStatus.submitted,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'referenceNumber': referenceNumber,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'community': community,
      'latitude': latitude,
      'longitude': longitude,
      'region': region?.name,
      'photoCount': photoCount,
      'photoPaths': photoPaths,
      'submittedAt': submittedAt?.toIso8601String(),
      'timeLabel': timeLabel,
      'status': status.name,
    };
  }

  CivicReport copyWith({
    String? id,
    String? referenceNumber,
    String? title,
    String? description,
    String? category,
    String? location,
    String? community,
    double? latitude,
    double? longitude,
    Region? region,
    int? photoCount,
    List<String>? photoPaths,
    DateTime? submittedAt,
    String? timeLabel,
    ReportStatus? status,
  }) {
    return CivicReport(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      community: community ?? this.community,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      region: region ?? this.region,
      photoCount: photoCount ?? this.photoCount,
      photoPaths: photoPaths ?? this.photoPaths,
      submittedAt: submittedAt ?? this.submittedAt,
      timeLabel: timeLabel ?? this.timeLabel,
      status: status ?? this.status,
    );
  }
}

Region? _regionFromName(String? name) {
  if (name == null) return null;
  for (final region in Region.values) {
    if (region.name == name) return region;
  }
  return null;
}
