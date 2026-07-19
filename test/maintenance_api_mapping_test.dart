import 'package:civic_voice/features/maintenance/models/maintenance_task.dart';
import 'package:civic_voice/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps an assigned team UUID into a live maintenance task', () {
    ApiClient.baseUrl = 'http://192.168.100.8:4000';
    final task = MaintenanceTask.fromApi({
      'id': 'internal-report-id',
      'publicReference': 'CV-2026-TASK01',
      'title': 'Blocked drain',
      'description': 'Drain is overflowing.',
      'category': 'Sanitation',
      'location': 'Market Road',
      'latitude': 5.6,
      'longitude': -0.2,
      'status': 'ASSIGNED',
      'region': 'greaterAccra',
      'assembly': 'Ga Central',
      'assignedTeamId': 'b9955110-7ecb-4fd6-a71e-c2dd3f17db86',
      'assignedTeamName': 'Ga Central Maintenance Team',
      'photoUrls': ['/uploads/reports/drain.jpg'],
      'resolutionPhotoUrls': <String>[],
      'createdAt': '2026-07-19T09:00:00.000Z',
      'updatedAt': '2026-07-19T09:30:00.000Z',
    });

    expect(task.apiId, 'internal-report-id');
    expect(task.id, 'CV-2026-TASK01');
    expect(task.status, MaintenanceTaskStatus.assigned);
    expect(task.teamId, 'b9955110-7ecb-4fd6-a71e-c2dd3f17db86');
    expect(task.teamName, 'Ga Central Maintenance Team');
    expect(task.reportPhotoCount, 1);
    expect(
      task.reportPhotoUrls.single,
      'http://192.168.100.8:4000/uploads/reports/drain.jpg',
    );
  });

  test('keeps a field failure distinct from citizen-facing report status', () {
    final task = MaintenanceTask.fromApi({
      'id': 'internal-failed-task',
      'publicReference': 'CV-2026-TASK02',
      'title': 'Streetlight repair',
      'location': 'High Street',
      'status': 'IN_PROGRESS',
      'assignedTeamName': 'Ga Central Maintenance Team',
      'photoUrls': <String>[],
      'resolutionPhotoUrls': <String>[],
      'maintenanceFailureNotes': 'Replacement part unavailable.',
    });

    expect(task.status, MaintenanceTaskStatus.failed);
    expect(task.completionNotes, 'Replacement part unavailable.');
  });

  test('normalizes an omitted problem description without losing photos', () {
    final task = MaintenanceTask.fromApi({
      'id': 'internal-report-without-description',
      'publicReference': 'CV-2026-TASK03',
      'title': 'Broken traffic light',
      'description': '   ',
      'location': 'Chantan Junction',
      'status': 'ASSIGNED',
      'photoUrls': <String>[
        '/uploads/reports/traffic-light-one.jpg',
        '/uploads/reports/traffic-light-two.jpg',
      ],
    });

    expect(task.description, isEmpty);
    expect(task.reportPhotoCount, 2);
    expect(task.reportPhotoUrls, hasLength(2));
  });
}
