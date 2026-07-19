import 'package:civic_voice/features/municipal/models/incoming_report.dart';
import 'package:civic_voice/features/municipal/models/resolved_report.dart';
import 'package:civic_voice/models/report_status.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a backend report without exposing its internal id', () {
    ApiClient.baseUrl = 'http://192.168.100.8:4000';
    final report = IncomingReportItem.fromApi({
      'id': 'internal-cuid',
      'publicReference': 'CV-2026-A1B2C3D4E5',
      'title': 'Broken streetlight',
      'description': 'The lamp is out.',
      'location': 'High Street',
      'category': 'Safety',
      'status': 'UNDER_REVIEW',
      'photoUrls': ['http://localhost:4000/uploads/reports/photo.jpg'],
      'resolutionPhotoUrls': <String>[],
      'createdAt': '2026-07-19T09:00:00.000Z',
      'updatedAt': '2026-07-19T09:30:00.000Z',
      'citizen': {'fullName': 'Victoria Akosua', 'phone': '+233500000000'},
      'assembly': 'Ga Central',
      'reviewer': {
        'publicId': 'MUN-000022',
        'fullName': 'Latif',
        'phone': '+233552072073',
      },
      'reviewedByCurrentUser': true,
      'reviewedAt': '2026-07-19T09:20:00.000Z',
    });

    expect(report.apiRecordId, 'internal-cuid');
    expect(report.referenceId, 'CV-2026-A1B2C3D4E5');
    expect(report.category, ReportCategory.safety);
    expect(report.status, ReportStatus.underReview);
    expect(
      report.photoUrl,
      'http://192.168.100.8:4000/uploads/reports/photo.jpg',
    );
    expect(report.citizenName, 'Victoria Akosua');
    expect(report.assembly, 'Ga Central');
    expect(report.reviewerName, 'Latif');
    expect(report.reviewedByCurrentUser, isTrue);
    expect(report.canCurrentOfficerReview, isTrue);
  });

  test('a report claimed by another officer remains visible but read-only', () {
    final report = IncomingReportItem.fromApi({
      'id': 'internal-cuid-2',
      'publicReference': 'CV-2026-LOCKED',
      'title': 'Blocked drain',
      'location': 'Market Road',
      'category': 'Sanitation',
      'status': 'SUBMITTED',
      'photoUrls': <String>[],
      'resolutionPhotoUrls': <String>[],
      'reviewer': {
        'publicId': 'other-officer',
        'fullName': 'Other Officer',
        'phone': '+233500000001',
      },
      'reviewedByCurrentUser': false,
    });

    expect(report.hasReviewer, isTrue);
    expect(report.canCurrentOfficerReview, isFalse);
    expect(report.reviewerName, 'Other Officer');
  });

  test(
    'a rejected report keeps its reason, timestamp, and citizen evidence',
    () {
      final report = IncomingReportItem.fromApi({
        'id': 'internal-rejected',
        'publicReference': 'CV-2026-REJECTED',
        'title': 'Duplicate drain report',
        'location': 'Market Road',
        'category': 'Sanitation',
        'status': 'REJECTED',
        'photoUrls': ['/uploads/reports/evidence.jpg'],
        'resolutionPhotoUrls': <String>[],
        'rejectionReason': 'This duplicates CV-2026-ORIGINAL.',
        'rejectedAt': '2026-07-19T10:00:00.000Z',
        'createdAt': '2026-07-19T09:00:00.000Z',
        'updatedAt': '2026-07-19T10:00:00.000Z',
      });
      final closed = ResolvedReportItem.fromReport(report);

      expect(report.status, ReportStatus.rejected);
      expect(report.rejectionReason, 'This duplicates CV-2026-ORIGINAL.');
      expect(report.rejectedAt, DateTime.utc(2026, 7, 19, 10));
      expect(closed.isRejected, isTrue);
      expect(closed.resolutionNote, 'This duplicates CV-2026-ORIGINAL.');
      expect(closed.evidencePhotoCount, 1);
    },
  );
}
