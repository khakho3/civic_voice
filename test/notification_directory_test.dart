import 'package:civic_voice/services/notification_directory.dart';
import 'package:civic_voice/models/notification_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('read notification IDs survive directory initialization', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final directory = NotificationDirectory.instance;
    directory.readIds.value = <String>{};
    await directory.initialize();

    directory.markRead('report-123-underReview');
    await Future<void>.delayed(Duration.zero);
    directory.readIds.value = <String>{};
    await directory.initialize();

    expect(directory.isRead('report-123-underReview'), isTrue);
  });

  test('core municipal lifecycle events include progress and resolution', () {
    final notifications = NotificationDirectory.instance.forMunicipal();

    expect(
      notifications.any(
        (item) => item.type == NotificationType.municipalMaintenanceStarted,
      ),
      isTrue,
    );
    expect(
      notifications.any(
        (item) => item.type == NotificationType.municipalReportResolved,
      ),
      isTrue,
    );
  });

  test(
    'maintenance team notifications cover assignment through completion',
    () {
      final types = NotificationDirectory.instance
          .forMaintenance()
          .map((item) => item.type)
          .toSet();

      expect(types, contains(NotificationType.maintenanceTaskAssigned));
      expect(types, contains(NotificationType.maintenanceTaskInProgress));
      expect(types, contains(NotificationType.maintenanceTaskCompleted));
    },
  );
}
