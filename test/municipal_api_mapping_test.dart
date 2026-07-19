import 'package:civic_voice/features/municipal/models/incoming_report.dart';
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
  });
}
