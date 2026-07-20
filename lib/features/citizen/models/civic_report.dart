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
    this.assembly,
    this.photoCount = 0,
    this.photoPaths = const <String>[],
    this.submittedAt,
    this.rejectionReason,
    this.rejectedAt,
    required this.timeLabel,
    required this.status,
    this.hasMunicipalCoverage,
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
  final String? assembly;
  final int photoCount;

  /// Local file paths for the photos attached to this report. There's no
  /// backend upload yet, so these point at on-device files rather than
  /// remote URLs — [photoCount] should always equal `photoPaths.length`.
  final List<String> photoPaths;
  final DateTime? submittedAt;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final String timeLabel;
  final ReportStatus status;

  /// Whether the report's region/assembly currently has an active Municipal
  /// Officer covering it — null means region/assembly hasn't been resolved
  /// yet. Computed fresh by the backend on every read (see reports.js's
  /// coverageForPairs), so it naturally flips to true the moment an officer
  /// is provisioned for a previously-uncovered area, with no migration or
  /// stored flag needed on this end.
  final bool? hasMunicipalCoverage;

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
      assembly: map['assembly'] as String?,
      photoCount: (map['photoCount'] as num?)?.toInt() ?? 0,
      photoPaths:
          (map['photoPaths'] as List<Object?>?)?.cast<String>() ??
          const <String>[],
      submittedAt: submittedAtValue == null
          ? null
          : DateTime.tryParse(submittedAtValue),
      rejectionReason: map['rejectionReason'] as String?,
      rejectedAt: DateTime.tryParse(map['rejectedAt'] as String? ?? ''),
      timeLabel: map['timeLabel'] as String? ?? '',
      status: ReportStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => ReportStatus.submitted,
      ),
      hasMunicipalCoverage: map['hasMunicipalCoverage'] as bool?,
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
      'assembly': assembly,
      'photoCount': photoCount,
      'photoPaths': photoPaths,
      'submittedAt': submittedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
      'rejectedAt': rejectedAt?.toIso8601String(),
      'timeLabel': timeLabel,
      'status': status.name,
      'hasMunicipalCoverage': hasMunicipalCoverage,
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
    String? assembly,
    int? photoCount,
    List<String>? photoPaths,
    DateTime? submittedAt,
    String? rejectionReason,
    DateTime? rejectedAt,
    String? timeLabel,
    ReportStatus? status,
    bool? hasMunicipalCoverage,
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
      assembly: assembly ?? this.assembly,
      photoCount: photoCount ?? this.photoCount,
      photoPaths: photoPaths ?? this.photoPaths,
      submittedAt: submittedAt ?? this.submittedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      timeLabel: timeLabel ?? this.timeLabel,
      status: status ?? this.status,
      hasMunicipalCoverage: hasMunicipalCoverage ?? this.hasMunicipalCoverage,
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
